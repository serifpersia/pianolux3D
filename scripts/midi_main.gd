extends Node3D

@onready var canvas_layer: CanvasLayer = $CanvasLayer

@onready var midi_keyboard = $MIDI_Keyboard
@onready var midi_notes = $MIDI_Notes
@onready var piano_bg: MeshInstance3D = $MIDI_Keyboard/Piano_BG
@onready var midi_particles = $MIDI_Particles

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_SPACE and event.pressed:
			canvas_layer.visible = not canvas_layer.visible

func _on_toggle_keyboard_toggled(toggled_on: bool) -> void:
	midi_keyboard.visible = toggled_on

func _on_toggle_midi_toggled(toggled_on):
	midi_notes.visible = toggled_on

func _on_toggle_bg_toggled(toggled_on):
	piano_bg.visible = toggled_on

func _on_toggle_particles_toggled(toggled_on):
	Global.particles_state = toggled_on
