extends Node3D

@export var white_keys_off_mat: StandardMaterial3D
@export var black_keys_off_mat: StandardMaterial3D
@export var white_notes_on_mat: StandardMaterial3D
@export var black_notes_on_mat: StandardMaterial3D

@export var light_offset: = Vector3(0,0.1,0)
@export var light_range: float = 0.1
@export var light_attenuation: float = 1

var light_nodes: Dictionary = {}

var black_keys: PackedInt32Array = PackedInt32Array([1, 3, 6, 8, 10])

@export var white_note_mesh_color: Color = Color(1.0, 0.0, 0.0, 1.0)
@export var black_note_mesh_color: Color = Color(0.8, 0.0, 0.0, 1.0)

func _ready() -> void:
	var keys = get_children()

	for key in keys:
		setup_key_light(key)

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

func setup_key_light(key: Node3D) -> void:
	var light_holder = Node3D.new()
	light_holder.name = "LightHolder"
	
	var key_id = int(String(key.name))
	var is_black = is_black_key(key_id)

	key.add_child(light_holder)
	light_holder.position += light_offset
	
	# Add OmniLight3D
	var omni_light = OmniLight3D.new()
	omni_light.name = "KeyLight"
	omni_light.light_color = black_note_mesh_color if is_black else white_note_mesh_color
	omni_light.omni_range = light_range
	omni_light.omni_attenuation = light_attenuation
	omni_light.light_size = 0.005
	#omni_light.shadow_enabled = true
	
	light_holder.add_child(omni_light)
	light_holder.visible = false
	light_nodes[key.name] = light_holder
