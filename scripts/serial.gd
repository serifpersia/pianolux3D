extends Control

var serial = SerialPort.new()
var port
var baudrate = 115200

var is_led_on = false

@onready var timer = $"../../SerialTimer"
@onready var serial_list = $"../CanvasLayer/SerialList"
@onready var open_close = $"../CanvasLayer/OpenClose"

# Command bytes
const COMMAND_BYTE1 = 0
const COMMAND_BYTE2 = 1

const COMMAND_BLACKOUT = 2
const COMMAND_SET_BRIGHTNESS = 3
const COMMAND_SET_GLOBAL_COLOR = 4
const COMMAND_FADE_RATE = 5
const COMMAND_STRIP_DIRECTION = 6
const COMMAND_NOTE_ON_DEFAULT = 7
const COMMAND_NOTE_OFF = 8
const COMMAND_SPLASH = 9
const COMMAND_SPLASH_MAX_LENGTH = 10
const COMMAND_VELOCITY = 11
const COMMAND_ANIMATION = 12
const COMMAND_SET_BG = 13
const COMMAND_SET_GUIDE = 14
const COMMAND_SET_LED_VISUALIZER = 15
const COMMAND_NOTE_ON = 16

# Helper function to send a command
func send_command(command_byte: int, args: Array):
	var message = PackedByteArray()
	message.append(COMMAND_BYTE1)
	message.append(COMMAND_BYTE2)
	message.append(command_byte)
	
	for arg in args:
		message.append(arg)
	
	serial.write_raw(message)


func send_command_update_color(c: Color):
	send_command(COMMAND_SET_GLOBAL_COLOR, [int(c.r * 255), int(c.g * 255), int(c.b * 255)])

func send_command_default_note_on(note: int):
	send_command(COMMAND_NOTE_ON_DEFAULT, [note])

func send_command_note_on(c: Color, note: int):
	send_command(COMMAND_NOTE_ON, [int(c.r * 255), int(c.g * 255), int(c.b * 255), note])

func send_command_set_brightness(brightness: int):
	send_command(COMMAND_SET_BRIGHTNESS, [brightness])

func send_command_splash(velocity: int, note: int):
	send_command(COMMAND_SPLASH, [velocity, note])

func send_command_fade_rate(fade_rate: int):
	send_command(COMMAND_FADE_RATE, [fade_rate])

func send_command_animation(animation_index: int, hue: int):
	send_command(COMMAND_ANIMATION, [animation_index, hue])

func send_command_blackout():
	send_command(COMMAND_BLACKOUT, [])

func send_command_note_off(note: int):
	send_command(COMMAND_NOTE_OFF, [note])

func send_command_splash_max_length(value: int):
	send_command(COMMAND_SPLASH_MAX_LENGTH, [value])

func send_command_set_bg(hue: int, saturation: int, brightness: int):
	send_command(COMMAND_SET_BG, [hue, saturation, brightness])

func send_command_velocity(velocity: int, note: int, c: Color):
	send_command(COMMAND_VELOCITY, [velocity, note, int(c.r * 255), int(c.g * 255), int(c.b * 255)])

func send_command_strip_direction(direction: int, num_leds: int):
	send_command(COMMAND_STRIP_DIRECTION, [direction, num_leds])

func send_command_set_guide(current_array: int, hue: int, saturation: int, brightness: int, scale_key_index: int, scale_pattern: Array):
	var message = PackedByteArray()
	message.append(COMMAND_BYTE1)
	message.append(COMMAND_BYTE2)
	message.append(COMMAND_SET_GUIDE)
	
	message.append(current_array)
	message.append(hue)
	message.append(saturation)
	message.append(brightness)
	message.append(scale_key_index)
	
	for value in scale_pattern:
		message.append(value)
	
	serial.write_raw(message)

func send_command_set_led_visualizer(effect: int, color_hue: int):
	send_command(COMMAND_SET_LED_VISUALIZER, [effect, color_hue])

	
func _ready():
	var ports_info = SerialPort.list_ports()
	for info in ports_info:
		serial_list.add_item(info)
	if ports_info.size():
		serial_list.select(0)
		
	update_serial()
	timer.start()


func send_led_command(turn_on: bool):
	var command = PackedByteArray()
	# Use 1 for true, 0 for false
	if turn_on:
		command.append(1)
	else:
		command.append(0)
	
	if serial.is_open():
		serial.write_raw(command)
		print("Sent command:", turn_on if true else false)

func _exit_tree():
	# Ensure we close the serial port when exiting the scene tree
	if serial.is_open():
		serial.close()


func _on_serial_timer_timeout():
	# Toggle LED state
	if serial.is_open():
		#send_led_command(not is_led_on)
		#is_led_on = not is_led_on
		pass

func update_serial():
	port = serial_list.get_item_text(serial_list.selected)
	serial.port = port
	

func _on_serial_list_item_selected(index):
	port = serial_list.get_item_text(index)


func _on_open_close_toggled(button_pressed):
	if button_pressed:
		serial.baudrate = baudrate
		serial.open(port)
		if serial.is_open():
			button_pressed = false
			open_close.text = "Close"
	else:
		serial.close()
		if not serial.is_open():
			button_pressed = true
			open_close.text = "Open"
