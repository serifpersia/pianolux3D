extends CharacterBody3D

@onready var camera_3d: Camera3D = $Camera3D

var fps_mode: bool = false
var is_paused: bool = false
var fspy_loaded: bool = false

var last_position: Vector3
var last_rotation: Vector3
var last_camera_rotation_degrees: Vector3

var initial_position: Vector3
var initial_rotation: Vector3
var initial_camera_rotation_degrees: Vector3

var fspy_position: Vector3
var fspy_rotation: Vector3
var fspy_camera_rotation: Vector3
var fspy_fov: float = 75.0
var fspy_projection: int = Camera3D.PROJECTION_PERSPECTIVE

@onready var fps: CharacterBody3D = $"."
@onready var calibration_overlay = $"../../../CalibrationOverlay"

func _ready() -> void:
	Global.player = fps

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

func setup_camera() -> void:
	if fps_mode:
		if fspy_loaded:
			position = fspy_position
			rotation = fspy_rotation
			camera_3d.rotation = fspy_camera_rotation
			camera_3d.fov = fspy_fov
			camera_3d.projection = fspy_projection as Camera3D.ProjectionType
			camera_3d.h_offset = 0
			camera_3d.position = Vector3.ZERO
		else:
			position = last_position
			rotation = last_rotation
			camera_3d.rotation_degrees = last_camera_rotation_degrees
			camera_3d.h_offset = 0
			camera_3d.fov = 75.0
			camera_3d.projection = Camera3D.PROJECTION_PERSPECTIVE
			camera_3d.position = Vector3.ZERO
	else:
		last_position = position
		last_rotation = rotation
		last_camera_rotation_degrees = camera_3d.rotation_degrees
		camera_3d.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera_3d.rotation_degrees = Vector3(-90, 0, 0)
		camera_3d.size = 0.716
		camera_3d.h_offset = 0.636
		position = Vector3(0, 0.1, -0.358)
		rotation = Vector3(0, 0, 0)

func toggle_fps_mode() -> void:
	fps_mode = !fps_mode
	setup_camera()

func handle_pause(pause_state: bool) -> void:
	is_paused = pause_state

func handle_perspective() -> void:
	if fps_mode: calibration_overlay.visible = !calibration_overlay.visible
