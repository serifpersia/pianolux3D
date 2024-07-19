extends Node3D

@onready var virtual_keyboard = $Virtual_Keyboard
@onready var midi_notes = $MIDI_Notes
@onready var bg = $BG
@onready var timer = $Timer

@onready var rotation_label = $CanvasLayer/Rotation_Label
@onready var position_label = $CanvasLayer/Position_Label
@onready var mode_label = $CanvasLayer/Mode_Label

var mode = "position_z" # Current mode: "rotate_x", "rotate_y", "rotate_z", "position_x", "position_y", "position_z"
var movement_step = 0.25

func _ready():
	set_process(true)
	timer.wait_time = 0.05
	timer.start()
	update_labels()

func _process(delta):
	# Handle input for mode selection
	if Input.is_action_just_pressed("ui_q"):
		mode = "rotate_x"
		update_mode_label()
	elif Input.is_action_just_pressed("ui_w"):
		mode = "rotate_y"
		update_mode_label()
	elif Input.is_action_just_pressed("ui_e"):
		mode = "rotate_z"
		update_mode_label()
	elif Input.is_action_just_pressed("ui_a"):
		mode = "position_x"
		update_mode_label()
	elif Input.is_action_just_pressed("ui_s"):
		mode = "position_y"
		update_mode_label()
	elif Input.is_action_just_pressed("ui_d"):
		mode = "position_z"
		update_mode_label()
	elif Input.is_action_just_pressed("ui_r"):
		reset_to_default()

func _on_toggle_keyboard_toggled(toggled_on):
	virtual_keyboard.visible = toggled_on

func _on_toggle_midi_toggled(toggled_on):
	midi_notes.visible = toggled_on

func _on_toggle_bg_toggled(toggled_on):
	bg.visible = toggled_on

func _on_timer_timeout():
	if Input.is_action_pressed("ui_upp"):
		handle_movement_or_rotation(1)
	elif Input.is_action_pressed("ui_downn"):
		handle_movement_or_rotation(-1)

func handle_movement_or_rotation(direction):
	match mode:
		"rotate_x":
			rotation_degrees.x += movement_step * direction
			print("Rotation X: ", String("%.1f" % rotation_degrees.x))
		"rotate_y":
			rotation_degrees.y += movement_step * direction
			print("Rotation Y: ", String("%.1f" % rotation_degrees.y))
		"rotate_z":
			rotation_degrees.z += movement_step * direction
			print("Rotation Z: ", String("%.1f" % rotation_degrees.z))
		"position_x":
			position.x += movement_step * direction
			print("Position X: ", String("%.1f" % position.x))
		"position_y":
			position.y += movement_step * direction
			print("Position Y: ", String("%.1f" % position.y))
		"position_z":
			position.z += movement_step * direction
			print("Position Z: ", String("%.1f" % position.z))
	update_labels()

func reset_to_default():
	rotation_degrees = Vector3(0, 0, 0)
	position = Vector3(0, 0, -16)
	print("Rotation reset to (0.0, 0.0, 0.0)")
	print("Position reset to (0.0, 0.0, -16.0)")
	update_labels()

func update_labels():
	position_label.text = "Position: X = %.1f Y = %.1f Z = %.1f" % [position.x, position.y, position.z]
	rotation_label.text = "Rotation: X = %.1f Y = %.1f Z = %.1f" % [rotation_degrees.x, rotation_degrees.y, rotation_degrees.z]

func update_mode_label():
	match mode:
		"rotate_x":
			mode_label.text = "Mode: Rotation X"
		"rotate_y":
			mode_label.text = "Mode: Rotation Y"
		"rotate_z":
			mode_label.text = "Mode: Rotation Z"
		"position_x":
			mode_label.text = "Mode: Position X"
		"position_y":
			mode_label.text = "Mode: Position Y"
		"position_z":
			mode_label.text = "Mode: Position Z"
