extends Node3D

@onready var canvas_layer: CanvasLayer = $CanvasLayer

@onready var midi_keyboard = $MIDI_Keyboard
@onready var midi_white_notes: Node3D = $MIDI_White_Notes
@onready var midi_black_notes: Node3D = $MIDI_Black_Notes
@onready var midi_bg: Node3D = $MIDI_BG

@onready var position_z_slider: HSlider = $CanvasLayer/Menu/Panel_Container/Margin_Sub/ScrollContainer/VBoxContainer/MarginContainer_Transforms/VBox_Transforms/VBox_Content/HBox_Pos_Z_Container/Pos_Z_Slider

var base_z_position: float

var pause_menu: bool = false

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_pause_menu"):
		pause_menu = !pause_menu
		canvas_layer.visible = pause_menu


func _on_virtual_keyboard_toggle_toggled(toggled_on: bool) -> void:
	midi_keyboard.visible = toggled_on

func _on_midi_notes_toggle_toggled(toggled_on: bool) -> void:
	midi_white_notes.visible = toggled_on
	midi_black_notes.visible = toggled_on

func _on_bg_toggle_toggled(toggled_on: bool) -> void:
	midi_bg.visible = toggled_on

func _on_particles_toggle_toggled(toggled_on: bool) -> void:
	Global.particles_state = toggled_on


func _on_pos_z_slider_value_changed(value: float) -> void:
	position.z = base_z_position + value
