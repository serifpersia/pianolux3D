extends Camera3D

@onready var midi_notes: Node3D = $"../MIDI_Pivot/MIDI_Pivot/MIDI/MIDI_Notes"
const LEFT_OFFSET_DIALOG = preload("res://scenes/left_offset_dialog.tscn")

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
			var key_name = hit_object.name
			
			if key_name.begins_with("key_"):
				var pitch_str = key_name.split("_")[1]
				var pitch = int(pitch_str)

				handle_key_action(pitch)

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
	midi_notes.update_key_material(pitch, true)
	midi_notes.notes_on[pitch] = true
	midi_notes.spawn_particle(pitch)

func stop_note_on_release():
	for key in midi_notes.notes_on.keys():
		midi_notes.update_key_material(key, false)
		midi_notes.notes_on.erase(key)
		midi_notes.stop_particle(key)

func show_offset_dialog():
	var raycast_result = shoot_ray()
	if raycast_result and raycast_result.collider:
		var hit_object = raycast_result.collider
		
		if hit_object is StaticBody3D:
			var key_name = hit_object.name
			
			if key_name.begins_with("key_"):
				var pitch_str = key_name.split("_")[1]
				var pitch = int(pitch_str)
				
				var offset_dialog = LEFT_OFFSET_DIALOG.instantiate()
				
				add_child(offset_dialog)
				
				offset_dialog.initialize_dialog(pitch)
