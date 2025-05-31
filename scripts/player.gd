extends CharacterBody3D

@onready var camera_3d: Camera3D = $Camera3D

var fps_mode: bool
var is_paused: bool

var last_position
var last_rotation
var last_camera_rotation_degrees

var initial_position
var initial_rotation
var initial_camera_rotation_degrees

var using_fps_script: bool = true

func _ready() -> void:
	initial_position = position
	initial_rotation = rotation
	initial_camera_rotation_degrees = camera_3d.rotation_degrees

	last_position = initial_position
	last_rotation = initial_rotation
	last_camera_rotation_degrees = initial_camera_rotation_degrees

	setup_camera()
	
func _input(_event: InputEvent) -> void:
	
	if Input.is_action_just_pressed("ui_fps_mode"):
		toggle_fps_mode()
		
	elif Input.is_action_just_pressed("ui_reset_all"):
		var midi_node = get_tree().root.find_child("MIDI", true, false)
		if midi_node:
			midi_node.scale = Vector3(1, 1, 1)
			midi_node.position = Vector3(0, 0, 0)
			midi_node.rotation = Vector3(0, 0, 0)

			var sliders = midi_node.find_children("", "HSlider", true)
			var target_sliders = {}

			for slider in sliders:
				if slider.name in ["Pos_X_Slider", "Pos_Y_Slider", "Pos_Z_Slider", "Rot_X_Slider", "Rot_Y_Slider", "Rot_Z_Slider"]:
					target_sliders[slider.name] = 0
				elif slider.name == "Scale_Slider":
					target_sliders[slider.name] = 1

			for name in target_sliders.keys():
				var slider = midi_node.find_child(name, true, false)
				if slider:
					slider.value = target_sliders[name]


func setup_camera() -> void:
	if fps_mode:
		camera_3d.projection = Camera3D.PROJECTION_PERSPECTIVE
		camera_3d.h_offset = 0
		camera_3d.v_offset = 0
		position = last_position
		rotation = last_rotation
		camera_3d.rotation_degrees = last_camera_rotation_degrees
	else:
		camera_3d.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera_3d.rotation_degrees = Vector3(-90, 0, 0)
		camera_3d.size = 71.2
		camera_3d.h_offset = 0.2
		camera_3d.v_offset = 21.0
		position = Vector3(0, 17, 0)
		rotation = Vector3(0, 0, 0)

func toggle_fps_mode() -> void:
	fps_mode = !fps_mode
	setup_camera()

func handle_pause(pause_state: bool) -> void:
	is_paused = pause_state
