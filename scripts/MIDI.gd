extends Node3D

@export var white_note_material : Material
@export var black_note_material : Material

@export var white_note_material_no_outline : Material
@export var black_note_material_no_outline : Material

@export var particles_material : StandardMaterial3D
@export var bg_material : Material

@export var base_speed_multiplier : float = 16.0
@export var particle_scene : PackedScene # Add a variable to hold the particle scene

var speed_multiplier

@onready var virtual_keyboard = $"../Virtual_Keyboard"
@onready var canvas_layer = $"../CanvasLayer"

@onready var color_picker_white_key = $"../CanvasLayer/ColorPicker_White_Key"
@onready var color_picker_black_key = $"../CanvasLayer/ColorPicker_Black_Key"

@onready var change_bg_image_button = $"../CanvasLayer/ChangeBGImage_Button"
@onready var file_dialog = $"../CanvasLayer/FileDialog"

@onready var bg_transparency_slider = $"../CanvasLayer/BGTransparency_Slider"
@onready var bg = $"../BG"
@onready var toggle_bg = $"../CanvasLayer/ToggleBG"

@onready var serial = $"../Serial"

var notes = []
var notes_on = {}
var note_height = 0.135
var note_depth = 0.1

var previous_white_color
var previous_black_color

var active_particles = {} # Dictionary to hold active particle instances

func _ready():
	previous_white_color = color_picker_white_key.color
	previous_black_color = color_picker_black_key.color
	OS.open_midi_inputs()
	
	# Adjust speed multiplier based on refresh rate
	var display_refresh_rate = DisplayServer.screen_get_refresh_rate()
	speed_multiplier = base_speed_multiplier * 60.0 / display_refresh_rate

func _input(event):
	if event is InputEventMIDI:
		if event.message == MIDI_MESSAGE_NOTE_ON:
			notes_on[event.pitch] = true
			update_key_material(event.pitch, true)
			spawn_particle(event.pitch) # Spawn particle when note is pressed
			var notePushed
			notePushed = serial.map_midi_note_to_led(event.pitch,21,108,176,1)
			serial.send_command_default_note_on(notePushed)
		elif event.message == MIDI_MESSAGE_NOTE_OFF:
			notes_on.erase(event.pitch)
			update_key_material(event.pitch, false)
			stop_particle(event.pitch) # Stop particle when note is released
			var notePushed
			notePushed = serial.map_midi_note_to_led(event.pitch,21,108,176,1)
			serial.send_command_note_off(notePushed)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and event.position.y > 545:
			canvas_layer.visible = not canvas_layer.visible

func update_key_material(pitch, is_note_on):
	var keys = virtual_keyboard.get_children()
	for key in keys:
		if key.name == "key_" + str(pitch):
			if virtual_keyboard.is_black_key(pitch):
				if is_note_on:
					key.material_override = black_note_material_no_outline
				else:
					key.material_override = virtual_keyboard.black_key_material
			else:
				if is_note_on:
					key.material_override = white_note_material_no_outline
				else:
					key.material_override = virtual_keyboard.white_key_meterial
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
		var z_position = 0.2 if virtual_keyboard.is_black_key(note) else 0.1  # Slightly in front for black keys
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

func stop_particle(pitch):
	if pitch in active_particles:
		var particle_instance = active_particles[pitch]
		particle_instance.emitting = false
		
		# Set a timer to remove the particle instance after its lifetime
		var timer = Timer.new()
		timer.one_shot = true
		timer.wait_time = particle_instance.lifetime  # Set wait_time to the particle's lifetime
		timer.connect("timeout", Callable(self, "_remove_particle_instance").bind(particle_instance))
		add_child(timer)
		timer.start()
			
		active_particles.erase(pitch)

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


func _on_color_picker_white_key_color_changed(color):
	white_note_material.albedo_color = color
	white_note_material_no_outline.albedo_color = color
	particles_material.albedo_color = color
	serial.send_command_update_color(color)	

func _on_color_picker_black_key_color_changed(color):
	black_note_material.albedo_color = color
	black_note_material_no_outline.albedo_color = color
