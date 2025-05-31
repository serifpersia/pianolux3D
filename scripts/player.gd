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

func handle_fspy() -> void:
	var file_dialog = FileDialog.new()
	file_dialog.use_native_dialog = true
	file_dialog.title = "Open fSpy Project"
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.filters = ["*.fspy"]
	file_dialog.file_selected.connect(_import_fspy_file)
	get_tree().root.add_child(file_dialog)
	file_dialog.popup_centered()

func _import_fspy_file(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Unable to open fSpy file.")
		return
	
	var buffer = file.get_buffer(4)
	var file_id = buffer[0] | (buffer[1] << 8) | (buffer[2] << 16) | (buffer[3] << 24)
	if file_id != 2037412710:
		push_error("File is not a valid fSpy project.")
		file.close()
		return
	
	var project_version = file.get_32()
	if project_version != 1:
		push_error("Unsupported fSpy project version.")
		file.close()
		return
	
	var state_string_size = file.get_32()
	
	file.seek(16)
	var json_string = file.get_buffer(state_string_size).get_string_from_utf8()
	var state = JSON.parse_string(json_string)
	if state == null or (state.has("error") and state["error"] != OK):
		push_error("Error parsing JSON string.")
		file.close()
		return

	var camera_params = state["cameraParameters"]
	var fov_horiz = camera_params["horizontalFieldOfView"]
	var camera_transform = camera_params["cameraTransform"]["rows"]
	var image_width = camera_params["imageWidth"]
	var image_height = camera_params["imageHeight"]
	
	file.close()
	
	var aspect_ratio = float(image_width) / image_height
	var fov_vertical = 2.0 * atan(tan(fov_horiz / 2.0) / aspect_ratio) * (180.0 / PI)
	
	fspy_fov = clamp(fov_vertical, 1.0, 179.0)
	
	var basis_col_x = Vector3(camera_transform[0][0], camera_transform[2][0], -camera_transform[1][0])
	var basis_col_y = Vector3(camera_transform[0][1], camera_transform[2][1], -camera_transform[1][1])
	var basis_col_z = Vector3(camera_transform[0][2], camera_transform[2][2], -camera_transform[1][2])
	
	var _basis = Basis(basis_col_x, basis_col_y, basis_col_z)
	
	fspy_position = Vector3(
		camera_transform[0][3],
		camera_transform[2][3],
		-camera_transform[1][3]
	)
	fspy_rotation = _basis.get_euler()
	fspy_camera_rotation = Vector3.ZERO
	fspy_projection = Camera3D.PROJECTION_PERSPECTIVE
	fspy_loaded = true
	
	if fps_mode:
		setup_camera()
	
	print("fSpy file imported successfully.")
	print("fSpy Position:", fspy_position)
	print("fSpy Rotation (Euler):", fspy_rotation)
	print("fSpy Camera Rotation:", fspy_camera_rotation)
	print("fSpy FOV:", fspy_fov)
	print("fSpy Projection:", fspy_projection)
