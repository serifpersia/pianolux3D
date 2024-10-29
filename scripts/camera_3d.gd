extends Camera3D

@onready var midi_keyboard: Node3D = $"../../MIDI/MIDI_Keyboard"
@onready var midi_notes: Node3D = $"../../MIDI/MIDI_Notes"
@onready var midi_particles: Node3D = $"../../MIDI/MIDI_Particles"

const LEFT_OFFSET_DIALOG = preload("res://scenes/left_offset_dialog.tscn")

var current_pressed_keys: Array[int] = []

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				detect_key()
			else:
				stop_note_on_release()

		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.is_released():
				show_offset_dialog()

func detect_key():
	var raycast_result = shoot_ray()
	if raycast_result and raycast_result.collider:
		var hit_object = raycast_result.collider
		
		if hit_object is StaticBody3D:
			var key_name = hit_object.get_parent().name
			handle_key_action(int(String(key_name)))

func shoot_ray():
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_length = 1000
	var from = project_ray_origin(mouse_pos)
	var to = from + project_ray_normal(mouse_pos) * ray_length
	var space = get_world_3d().direct_space_state
	var ray_query = PhysicsRayQueryParameters3D.new()
	
	ray_query.from = from
	ray_query.to = to

	return space.intersect_ray(ray_query)

func handle_key_action(pitch):
	midi_keyboard.update_key_material(pitch, true)
	current_pressed_keys.append(pitch)
	midi_notes.on_note_on(pitch)
	midi_particles.spawn_particle(pitch)

func stop_note_on_release():
	for pitch in current_pressed_keys:
		midi_keyboard.update_key_material(pitch, false)
		midi_notes.on_note_off(pitch)
		midi_particles.stop_particle(pitch)

func show_offset_dialog():
	var raycast_result = shoot_ray()
	if raycast_result and raycast_result.collider:
		var hit_object = raycast_result.collider
		
		if hit_object is StaticBody3D:
			var key_number_str = String(hit_object.get_parent().name)
			var pitch = int(key_number_str)
			var offset_dialog = LEFT_OFFSET_DIALOG.instantiate()

			add_child(offset_dialog)
			offset_dialog.initialize_dialog(pitch)
