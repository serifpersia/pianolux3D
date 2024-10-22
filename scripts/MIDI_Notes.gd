extends Node3D

@export var white_note_material : Material
@export var black_note_material : Material

@export var base_speed_multiplier : float = 16.0

@onready var virtual_keyboard = $"../Virtual_Keyboard"

var speed_multiplier

var notes = []
var notes_on = {}
var note_height = 0.06
var note_depth = 0.2


func _ready():
	var display_refresh_rate = DisplayServer.screen_get_refresh_rate()
	speed_multiplier = base_speed_multiplier * 60.0 / display_refresh_rate


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
		box.position = Vector3(x_offset - 31.57, -8.53, z_position)
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

func update_key_material(pitch, is_note_on):
	var keys = virtual_keyboard.get_children()
	for key in keys:
		if key.name == "key_" + str(pitch):
			
			var mesh_instance = key.get_child(0)
			if virtual_keyboard.is_black_key(pitch):
				if is_note_on:
					mesh_instance.material_override = black_note_material
				else:
					mesh_instance.material_override = virtual_keyboard.black_key_material
			else:
				if is_note_on:
					mesh_instance.material_override = white_note_material
				else:
					mesh_instance.material_override = virtual_keyboard.white_key_meterial
			break
			
