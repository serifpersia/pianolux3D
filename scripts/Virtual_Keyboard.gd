@tool
extends Node3D

@export var white_key_meterial : Material
@export var black_key_material : Material

@export var speed_multiplier : float = 10.0

var note_width = 0.792

func _ready():
	create_midi_keyboard()

func create_midi_keyboard():
	var white_key_width = note_width
	var black_key_width = white_key_width * 0.65

	for note in range(21,109):
		
		var key_body = StaticBody3D.new()
		var key_mesh_instance = MeshInstance3D.new()
		var mesh = QuadMesh.new()
		
		key_mesh_instance.mesh = mesh
		
		var z_position = 0.2 if is_black_key(note) else 0.1
		var x_offset = calculate_x_offset(note)
		var y_offset = -9.75 if is_black_key(note) else -10.502
		key_body.position = Vector3(x_offset-31.57, y_offset, z_position)
		
		if is_black_key(note):
			key_mesh_instance.scale = Vector3(black_key_width, 2.4, 0.1)
			key_mesh_instance.material_override = black_key_material
		else:
			key_mesh_instance.scale = Vector3(white_key_width, 3.8, 0.1)
			key_mesh_instance.material_override = white_key_meterial
		
		key_body.add_child(key_mesh_instance)

		var collision_shape = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		
		shape.size = key_mesh_instance.scale
		collision_shape.shape = shape
		
		key_body.add_child(collision_shape)

		key_body.name = "key_" + str(note)

		add_child(key_body)

func calculate_x_offset(note):
	var spacing = 0.05
	var white_key_width = note_width + spacing
	var octave = int(note / 12)  # Calculate octave based on MIDI note
	var key_in_octave = note % 12  # Key within the octave
	var x_offset = octave * 7 * white_key_width

	# Adjusted offsets for keys in an octave
	var key_offsets = [
		0,  # C
		white_key_width * 0.5,  # C#
		white_key_width * 1,  # D
		white_key_width * 1.5,  # D#
		white_key_width * 2,  # E
		white_key_width * 3,  # F
		white_key_width * 3.5,  # F#
		white_key_width * 4,  # G
		white_key_width * 4.5,  # G#
		white_key_width * 5,  # A
		white_key_width * 5.5, # A#
		white_key_width * 6  # B
	]

	x_offset += key_offsets[key_in_octave]

	return x_offset

## Revised Function: `is_black_key`

func is_black_key(note):
	var black_keys = [1, 3, 6, 8, 10] # C#, D#, F#, G#, A#
	return (note % 12) in black_keys
