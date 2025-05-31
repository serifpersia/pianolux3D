extends Node3D

@onready var canvas_layer: CanvasLayer = $CanvasLayer

@onready var midi_keyboard = $MIDI_Keyboard
@onready var midi_white_notes: Node3D = $MIDI_White_Notes
@onready var midi_black_notes: Node3D = $MIDI_Black_Notes
@onready var midi_bg: Node3D = $MIDI_BG

@onready var position_z_slider: HSlider = $CanvasLayer/Menu/Panel_Container/Margin_Sub/VBox_Root/HBox_Pos_Z_Container/Pos_Z_Slider

@onready var controls_menu: MarginContainer = $CanvasLayer/Controls_Menu
@onready var transforms_menu: MarginContainer = $CanvasLayer/Transforms_Menu

@onready var controls_button: Button = $CanvasLayer/Menu/Panel_Container/Margin_Sub/VBox_Root/HBox_BG_C_Container/Controls_Button

var base_x_position: float
var base_y_position: float
var base_z_position: float

var base_x_rotation: float
var base_y_rotation: float
var base_z_rotation: float

var pause_menu: bool = false

func _ready() -> void:
	base_z_position = position.z

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_pause_menu"):
		pause_menu = !pause_menu
		canvas_layer.visible = pause_menu
		controls_button.button_pressed = false
		controls_menu.visible = false

func _on_virtual_keyboard_toggle_toggled(toggled_on: bool) -> void:
	midi_keyboard.visible = toggled_on

func _on_midi_notes_toggle_toggled(toggled_on: bool) -> void:
	midi_white_notes.visible = toggled_on
	midi_black_notes.visible = toggled_on

func _on_bg_toggle_toggled(toggled_on: bool) -> void:
	midi_bg.visible = toggled_on

func _on_particles_toggle_toggled(toggled_on: bool) -> void:
	Global.particles_state = toggled_on

func _on_scale_slider_value_changed(value: float) -> void:
	scale = Vector3(value, value, value)

func _on_pos_x_slider_value_changed(value: float) -> void:
	position.x = base_x_position + value

func _on_pos_y_slider_value_changed(value: float) -> void:
	position.y = base_y_position + value

func _on_pos_z_slider_value_changed(value: float) -> void:
	position.z = base_z_position + value


func _on_controls_button_toggled(toggled_on: bool) -> void:
	controls_menu.visible = toggled_on
	
func _on_transforms_button_toggled(toggled_on: bool) -> void:
	transforms_menu.visible = toggled_on

func _on_rot_x_slider_value_changed(value: float) -> void:
	rotation_degrees.x = base_x_rotation + value


func _on_rot_y_slider_value_changed(value: float) -> void:
	rotation_degrees.y =base_y_rotation + value

func _on_rot_z_slider_value_changed(value: float) -> void:
	rotation_degrees.z =base_z_rotation + value


var file_dialog
var target_camera: Camera3D = null

func _on_fspy_pressed():
	file_dialog = FileDialog.new()
	file_dialog.title = "Open fSpy Project"
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.use_native_dialog = true
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.filters = ["*.fspy"]
	file_dialog.file_selected.connect(_import_fspy_file)
	add_child(file_dialog)
	file_dialog.popup_centered()
	
func _import_fspy_file(path):
	import_fspy(path)
	file_dialog.queue_free()

func import_fspy(filepath: String) -> void:
	var file = FileAccess.open(filepath, FileAccess.READ)
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
	var image_buffer_size = file.get_32()

	file.seek(16)
	
	var json_string = file.get_buffer(state_string_size).get_string_from_utf8()
	var state = JSON.parse_string(json_string)
	if state.has("error") and state["error"] != OK:
		push_error("Error parsing JSON string.")
		file.close()
		return
	
	var camera_params = state["cameraParameters"]
	var principal_point = Vector2(camera_params["principalPoint"]["x"], camera_params["principalPoint"]["y"])
	var fov_horiz = camera_params["horizontalFieldOfView"]
	var camera_transform = camera_params["cameraTransform"]["rows"]
	var image_width = camera_params["imageWidth"]
	var image_height = camera_params["imageHeight"]

	file.get_buffer(image_buffer_size)
	file.close()
	
	#var origin = Vector3(camera_transform[0][3], camera_transform[1][3], camera_transform[2][3])
	#print(origin)
	
	_modify_existing_camera(fov_horiz, camera_transform, principal_point, image_width, image_height)

func _modify_existing_camera(fov_horiz: float, camera_transform: Array, principal_point: Vector2, image_width: int, image_height: int) -> void:
	var camera = player.get_child(1)
	
	if camera == null:
		push_error("No Camera3D found.")
		return
	
	var old_fov = camera.fov
	var old_transform = camera.transform
	var old_h_offset = camera.h_offset
	var old_v_offset = camera.v_offset
	var old_projection = camera.projection
	
	var fov_horiz_degrees = fov_horiz * (180.0 / PI)
	
	if fov_horiz_degrees < 1.0 or fov_horiz_degrees > 179.0:
		push_error("Invalid FOV: " + str(fov_horiz))
		return
	
	camera.fov = fov_horiz_degrees
	camera.set_projection(Camera3D.PROJECTION_PERSPECTIVE)
	
	var transform = Transform3D()
	for i in range(3):
		for j in range(3):
			transform.basis[i][j] = camera_transform[i][j]
	camera.transform = transform
	camera.rotation_edit_mode = Node3D.ROTATION_EDIT_MODE_QUATERNION
	camera.quaternion.z *= -1 
	camera.scale.y = 1
	
	var x_shift_scale = 1.0 if image_height > image_width else float(image_width) / image_height
	var y_shift_scale = 1.0 if image_width > image_height else float(image_height) / image_width
	
	camera.h_offset = x_shift_scale * (0.5 - principal_point.x)
	camera.v_offset = y_shift_scale * (0.5 - principal_point.y)
	
	print("fSpy file import completed.")
