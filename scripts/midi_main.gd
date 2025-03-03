extends Node3D

@onready var canvas_layer: CanvasLayer = $CanvasLayer

@onready var midi_keyboard = $MIDI_Keyboard
@onready var midi_notes = $MIDI_Notes
@onready var midi_bg: Node3D = $MIDI_BG
@onready var midi_particles = $MIDI_Particles

@export var player : CharacterBody3D
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

		player.handle_pause(pause_menu)

func _on_virtual_keyboard_toggle_toggled(toggled_on: bool) -> void:
	midi_keyboard.visible = toggled_on

func _on_midi_notes_toggle_toggled(toggled_on: bool) -> void:
	midi_notes.visible = toggled_on

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
	# Open native file dialog to select an fSpy file
	file_dialog = FileDialog.new()
	file_dialog.title = "Open fSpy Project"
	file_dialog.mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.filters = ["*.fspy"]
	file_dialog.file_selected.connect(_import_fspy_file)
	add_child(file_dialog)  # Add dialog to this node
	file_dialog.popup_centered()

func _import_fspy_file(path):
	# Call the import function for the selected file
	print("Importing fSpy file: ", path)
	import_fspy(path)
	
	# Clean up file dialog after selection
	file_dialog.queue_free()

func import_fspy(filepath: String) -> void:
	var file = FileAccess.open(filepath, FileAccess.READ)
	if file == null:
		push_error("Unable to open fSpy file.")
		return
	
	var buffer = file.get_buffer(4)
	var file_id = buffer[0] | (buffer[1] << 8) | (buffer[2] << 16) | (buffer[3] << 24)
	
	# Verify file identifier
	if file_id != 2037412710:
		push_error("The file is not a valid fSpy project.")
		file.close()
		return
	
	# Read project version
	var project_version = file.get_32()
	if project_version != 1:
		push_error("Unsupported fSpy project version.")
		file.close()
		return
	
	# Read JSON string size and image buffer size
	var state_string_size = file.get_32()
	var image_buffer_size = file.get_32()
	
	# Read JSON string
	file.seek(16)  # Skip first 16 bytes
	var json_string = file.get_buffer(state_string_size).get_string_from_utf8()
	var state = JSON.parse_string(json_string)
	if state.has("error") and state["error"] != OK:
		push_error("Error parsing JSON string.")
		file.close()
		return
	
	# Extract camera parameters
	var camera_params = state["cameraParameters"]
	var principal_point = Vector2(camera_params["principalPoint"]["x"], camera_params["principalPoint"]["y"])
	var fov_horiz = camera_params["horizontalFieldOfView"]
	var camera_transform = camera_params["cameraTransform"]["rows"]
	var image_width = camera_params["imageWidth"]
	var image_height = camera_params["imageHeight"]
	
	# Skip image data
	file.get_buffer(image_buffer_size)
	file.close()
	
	# Find and modify the existing camera, tracking changes
	_modify_existing_camera(fov_horiz, camera_transform, principal_point, image_width, image_height)

func _modify_existing_camera(fov_horiz: float, camera_transform: Array, principal_point: Vector2, image_width: int, image_height: int) -> void:
	# List to track changes
	var changes = []
	
	var camera = player.get_child(1)
	
	if camera == null:
		push_error("No Camera3D found.")
		return
	
	# Store original values for comparison
	var old_fov = camera.fov
	var old_transform = camera.transform
	var old_h_offset = camera.h_offset
	var old_v_offset = camera.v_offset
	var old_projection = camera.projection
	
	# Modify the existing camera
	# Convert from radians to degrees
	var fov_horiz_degrees = fov_horiz * (180.0 / PI)
	
	# Verify FOV value
	if fov_horiz_degrees < 1.0 or fov_horiz_degrees > 179.0:
		push_error("Invalid FOV: " + str(fov_horiz))
		return
	
	camera.fov = fov_horiz_degrees
	if old_fov != camera.fov:
		changes.append("FOV changed from " + str(old_fov) + " to " + str(camera.fov))
	
	camera.set_projection(Camera3D.PROJECTION_PERSPECTIVE)
	if old_projection != camera.projection:
		changes.append("Projection changed from " + str(old_projection) + " to " + str(camera.projection))
	
	# Set up camera transform
	var transform = Transform3D()
	for i in range(3):  # Only 0, 1, 2 for 3x3 part
		for j in range(3):  # Assume camera_transform has 4 columns
			transform.basis[i][j] = camera_transform[i][j]
	
	camera.transform = transform
	if old_transform != camera.transform:
		changes.append("Transform changed from " + str(old_transform) + " to " + str(camera.transform))
	
	# Set camera shift to align principal point
	var x_shift_scale = 1.0
	var y_shift_scale = 1.0
	if image_height > image_width:
		x_shift_scale = float(image_width) / image_height
	else:
		y_shift_scale = float(image_height) / image_width
	
	camera.h_offset = x_shift_scale * (0.5 - principal_point.x)
	if old_h_offset != camera.h_offset:
		changes.append("Horizontal offset changed from " + str(old_h_offset) + " to " + str(camera.h_offset))
	
	camera.v_offset = y_shift_scale * (0.5 - principal_point.y)
	if old_v_offset != camera.v_offset:
		changes.append("Vertical offset changed from " + str(old_v_offset) + " to " + str(camera.v_offset))
	
	# Print the list of changes
	if changes.size() > 0:
		print("fSpy camera modifications completed. Changes made:")
		for change in changes:
			print("- " + change)
	else:
		print("fSpy camera modifications completed. No changes detected.")
