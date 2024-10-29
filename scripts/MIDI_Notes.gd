extends Node3D

@export var white_keys_off_mat: StandardMaterial3D
@export var black_keys_off_mat: StandardMaterial3D
@export var white_notes_on_mat: StandardMaterial3D
@export var black_notes_on_mat: StandardMaterial3D

@export var white_light_offset: Vector3 = Vector3(0, 0.2, 0)  # Adjust for white keys
@export var black_light_offset: Vector3 = Vector3(0, 0.4, 0)  # Adjust for black keys
@export var light_range: float = 6.0
@export var light_attenuation: float = -1.25

@export var white_note_mesh_scene: PackedScene

@export var shader: Shader
@export var speed: float = 18.0

class NoteData:
	var instance: MeshInstance3D
	var released: bool
	var shader_material: ShaderMaterial
	var offset: float
	
var light_nodes: Dictionary = {}

var active_notes: Dictionary = {}
var notes_to_remove: Array[int] = []
var target_vertex_indices: PackedInt32Array = []
var black_keys: PackedInt32Array = PackedInt32Array([1, 3, 6, 8, 10])

@export var white_note_mesh_color: Color = Color(1.0, 0.0, 0.0, 1.0)
@export var black_note_mesh_color: Color = Color(0.8, 0.0, 0.0, 1.0)

var shader_material_prototype: ShaderMaterial

func _ready() -> void:
	var keys = get_children()
	
	for key in keys:
		setup_key_light(key)
		
	shader_material_prototype = ShaderMaterial.new()
	shader_material_prototype.shader = shader
	
	var key_mesh_instance: Node3D = white_note_mesh_scene.instantiate()
	var mesh_instance_get_mesh_data: MeshInstance3D = key_mesh_instance.get_child(0)
	select_vertices_automatically(mesh_instance_get_mesh_data.mesh)
	
	shader_material_prototype.set_shader_parameter("target_vertex_count", target_vertex_indices.size())
	shader_material_prototype.set_shader_parameter("target_vertex_indices", target_vertex_indices)
	shader_material_prototype.set_shader_parameter("z_offset", 0.0)

func _process(delta: float) -> void:
	move_notes(delta)
	despawn_notes()

func create_shader_material() -> ShaderMaterial:
	return shader_material_prototype.duplicate()

func create_note_data(instance: MeshInstance3D, shader_material: ShaderMaterial) -> NoteData:
	var data := NoteData.new()
	data.instance = instance
	data.released = false
	data.shader_material = shader_material
	data.offset = 0.0

	shader_material.set_shader_parameter("white_key_color", white_note_mesh_color)
	shader_material.set_shader_parameter("black_key_color", black_note_mesh_color)
	
	return data


func on_note_on(pitch: int) -> void:
	var key_mesh_instance: Node3D = white_note_mesh_scene.instantiate()
	var new_mesh_instance: MeshInstance3D = key_mesh_instance.get_child(0)

	var is_black = is_black_key(pitch)
	if is_black:
		var scale_factor := Vector3(1.35 / 2.3, 1.35 / 2.3, 0.5)
		new_mesh_instance.scale = scale_factor

	if not active_notes.has(pitch):
		active_notes[pitch] = []

	var note_mesh := get_node(str(pitch))
	var note_mesh_z = note_mesh.position.z - 0.65 if is_black else note_mesh.position.z - 1.25

	var note_shader_material := create_shader_material()
	
	new_mesh_instance.material_override = note_shader_material
	new_mesh_instance.position = Vector3(note_mesh.position.x, note_mesh.position.y, note_mesh_z)

	note_shader_material.set_shader_parameter("is_black_key", is_black)

	var note_array: Array = active_notes[pitch]
	note_array.append(create_note_data(new_mesh_instance, note_shader_material))

	add_child(key_mesh_instance)


func on_note_off(pitch: int) -> void:
	if active_notes.has(pitch):
		var note_array: Array = active_notes[pitch]
		for note_data in note_array:
			if not (note_data as NoteData).released:
				(note_data as NoteData).released = true

func move_notes(delta: float) -> void:
	var move_amount := delta * 18.0
	var speed_delta := speed * delta
	
	for note_array in active_notes.values():
		for note_data in note_array:
			var typed_data := note_data as NoteData
			var note_instance: MeshInstance3D = typed_data.instance
			if note_instance and note_instance.is_inside_tree():
				if not typed_data.released:
					typed_data.offset -= speed_delta
					typed_data.shader_material.set_shader_parameter("z_offset", typed_data.offset)
				else:
					note_instance.position.z -= move_amount

func despawn_notes() -> void:
	var pitches_to_remove: Array[int] = []
	
	for pitch in active_notes:
		var note_array: Array = active_notes[pitch]
		notes_to_remove.clear()
		
		for i in range(note_array.size() - 1, -1, -1):
			var note_data := note_array[i] as NoteData
			var note_instance: Node3D = note_data.instance
			if note_instance and note_instance.position.z < -64:
				note_instance.queue_free()
				notes_to_remove.append(i)
		
		for index in notes_to_remove:
			note_array.remove_at(index)
			
		if note_array.is_empty():
			pitches_to_remove.append(pitch)
	
	for pitch in pitches_to_remove:
		active_notes.erase(pitch)

func is_black_key(note: int) -> bool:
	return (note % 12) in black_keys

func update_key_material(pitch: int, is_note_on: bool) -> void:
	var pitch_str := str(pitch)
	var is_black := is_black_key(pitch)

	for key in get_children():
		if key.name == pitch_str:
			var mesh_instance := key
			mesh_instance.material_override = (
				black_notes_on_mat if is_note_on else black_keys_off_mat
			) if is_black else (
				white_notes_on_mat if is_note_on else white_keys_off_mat
			)

			if light_nodes.has(pitch_str):
				light_nodes[pitch_str].visible = is_note_on
			return

func select_vertices_automatically(array_mesh: ArrayMesh) -> void:
	var surface_count := array_mesh.get_surface_count()
	target_vertex_indices.resize(0)
	
	for surface_index in surface_count:
		var vertices: PackedVector3Array = array_mesh.surface_get_arrays(surface_index)[ArrayMesh.ARRAY_VERTEX]
		for i in vertices.size():
			if vertices[i].z < 0:
				target_vertex_indices.push_back(i)

func setup_key_light(key: Node3D) -> void:
	
	var light_holder = Node3D.new()
	light_holder.name = "LightHolder"
	
	var key_id = int(String(key.name))
	var is_black = is_black_key(key_id)
	
	key.add_child(light_holder)
	
	light_holder.position += black_light_offset if is_black else white_light_offset
	
	var omni_light = OmniLight3D.new()
	omni_light.name = "KeyLight"
	
	# Set the light color based on whether it's a black or white key
	omni_light.light_color = black_note_mesh_color if is_black else white_note_mesh_color
	
	omni_light.omni_range = light_range
	omni_light.omni_attenuation = light_attenuation
	
	light_holder.add_child(omni_light)
	
	light_holder.visible = false
	
	light_nodes[key.name] = light_holder
