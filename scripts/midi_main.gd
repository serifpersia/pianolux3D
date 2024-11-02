extends Node3D

@onready var canvas_layer: CanvasLayer = $CanvasLayer

@onready var midi_keyboard = $MIDI_Keyboard
@onready var midi_notes = $MIDI_Notes
@onready var midi_bg: Node3D = $MIDI_BG
@onready var midi_particles = $MIDI_Particles

@export var player : CharacterBody3D
@onready var position_z_slider: HSlider = $CanvasLayer/Menu/Panel_Container/Margin_Sub/VBox_Root/HBox_Pos_Z_Container/Pos_Z_Slider

@onready var controls_menu: MarginContainer = $CanvasLayer/Controls_Menu

@onready var controls_button: Button = $CanvasLayer/Menu/Panel_Container/Margin_Sub/VBox_Root/HBox_BG_C_Container/Controls_Button

var max_z_offset: float
var base_z_position: float

var pause_menu: bool = false

func _ready() -> void:
	max_z_offset = -calculate_max_z_offset() / 4
	base_z_position = position.z

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_pause_menu"):
		pause_menu = !pause_menu
		canvas_layer.visible = pause_menu
		controls_button.button_pressed = false
		controls_menu.visible = false

		player.handle_pause(pause_menu)

func _on_virtual_keyboard_toggle_toggled(toggled_on: bool) -> void:
	midi_keyboard.visible = toggled_on

func _on_midi_notes_toggle_toggled(toggled_on: bool) -> void:
	midi_notes.visible = toggled_on

func _on_bg_toggle_toggled(toggled_on: bool) -> void:
	midi_bg.visible = toggled_on

func _on_particles_toggle_toggled(toggled_on: bool) -> void:
	Global.particles_state = toggled_on

func calculate_max_z_offset() -> float:
	var camera3d = player.get_child(2)
	
	var distance_to_camera = camera3d.global_transform.origin.distance_to(global_transform.origin)
	return distance_to_camera

func _on_scale_slider_value_changed(value: float) -> void:
	scale = Vector3(value, value, value)
	
	position_z_slider.set_value_no_signal(0)
	var z_offset = (1.0 - value) * max_z_offset
	base_z_position = z_offset
	position.z = base_z_position

func _on_pos_z_slider_value_changed(value: float) -> void:
	position.z = base_z_position + value


func _on_controls_button_toggled(toggled_on: bool) -> void:
	controls_menu.visible = toggled_on
