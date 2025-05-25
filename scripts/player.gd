extends CharacterBody3D

@onready var camera_3d: Camera3D = $Camera3D
@export var fspy_camera: PackedScene

var fps_mode: bool
var is_paused: bool

var last_position: Vector3
var last_rotation: Vector3
var last_camera_rotation_degrees: Vector3

var initial_position: Vector3
var initial_rotation: Vector3
var initial_camera_rotation_degrees: Vector3

var fspy_position: Vector3
var fspy_rotation: Vector3
var fspy_fov: float
var fspy_projection: int

func _ready() -> void:
	initial_position = position
	initial_rotation = rotation
	initial_camera_rotation_degrees = camera_3d.rotation_degrees

	last_position = initial_position
	last_rotation = initial_rotation
	last_camera_rotation_degrees = initial_camera_rotation_degrees

	var fspy_scene = fspy_camera.instantiate() as Node3D
	if fspy_scene:
		var fspy_camera3d = fspy_scene.get_child(0) as Camera3D
		if fspy_camera3d:
			fspy_position = fspy_camera3d.position
			fspy_rotation = fspy_camera3d.rotation
			fspy_fov = fspy_camera3d.fov
			fspy_projection = fspy_camera3d.projection
		else:
			print("Error: Camera3D not found in fSpy scene!")
		fspy_scene.free()
	else:
		print("Error: Failed to instantiate fSpy scene!")
		
	setup_camera()

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_fps_mode"):
		toggle_fps_mode()

func setup_camera() -> void:
	if fps_mode:
		position = fspy_position
		rotation = fspy_rotation
		camera_3d.position = Vector3.ZERO
		camera_3d.rotation = Vector3.ZERO
		camera_3d.projection = Camera3D.PROJECTION_PERSPECTIVE
		camera_3d.fov = fspy_fov
	else:
		camera_3d.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera_3d.rotation_degrees = Vector3(-90, 0, 0)
		camera_3d.size = 0.717
		position = Vector3(0, 0.1, -0.1995)
		rotation = Vector3(0, 0, 0)

func toggle_fps_mode() -> void:
	fps_mode = !fps_mode
	setup_camera()

func handle_pause(pause_state: bool) -> void:
	is_paused = pause_state
