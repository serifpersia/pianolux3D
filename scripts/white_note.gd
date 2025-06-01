extends Node3D

@onready var midi_keyboard: Node3D = $"../MIDI_Keyboard"
@export var white_note_mesh_scene: PackedScene
@export var shader: Shader
@export var speed: float = 0.35
@export var surface_colors: Array[Color] = []

class NoteData:
	var instance: MeshInstance3D
	var parent_node: Node3D
	var released: bool
	var shader_materials: Array[ShaderMaterial]
	var offset: float

var active_notes: Dictionary = {}
var notes_to_remove: Array[int] = []
var target_vertex_indices: Array[PackedInt32Array] = []

func _ready() -> void:
	surface_colors = [Color.RED, Color.RED]
	var key_mesh_instance = white_note_mesh_scene.instantiate()
	var mesh_instance_get_mesh_data = key_mesh_instance.get_child(0) as MeshInstance3D

	if mesh_instance_get_mesh_data == null or mesh_instance_get_mesh_data.mesh == null:
		key_mesh_instance.queue_free()
		return

	var array_mesh = mesh_instance_get_mesh_data.mesh
	var surface_count = array_mesh.get_surface_count()

	target_vertex_indices.resize(surface_count)
	for i in surface_count:
		target_vertex_indices[i] = PackedInt32Array()

	for surface_index in surface_count:
		select_vertices_automatically(array_mesh, surface_index)

	key_mesh_instance.queue_free()

func _process(delta: float) -> void:
	move_notes(delta)
	despawn_notes()

func create_shader_materials_for_note_instance(mesh_instance: MeshInstance3D) -> Array[ShaderMaterial]:
	var new_materials: Array[ShaderMaterial] = []
	var array_mesh = mesh_instance.mesh
	var surface_count = array_mesh.get_surface_count()

	for surface_index in surface_count:
		var material = ShaderMaterial.new()
		material.shader = shader

		var surface_indices = target_vertex_indices[surface_index]
		material.set_shader_parameter("target_vertex_count", surface_indices.size())
		material.set_shader_parameter("target_vertex_indices", surface_indices)
		material.set_shader_parameter("z_offset", 0.0)
		
		var current_surface_color = Color.WHITE
		if surface_index < surface_colors.size():
			current_surface_color = surface_colors[surface_index]
		
		material.set_shader_parameter("surface_color", current_surface_color)

		new_materials.append(material)
	return new_materials

func create_note_data(instance: MeshInstance3D, parent: Node3D, materials: Array[ShaderMaterial]) -> NoteData:
	var data := NoteData.new()
	data.instance = instance
	data.parent_node = parent
	data.released = false
	data.shader_materials = materials
	data.offset = 0.0
	return data

func on_note_on(pitch: int) -> void:
	if midi_keyboard.is_black_key(pitch):
		return
	var key_mesh_instance: Node3D = white_note_mesh_scene.instantiate()
	var new_mesh_instance: MeshInstance3D = key_mesh_instance.get_child(0) as MeshInstance3D

	if not active_notes.has(pitch):
		active_notes[pitch] = []

	var note_mesh := midi_keyboard.get_node(str(pitch))
	var note_mesh_position_z_offset = new_mesh_instance.get_aabb().size.x / 2
	var note_mesh_position_y_offset = new_mesh_instance.get_aabb().size.y / 2

	var note_shader_materials_array := create_shader_materials_for_note_instance(new_mesh_instance)
	
	var surface_count = new_mesh_instance.mesh.get_surface_count()
	for surface_index in surface_count:
		new_mesh_instance.set_surface_override_material(surface_index, note_shader_materials_array[surface_index])
	
	new_mesh_instance.position = Vector3(
		note_mesh.position.x, 
		note_mesh.position.y + note_mesh_position_y_offset,
		note_mesh.position.z -note_mesh_position_z_offset)
		
	var note_array: Array = active_notes[pitch]
	note_array.append(create_note_data(new_mesh_instance, key_mesh_instance, note_shader_materials_array))

	add_child(key_mesh_instance)

func on_note_off(pitch: int) -> void:
	if active_notes.has(pitch):
		var note_array: Array = active_notes[pitch]
		for note_data in note_array:
			if not (note_data as NoteData).released:
				(note_data as NoteData).released = true

func move_notes(delta: float) -> void:
	var move_amount := delta * speed
	var speed_delta := speed * delta

	for note_array in active_notes.values():
		for note_data in note_array:
			var typed_data := note_data as NoteData
			var note_instance: MeshInstance3D = typed_data.instance
			if note_instance and note_instance.is_inside_tree():
				if not typed_data.released:
					typed_data.offset -= speed_delta
					for material in typed_data.shader_materials:
						material.set_shader_parameter("z_offset", typed_data.offset)
						material.set_shader_parameter("parent_scale", midi_keyboard.scale)
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
			if note_instance and note_instance.position.z < -1.35:
				if note_data.parent_node and is_instance_valid(note_data.parent_node):
					note_data.parent_node.queue_free()
				notes_to_remove.append(i)

		for index in notes_to_remove:
			note_array.remove_at(index)
			
		if note_array.is_empty():
			pitches_to_remove.append(pitch)
	
	for pitch in pitches_to_remove:
		active_notes.erase(pitch)

func select_vertices_automatically(array_mesh: ArrayMesh, surface_index: int) -> void:
	target_vertex_indices[surface_index].resize(0)
	var vertices: PackedVector3Array = array_mesh.surface_get_arrays(surface_index)[ArrayMesh.ARRAY_VERTEX]
	for i in vertices.size():
		if vertices[i].z < 0:
			target_vertex_indices[surface_index].push_back(i)
