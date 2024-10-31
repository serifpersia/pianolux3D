extends Node3D

@onready var canvas_layer: CanvasLayer = $CanvasLayer

@onready var midi_keyboard = $MIDI_Keyboard
@onready var midi_notes = $MIDI_Notes
@onready var midi_bg: Node3D = $MIDI_BG
@onready var midi_particles = $MIDI_Particles

@export var player : CharacterBody3D

var max_z_offset: float

func _ready() -> void:
	max_z_offset = -calculate_max_z_offset() / 4

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_pause_menu"):
		canvas_layer.visible = not canvas_layer.visible

func _on_toggle_keyboard_toggled(toggled_on: bool) -> void:
	midi_keyboard.visible = toggled_on

func _on_toggle_midi_toggled(toggled_on):
	midi_notes.visible = toggled_on

func _on_toggle_bg_toggled(toggled_on):
	midi_bg.visible = toggled_on

func _on_toggle_particles_toggled(toggled_on):
	Global.particles_state = toggled_on

func calculate_max_z_offset() -> float:
	var camera3d = player.get_child(2)
	
	var distance_to_camera = camera3d.global_transform.origin.distance_to(global_transform.origin)
	return distance_to_camera

func _on_scale_slider_value_changed(value: float) -> void:
	scale = Vector3(value, value, value)

	var z_offset = (1.0 - value) * max_z_offset
	position.z = z_offset
