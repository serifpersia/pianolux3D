extends Node3D

@export var white_key_meterial : Material
@export var black_key_material : Material

@export var speed_multiplier : float = 10.0

var display_range = 42.84
var note_range = 57.93
var note_width = display_range / note_range

func _ready():
	create_midi_keyboard()

	
func create_midi_keyboard():
	var white_key_width = note_width
	var black_key_width = white_key_width * 0.65

	for note in range(21,109):
		var key = MeshInstance3D.new()
		var mesh = BoxMesh.new()
		key.mesh = mesh
		var z_position = 0.2 if is_black_key(note) else 0.1
		var x_offset = calculate_x_offset(note)
		var y_offset = -9.75 if is_black_key(note) else -10.5
		key.position = Vector3(x_offset - display_range / 2, y_offset, z_position)
		if is_black_key(note):
			key.scale = Vector3(black_key_width, 2.4, 0.1)
			key.material_override = black_key_material
		else:
			key.scale = Vector3(white_key_width, 3.8, 0.1)
			key.material_override = white_key_meterial
		
		key.name = "key_" + str(note)
		add_child(key)

func calculate_x_offset(note):
	var white_key_width = note_width + 0.1
	var octave = int((note - 21) / 12)
	var key_in_octave = (note - 21) % 12
	var x_offset = octave * 7 * white_key_width

	var key_offsets = [
		0,  # A
		white_key_width * 0.5,  # A#
		white_key_width * 1,  # B
		white_key_width * 2,  # C
		white_key_width * 2.5,  # C#
		white_key_width * 3,  # D
		white_key_width * 3.5,  # D#
		white_key_width * 4,  # E
		white_key_width * 5,  # F
		white_key_width * 5.5,  # F#
		white_key_width * 6,  # G
		white_key_width * 6.5  # G#
	]

	x_offset += key_offsets[key_in_octave]

	return x_offset

func is_black_key(note):
	var black_keys = [1, 3, 6, 8, 10]
	return (note % 12) in black_keys
