extends Node3D

@export var white_note_material : Material
@export var black_note_material : Material

@export var white_note_material_no_outline : Material
@export var black_note_material_no_outline : Material

@export var speed_multiplier : float = 10.0

@onready var virtual_keyboard = $"../Virtual_Keyboard"

var notes = []
var notes_on = {}
var display_range = 42.75
var note_range = 57.925
var note_width = display_range / note_range
var note_height = 0.1
var note_depth = 0.1

func _ready():
	OS.open_midi_inputs()

func _input(midi_event):
	if midi_event is InputEventMIDI:
		if midi_event.message == MIDI_MESSAGE_NOTE_ON:
			notes_on[midi_event.pitch] = true
			update_key_material(midi_event.pitch, true)
		elif midi_event.message == MIDI_MESSAGE_NOTE_OFF:
			notes_on.erase(midi_event.pitch)
			update_key_material(midi_event.pitch, false)

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
		var width = note_width if not virtual_keyboard.is_black_key(note) else note_width * 0.65
		var z_position = 0.1 if virtual_keyboard.is_black_key(note) else 0.0  # Slightly in front for black keys
		box.position = Vector3(x_offset - display_range / 2, -8.5, z_position)
		box.scale = Vector3(width, note_height, note_depth)
		box.material_override = black_note_material if virtual_keyboard.is_black_key(note) else white_note_material
		add_child(box)
		notes.append(box)

func move_notes(delta):
	for note in notes:
		note.position.y += delta * speed_multiplier

func despawn_notes():
	for note in notes:
		if note.position.y > 32:
			notes.remove_at(notes.find(note))
			note.queue_free()
