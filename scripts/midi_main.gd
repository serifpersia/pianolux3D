extends Node3D
@onready var virtual_keyboard = $Virtual_Keyboard
@onready var midi_notes = $MIDI_Notes
@onready var bg = $BG

func _on_toggle_keyboard_toggled(toggled_on):
	virtual_keyboard.visible = toggled_on


func _on_toggle_midi_toggled(toggled_on):
	midi_notes.visible = toggled_on


func _on_toggle_bg_toggled(toggled_on):
	bg.visible = toggled_on
