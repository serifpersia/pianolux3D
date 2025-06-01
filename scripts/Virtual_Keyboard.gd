extends Node3D

@export var white_keys_off_mat: StandardMaterial3D
@export var black_keys_off_mat: StandardMaterial3D
@export var white_notes_on_mat: StandardMaterial3D
@export var black_notes_on_mat: StandardMaterial3D

@export var light_offset: = Vector3(0, 0.1, 0)
@export var light_range: float = 0.1
@export var light_attenuation: float = 1
@export var tween_duration: float = 0.1
@export var shader: Shader

var light_nodes: Dictionary = {}
var tweens: Dictionary = {}
var black_keys: PackedInt32Array = PackedInt32Array([1, 3, 6, 8, 10])

func _ready() -> void:
	var keys = get_children()
	for key in keys:
		setup_key_light(key)
		var key_id = int(String(key.name))
		var is_black = is_black_key(key_id)
		var mesh_instance = key as MeshInstance3D
		if mesh_instance:
			var base_mat = (black_keys_off_mat if is_black else white_keys_off_mat)
			var shader_mat := ShaderMaterial.new()
			shader_mat.shader = shader

			shader_mat.set_shader_parameter("color_from", base_mat.albedo_color)
			shader_mat.set_shader_parameter("color_to", base_mat.albedo_color)
			shader_mat.set_shader_parameter("blend_factor", 0.0)

			shader_mat.set_shader_parameter("emission_from", Color(0, 0, 0))
			shader_mat.set_shader_parameter("emission_to", Color(0, 0, 0))
			shader_mat.set_shader_parameter("emission_blend", 0.0)

			shader_mat.set_shader_parameter("emission_multiplier_from", 0.0)
			shader_mat.set_shader_parameter("emission_multiplier_to", 0.0)
			shader_mat.set_shader_parameter("emission_multiplier_blend", 0.0)

			mesh_instance.material_override = shader_mat

func is_black_key(note: int) -> bool:
	return (note % 12) in black_keys

func update_key_material(pitch: int, is_note_on: bool) -> void:
	var pitch_str := str(pitch)
	var is_black := is_black_key(pitch)

	for key in get_children():
		if key.name == pitch_str:
			var mesh_instance := key as MeshInstance3D
			if not mesh_instance:
				return

			if tweens.has(pitch_str):
				tweens[pitch_str].kill()

			var tween := create_tween().set_parallel()
			tweens[pitch_str] = tween

			var from_mat = (black_keys_off_mat if is_black else white_keys_off_mat)
			var to_mat = (black_notes_on_mat if is_black else white_notes_on_mat)

			var shader_mat = mesh_instance.material_override as ShaderMaterial

			shader_mat.set_shader_parameter("color_from", from_mat.albedo_color)
			shader_mat.set_shader_parameter("color_to", to_mat.albedo_color)

			shader_mat.set_shader_parameter("emission_from", shader_mat.get_shader_parameter("emission"))
			shader_mat.set_shader_parameter("emission_to", to_mat.emission if is_note_on else Color(0, 0, 0))

			shader_mat.set_shader_parameter("emission_multiplier_from", shader_mat.get_shader_parameter("emission_multiplier_to"))
			shader_mat.set_shader_parameter("emission_multiplier_to", to_mat.emission_energy_multiplier if is_note_on else 0.0)

			tween.tween_property(shader_mat, "shader_parameter/blend_factor", 1.0 if is_note_on else 0.0, tween_duration)
			tween.tween_property(shader_mat, "shader_parameter/emission_blend", 1.0 if is_note_on else 0.0, tween_duration)
			tween.tween_property(shader_mat, "shader_parameter/emission_multiplier_blend", 1.0 if is_note_on else 0.0, tween_duration)

			if light_nodes.has(pitch_str):
				var light_holder = light_nodes[pitch_str]
				var omni_light = light_holder.get_node("KeyLight") as OmniLight3D
				if omni_light:
					var target_energy = 1.0 if is_note_on else 0.0
					tween.tween_property(omni_light, "light_energy", target_energy, tween_duration)

					if is_note_on:
						light_holder.visible = true
					else:
						tween.tween_callback(func(): light_holder.visible = false)

			tween.tween_callback(func(): tweens.erase(pitch_str))
			return

func setup_key_light(key: Node3D) -> void:
	var light_holder = Node3D.new()
	light_holder.name = "LightHolder"
	var key_id = int(String(key.name))
	var is_black = is_black_key(key_id)

	key.add_child(light_holder)
	light_holder.position += light_offset

	var omni_light = OmniLight3D.new()
	omni_light.name = "KeyLight"
	omni_light.light_color = black_notes_on_mat.albedo_color if is_black else white_notes_on_mat.albedo_color
	omni_light.omni_range = light_range
	omni_light.omni_attenuation = light_attenuation
	omni_light.light_size = 0.005
	omni_light.light_energy = 0.0

	light_holder.add_child(omni_light)
	light_holder.visible = false
	light_nodes[key.name] = light_holder
