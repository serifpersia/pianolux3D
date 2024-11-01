extends CharacterBody3D

@onready var camera_3d: Camera3D = $Camera3D
@export var mouse_sensitivity := 0.1
@onready var texture_rect: TextureRect = $CanvasLayer/TextureRect

@export var midi_scene: Node3D

const SPEED = 25.0
var rotation_x := 0.0
var mouse_lock: bool = false
var fps_mode: bool = false
var is_paused: bool = false

var last_position
var last_rotation
var last_camera_rotation_degrees

var initial_position
var initial_rotation
var initial_rotation_degrees

func _ready() -> void:
	initial_position = position
	initial_rotation = rotation
	initial_rotation_degrees = camera_3d.rotation_degrees

	last_position = initial_position
	last_rotation = initial_rotation
	last_camera_rotation_degrees = initial_rotation_degrees

	setup_camera()

func set_mouse_lock_and_texture_visibility() -> void:
	texture_rect.visible = not mouse_lock
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if mouse_lock else Input.MOUSE_MODE_CAPTURED

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
	rotation_x = 0.0
	setup_camera()
	set_mouse_lock_and_texture_visibility()

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_mouse_lock"):
		if fps_mode:
			mouse_lock = !mouse_lock
			set_mouse_lock_and_texture_visibility()
	elif Input.is_action_just_pressed("ui_fps_mode"):
		toggle_fps_mode()
	elif Input.is_action_just_pressed("ui_reset_fps_view"):
		if fps_mode:
			position = initial_position
			rotation = initial_rotation
			camera_3d.rotation_degrees = initial_rotation_degrees
			rotation_x = 0.0
		else:
			midi_scene.scale = Vector3(1, 1, 1)
			midi_scene.position.z = 0

func handle_pause(pause_state: bool) -> void:
	is_paused = pause_state
	mouse_lock = pause_state
	if fps_mode:
		set_mouse_lock_and_texture_visibility()

func _physics_process(_delta: float) -> void:
	if not fps_mode:
		return
		
	var input_dir := Input.get_vector("ui_a", "ui_d", "ui_w", "ui_s")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		
	if Input.is_action_pressed("ui_go_up"):
		velocity.y = SPEED
	elif Input.is_action_pressed("ui_go_down"):
		velocity.y = -SPEED
	else:
		velocity.y = 0

	if not mouse_lock and not is_paused:
		last_position = position
		last_rotation = rotation
		last_camera_rotation_degrees = camera_3d.rotation_degrees
		move_and_slide()

func switch_camera_mode():
	setup_camera()
	set_mouse_lock_and_texture_visibility()

func _unhandled_input(event):
	if event is InputEventMouseMotion and fps_mode and not mouse_lock:
		rotate_camera(event.relative)

func rotate_camera(mouse_delta: Vector2):
	rotation_x = clamp(rotation_x - mouse_delta.y * mouse_sensitivity, -90, 90)
	camera_3d.rotation_degrees.x = rotation_x
	rotate_y(-mouse_delta.x * mouse_sensitivity * PI / 180.0)
