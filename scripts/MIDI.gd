extends Node3D

@export var white_note_material : Material
@export var black_note_material : Material

@export var white_note_material_no_outline : Material
@export var black_note_material_no_outline : Material

@export var base_speed_multiplier : float = 16.0
@export var particle_scene : PackedScene # Add a variable to hold the particle scene

var speed_multiplier

@onready var virtual_keyboard = $"../Virtual_Keyboard"
@onready var canvas_layer = $"../CanvasLayer"

@onready var color_picker_white_key = $"../CanvasLayer/ColorPicker_White_Key"
@onready var color_picker_black_key = $"../CanvasLayer/ColorPicker_Black_Key"

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
		elif event.message == MIDI_MESSAGE_NOTE_OFF:
			notes_on.erase(event.pitch)
			update_key_material(event.pitch, false)
			stop_particle(event.pitch) # Stop particle when note is released
	if event is InputEventMouseButton:
		if event.pressed and event.position.y > 545:
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
	check_color_change(color_picker_white_key, previous_white_color, "White key")
	check_color_change(color_picker_black_key, previous_black_color, "Black key")

func check_color_change(color_picker, var_name, label):
	if color_picker.color_changed:
		var current_color = color_picker.color
		if current_color != var_name:
			print(label, "color: ", current_color)
			var_name = current_color
			
			if label == "White key":
				white_note_material.albedo_color = current_color
				white_note_material_no_outline.albedo_color = current_color
			elif label == "Black key":
				black_note_material_no_outline.albedo_color = current_color
				black_note_material.albedo_color = current_color

func spawn_notes():
	for note in notes_on.keys():
		var box = MeshInstance3D.new()
		var capsule = CapsuleMesh.new()
		box.mesh = capsule
		var x_offset = virtual_keyboard.calculate_x_offset(note)
		var width = virtual_keyboard.note_width if not virtual_keyboard.is_black_key(note) else virtual_keyboard.note_width * 0.65
		var z_position = 0.1 if virtual_keyboard.is_black_key(note) else 0.0  # Slightly in front for black keys
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

	var particle_instance = particle_scene.instantiate()
	var x_offset = virtual_keyboard.calculate_x_offset(pitch)
	particle_instance.position = Vector3(x_offset - virtual_keyboard.display_range / 2, -8.5, 0)
	add_child(particle_instance)
	particle_instance.emitting = true
	active_particles[pitch] = particle_instance

func stop_particle(pitch):
	if pitch in active_particles:
		var particle_instance = active_particles[pitch]
		particle_instance.emitting = false
		particle_instance.queue_free()
		active_particles.erase(pitch)
