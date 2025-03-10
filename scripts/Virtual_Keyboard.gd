extends Node3D

@export var white_keys_off_mat: StandardMaterial3D
@export var black_keys_off_mat: StandardMaterial3D
@export var white_notes_on_mat: StandardMaterial3D
@export var black_notes_on_mat: StandardMaterial3D

@export var white_light_offset: Vector3 = Vector3(0, 0.2, 0)
@export var black_light_offset: Vector3 = Vector3(0, 0.4, 0)
@export var light_range: float = 16.0
@export var light_attenuation: float = -1.25
@export var  light_angle_attenuation: float = 7.0

@export var white_note_mesh_scene: PackedScene

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

	light_holder.position += black_light_offset if is_black else white_light_offset

	var spot_light = SpotLight3D.new()
	spot_light.rotation.x = -90
	
	spot_light.name = "KeyLight"
	spot_light.light_color = black_note_mesh_color if is_black else white_note_mesh_color
	spot_light.spot_range = light_range
	spot_light.spot_attenuation = light_attenuation
	spot_light.spot_angle_attenuation = light_angle_attenuation
	spot_light.shadow_enabled = true
	
	light_holder.add_child(spot_light)
	light_holder.visible = false
	light_nodes[key.name] = light_holder
