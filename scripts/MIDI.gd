extends Node3D

@export var white_note_material : Material
@export var black_note_material : Material

@export var white_note_material_no_outline : Material
@export var black_note_material_no_outline : Material

@export var particles_material : StandardMaterial3D
@export var particles_flash_material : StandardMaterial3D
@export var bg_material : Material

@export var base_speed_multiplier : float = 16.0
@export var particle_scene : PackedScene

var speed_multiplier

@onready var virtual_keyboard = $"../Virtual_Keyboard"
@onready var canvas_layer = $"../CanvasLayer"

@onready var color_picker = $"../CanvasLayer/ColorPicker"

@onready var change_bg_image_button = $"../CanvasLayer/ChangeBGImage_Button"
@onready var file_dialog = $"../CanvasLayer/FileDialog"

@onready var bg_transparency_slider = $"../CanvasLayer/BGTransparency_Slider"
@onready var bg = $"../BG"
@onready var toggle_bg = $"../CanvasLayer/ToggleBG"

@onready var serial = $"../PianoController"

var notes = []
var notes_on = {}
var note_height = 0.135
var note_depth = 0.1

var previous_white_color
var previous_black_color

var active_particles = {}
var child_particles = {}

var serial_thread : Thread = Thread.new()
var serial_queue : Array = []
var serial_lock : Mutex = Mutex.new()
var is_running : bool = true

func _ready():
	serial_thread.start(_thread_serial_handler)
	
	previous_white_color = color_picker.color
	OS.open_midi_inputs()
	
	var display_refresh_rate = DisplayServer.screen_get_refresh_rate()
	speed_multiplier = base_speed_multiplier * 60.0 / display_refresh_rate

func _exit_tree():
	is_running = false
	if serial_thread:
		serial_thread.wait_to_finish()

func _input(event):
	if event is InputEventMIDI:
		if event.message == MIDI_MESSAGE_NOTE_ON:
			notes_on[event.pitch] = true
			update_key_material(event.pitch, true)
			spawn_particle(event.pitch)

			var notePushed
			if not serial.fixLED_Toggle:
				notePushed = serial.fixed_map_midi_note_to_led(event.pitch, serial.firstNoteSelected, serial.lastNoteSelected, serial.stripLedNum, 1)
			else:
				notePushed = serial.map_midi_note_to_led(event.pitch, serial.firstNoteSelected, serial.lastNoteSelected, serial.stripLedNum, 1)

			var command_data = {
				"mode": serial.MODE,
				"velocity": event.velocity,
				"notePushed": notePushed,
				"type": "note_on"
			}

			serial_lock.lock()
			serial_queue.append(command_data)
			serial_lock.unlock()

		elif event.message == MIDI_MESSAGE_NOTE_OFF:
			notes_on.erase(event.pitch)
			update_key_material(event.pitch, false)
			stop_particle(event.pitch)

			var notePushed
			if not serial.fixLED_Toggle:
				notePushed = serial.fixed_map_midi_note_to_led(event.pitch, serial.firstNoteSelected, serial.lastNoteSelected, serial.stripLedNum, 1)
			else:
				notePushed = serial.map_midi_note_to_led(event.pitch, serial.firstNoteSelected, serial.lastNoteSelected, serial.stripLedNum, 1)

			var command_data = {
				"notePushed": notePushed,
				"type": "note_off"
			}

			serial_lock.lock()
			serial_queue.append(command_data)
			serial_lock.unlock()

	if event is InputEventKey:
		if event.keycode == KEY_SPACE and event.pressed:
			canvas_layer.visible = not canvas_layer.visible


func _thread_serial_handler():
	while is_running:
		serial_lock.lock()
		if serial_queue.size() > 0:
			var command_data = serial_queue.pop_front()
			serial_lock.unlock()

			if command_data.type == "note_on":
				match command_data.mode:
					0:
						serial.send_command_default_note_on(command_data.notePushed, command_data.velocity)
					1:
						serial.send_command_splash(command_data.velocity, command_data.notePushed)
					2:
						serial.send_command_note_on(command_data.notePushed)
					3:
						serial.send_command_velocity(command_data.velocity, command_data.notePushed)
						
			elif command_data.type == "note_off":
				serial.send_command_note_off(command_data.notePushed)
		else:
			serial_lock.unlock()

		OS.delay_msec(10)

