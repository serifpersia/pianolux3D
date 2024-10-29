extends CharacterBody3D


@onready var camera_3d: Camera3D = $Camera3D
@export var mouse_sensitivity := 0.1

@onready var texture_rect: TextureRect = $CanvasLayer/TextureRect

const SPEED = 25.0
var rotation_x := 0.0
var mouse_lock : bool = false
var fps_mode : bool = false

var last_position
var last_rotation
var last_camera_rotation
		
func _ready():

	last_position = position
	last_rotation = rotation
	
	switch_camera_mode()


func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_mouse_lock"):
		
		if fps_mode:
			mouse_lock = !mouse_lock
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if mouse_lock else Input.MOUSE_MODE_CAPTURED
			if mouse_lock:
				texture_rect.visible = false
			else:
				texture_rect.visible = true
	
	elif Input.is_action_just_pressed("ui_fps_mode"):
		fps_mode = !fps_mode
		switch_camera_mode()

func switch_camera_mode():
		
	if fps_mode:
		mouse_lock = false
		
		texture_rect.visible = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		
		camera_3d.projection = Camera3D.PROJECTION_PERSPECTIVE	
		camera_3d.h_offset = 0		
		camera_3d.v_offset = 0
			
		position = last_position
		rotation = last_rotation
			
		camera_3d.rotation_degrees = Vector3(0,0,0)
			
	else:
		mouse_lock = true
		
		texture_rect. visible = false
		
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
		camera_3d.projection = Camera3D.PROJECTION_ORTHOGONAL
		
		camera_3d.size = 71.2
		camera_3d.h_offset = 0.2
		camera_3d.v_offset = 28.3
			
		position = Vector3(0, 17, 0)
		camera_3d.rotation_degrees = Vector3(-90, 0, 0)
		rotation = Vector3(0,0,0)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		if not mouse_lock:
			rotate_camera(event.relative)

func rotate_camera(mouse_delta: Vector2):
	rotation_x -= mouse_delta.y * mouse_sensitivity
	rotation_x = clamp(rotation_x, -90, 90)

	camera_3d.rotation_degrees.x = rotation_x
	
	rotation_degrees.y -= mouse_delta.x * mouse_sensitivity

func _physics_process(_delta: float) -> void:

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

	if fps_mode:
		if not mouse_lock:
			move_and_slide()
