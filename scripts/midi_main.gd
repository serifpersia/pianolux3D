extends Node3D

@onready var virtual_keyboard = $Virtual_Keyboard
@onready var midi_notes = $MIDI_Notes
@onready var bg = $BG
@onready var midi_particles: Node3D = $MIDI_Particles

@onready var canvas_layer: CanvasLayer = $CanvasLayer

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_SPACE and event.pressed:
			canvas_layer.visible = not canvas_layer.visible

func _on_toggle_keyboard_toggled(toggled_on):
	virtual_keyboard.visible = toggled_on

func _on_toggle_midi_toggled(toggled_on):
	midi_notes.visible = toggled_on

func _on_toggle_bg_toggled(toggled_on):
	bg.visible = toggled_on

func _on_toggle_particles_toggled(toggled_on):
	Global.particles_state = toggled_on
