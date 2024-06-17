extends Node3D

@export var note_material : Material
@export var black_key_material : Material
@export var speed_multiplier : float = 14.0

var notes = []
var notes_on = {}
var display_range = 36.0
var note_range = 108 - 21 + 1
var note_width = display_range / note_range
var note_height = 0.1
var note_depth = 0.1

func _ready():
	OS.open_midi_inputs()

func _input(midi_event):
	if midi_event is InputEventMIDI:
		if midi_event.message == MIDI_MESSAGE_NOTE_ON:
			notes_on[midi_event.pitch] = true
		elif midi_event.message == MIDI_MESSAGE_NOTE_OFF:
			notes_on.erase(midi_event.pitch)

func _process(delta):
	spawn_notes()
	move_notes(delta)
	despawn_notes()

func spawn_notes():
	for note in notes_on.keys():
		var box = MeshInstance3D.new()
		var capsule = BoxMesh.new()
		box.mesh = capsule
		var x_offset = calculate_x_offset(note)
		var width = note_width if not is_black_key(note) else note_width / 1.25
		box.position = Vector3(x_offset - display_range / 2,-11, 0)
		box.scale = Vector3(width-0.1, note_height, note_depth)
		box.material_override = black_key_material if is_black_key(note) else note_material
		add_child(box)
		notes.append(box)

func calculate_x_offset(note):
	return float(note - 21) * note_width

func is_black_key(note):
	var black_keys = [1, 3, 6, 8, 10]
	return (note % 12) in black_keys

func move_notes(delta):
	for note in notes:
		note.position.y += delta * speed_multiplier

func despawn_notes():
	for note in notes:
		if note.position.y > 20:
			notes.remove_at(notes.find(note))
			note.queue_free()
