extends Node3D

@export var note_material : Material
@export var black_key_material : Material
@export var speed_multiplier : float = 10.0

var notes = []
var notes_on = {}
var display_range = 43.0
var note_range = 58.05
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
		var capsule = CapsuleMesh.new()
		box.mesh = capsule
		var x_offset = calculate_x_offset(note)
		var width = note_width if not is_black_key(note) else note_width / 1.5
		var z_position = 0.1 if is_black_key(note) else 0  # Slightly in front for black keys
		box.position = Vector3(x_offset - display_range / 2, -8.5, z_position)
		box.scale = Vector3(width, note_height, note_depth)
		box.material_override = black_key_material if is_black_key(note) else note_material
		add_child(box)
		notes.append(box)
		
func calculate_x_offset(note):
	var white_key_width = note_width + 0.1
	var octave = int((note - 21) / 12)
	var key_in_octave = (note - 21) % 12
	var x_offset = octave * 7 * white_key_width # Offset by number of white keys in full octaves

	# Array representing the x offset within an octave for each key
	var key_offsets = [
		0, # A
		white_key_width * 0.5, # A#
		white_key_width * 1, # B
		white_key_width * 2, # C
		white_key_width * 2.5, # C#
		white_key_width * 3, # D
		white_key_width * 3.5, # D#
		white_key_width * 4, # E
		white_key_width * 5, # F
		white_key_width * 5.5, # F#
		white_key_width * 6, # G
		white_key_width * 6.5] # G#


	x_offset += key_offsets[key_in_octave]

	return x_offset


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
