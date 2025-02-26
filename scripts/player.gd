extends CharacterBody3D

@onready var camera_3d: Camera3D = $Camera3D
@export var mouse_sensitivity := 0.1
@onready var texture_rect: TextureRect = $CanvasLayer/TextureRect

const SPEED = 35.0
@export var precise_move_speed: float = 6.0
@export var precise_rotation_speed: float = 1.0
@export var precise_roll_speed: float = 1.0

var rotation_x := 0.0
var mouse_lock: bool
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

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_mouse_lock") and fps_mode:
		mouse_lock = !mouse_lock
		set_mouse_lock_and_texture_visibility()
	elif Input.is_action_just_pressed("ui_fps_mode"):
		toggle_fps_mode()
	elif Input.is_action_just_pressed("ui_reset_fps_view"):
		if fps_mode:
			position = initial_position
			rotation = initial_rotation
			camera_3d.rotation_degrees = initial_camera_rotation_degrees
			rotation_x = 0.0
			camera_3d.rotation_degrees.z = 0.0
	elif Input.is_action_just_pressed("ui_precise") and fps_mode:
		toggle_camera_mode()

	if not using_fps_script and fps_mode and not mouse_lock:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
				camera_3d.rotation_degrees.z -= precise_roll_speed
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
				camera_3d.rotation_degrees.z += precise_roll_speed

func _unhandled_input(event):
	if event is InputEventMouseMotion and fps_mode and not mouse_lock:
		rotate_camera(event.relative)

func _physics_process(delta: float) -> void:
	if not fps_mode or is_paused:
		return

	var current_speed = SPEED if using_fps_script else precise_move_speed
	var current_rotation_speed = mouse_sensitivity if using_fps_script else precise_rotation_speed * delta

	var input_dir := Input.get_vector("ui_a", "ui_d", "ui_w", "ui_s")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	if Input.is_action_pressed("ui_go_up"):
		velocity.y = current_speed
	elif Input.is_action_pressed("ui_go_down"):
		velocity.y = -current_speed
	else:
		velocity.y = 0

	if not mouse_lock:
		last_position = position
		last_rotation = rotation
		last_camera_rotation_degrees = camera_3d.rotation_degrees
		move_and_slide()

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

	if fps_mode:
		mouse_lock = false
		texture_rect.visible = true
	else:
		mouse_lock = true
		texture_rect.visible = false

	setup_camera()
	set_mouse_lock_and_texture_visibility()

func handle_pause(pause_state: bool) -> void:
	is_paused = pause_state
	mouse_lock = pause_state
	if fps_mode:
		set_mouse_lock_and_texture_visibility()

func rotate_camera(mouse_delta: Vector2):
	var rotation_speed = mouse_sensitivity if using_fps_script else precise_rotation_speed * get_process_delta_time()
	rotation_x = clamp(rotation_x - mouse_delta.y * rotation_speed, -90, 90)
	camera_3d.rotation_degrees.x = rotation_x
	rotate_y(-mouse_delta.x * rotation_speed * PI / 180.0)

func toggle_camera_mode() -> void:
	using_fps_script = !using_fps_script
	print("Switched to ", "FPS" if using_fps_script else "Precise", " mode")