func update_key_material(pitch, is_note_on):
	var keys = virtual_keyboard.get_children()
	for key in keys:
		if key.name == "key_" + str(pitch):
			
			var mesh_instance = key.get_child(0)
			if virtual_keyboard.is_black_key(pitch):
				if is_note_on:
					mesh_instance.material_override = black_note_material_no_outline
				else:
					mesh_instance.material_override = virtual_keyboard.black_key_material
			else:
				if is_note_on:
					mesh_instance.material_override = white_note_material_no_outline
				else:
					mesh_instance.material_override = virtual_keyboard.white_key_meterial
			break


func _process(delta):
	spawn_notes()
	move_notes(delta)
	despawn_notes()

func spawn_notes():
	for note in notes_on.keys():
		var box = MeshInstance3D.new()
		var capsule = CapsuleMesh.new()
		box.mesh = capsule
		var x_offset = virtual_keyboard.calculate_x_offset(note)
		var width = virtual_keyboard.note_width if not virtual_keyboard.is_black_key(note) else virtual_keyboard.note_width * 0.65
		var z_position = 0.2 if virtual_keyboard.is_black_key(note) else 0.1
		box.position = Vector3(x_offset - virtual_keyboard.display_range / 2, -8.5, z_position)
		box.scale = Vector3(width, note_height, note_depth)
		box.material_override = black_note_material if virtual_keyboard.is_black_key(note) else white_note_material
		add_child(box)
		notes.append(box)

func move_notes(delta):
	var move_amount = delta * speed_multiplier
	for note in notes:
		note.position.y += move_amount

func despawn_notes():
	for note in notes:
		if note.position.y > 32:
			notes.remove_at(notes.find(note))
			note.queue_free()

func spawn_particle(pitch):
	if not particle_scene:
		return
		
	if Global.particles_state:
		var particle_instance = particle_scene.instantiate()
		var x_offset = virtual_keyboard.calculate_x_offset(pitch)
		particle_instance.position = Vector3(x_offset - virtual_keyboard.display_range / 2, -8.5, 0.3)
		add_child(particle_instance)
		particle_instance.emitting = true
		
		active_particles[pitch] = particle_instance
		
		for child in particle_instance.get_children():
			child.emitting = true
			if not child_particles.has(pitch):
				child_particles[pitch] = []
			child_particles[pitch].append(child)


func stop_particle(pitch):
	if pitch in active_particles:
		var particle_instance = active_particles[pitch]
		particle_instance.emitting = false
		
		var parent_timer = Timer.new()
		parent_timer.one_shot = true
		parent_timer.wait_time = particle_instance.lifetime
		parent_timer.connect("timeout", Callable(self, "_remove_particle_instance").bind(particle_instance))
		add_child(parent_timer)
		parent_timer.start()
		
		if pitch in child_particles:
			for child in child_particles[pitch]:
				child.emitting = false
				var child_timer = Timer.new()
				child_timer.one_shot = true
				child_timer.wait_time = child.lifetime
				child_timer.connect("timeout", Callable(self, "_remove_particle_instance").bind(child))
				add_child(child_timer)
				child_timer.start()
			
		active_particles.erase(pitch)
		child_particles.erase(pitch)


func _remove_particle_instance(particle_instance):
	if particle_instance and particle_instance.get_parent():
		particle_instance.queue_free()

func _on_change_bg_image_button_pressed():
	file_dialog.popup()

func _on_file_dialog_file_selected(path):
	var image = Image.new()
	
	image.load(path)
	
	var image_texture = ImageTexture.new()
	
	image_texture.set_image(image)
	
	bg_material.albedo_color.a = 1
	bg_material.albedo_texture = image_texture
	
	bg_transparency_slider.value = 1
	toggle_bg.button_pressed = true

func _on_clear_bg_image_button_pressed():
	bg_material.albedo_texture = null
	toggle_bg.button_pressed = false

func _on_bg_transparency_slider_value_changed(value):
	bg_material.albedo_color.a = value

func _on_color_picker_color_changed(color):
	white_note_material.albedo_color = color
	white_note_material_no_outline.albedo_color = color
	
	var darker_color = Color(color.r * 0.8, color.g * 0.8, color.b * 0.8, color.a)
	print(darker_color)
	
	black_note_material.albedo_color = darker_color
	black_note_material_no_outline.albedo_color = darker_color
	
	particles_material.albedo_color = color
	particles_flash_material.albedo_color = color
	
	serial.currentColor = color
	serial.send_command_update_color(color)
