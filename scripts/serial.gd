extends Control

var serial = SerialPort.new()
var port
var baudrate = 115200
var MODE = 0

var led_mode_list = ["Default", "Splash", "Animation"]
var led_animations_list = [
	"RainbowColors",
	"RainbowStripeColor",
	"OceanColors",
	"CloudColors",
	"LavaColors",
	"ForestColors",
	"PartyColors",
	"SineWave",
	"SparkleDots",
	"Snake"
]

@onready var serial_list = $"../CanvasLayer/SerialList"
@onready var open_close = $"../CanvasLayer/OpenClose"
@onready var modes_list = $"../CanvasLayer/ModesList"
@onready var animations_list = $"../CanvasLayer/AnimationsList"

@onready var brightness_slider = $"../CanvasLayer/Brightness_Slider"
@onready var fade_rate_slider = $"../CanvasLayer/FadeRate_Slider"
@onready var splash_length_slider = $"../CanvasLayer/SplashLength_Slider"

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
	if serial.is_open():
		serial.write_raw(message)
	else:
		print("Can't send commmand to serial device. Busy port or not open!")


func gamma_correction(value: float, gamma: float) -> int:
	return int(pow(clamp(value, 0.0, 1.0), gamma) * 255)

func send_command_update_color(c: Color):
	var gamma = 5.0
	
	# Apply gamma correction and clamp the values
	var r = gamma_correction(c.r, gamma)
	var g = gamma_correction(c.g, gamma)
	var b = gamma_correction(c.b, gamma)

	send_command(COMMAND_SET_GLOBAL_COLOR, [r, g, b])

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


var transposition : int = 0

func map_midi_note_to_led(midi_note: int, lowest_note: int, highest_note: int, strip_led_number: int, out_min: int) -> int:
	midi_note -= transposition
	var out_max = out_min + strip_led_number - 1
	var mapped_led = (midi_note - lowest_note) * float(out_max - out_min) / float(highest_note - lowest_note)
	return int(mapped_led) + out_min
	
func _ready():
	var ports_info = SerialPort.list_ports()
	for info in ports_info:
		serial_list.add_item(info)
	if ports_info.size():
		serial_list.select(0)

	for mode in led_mode_list:
		modes_list.add_item(mode)
	
	if led_mode_list.size() > 0:
		modes_list.select(0)

	for animation in led_animations_list:
		animations_list.add_item(animation)
	
	if led_animations_list.size() > 0:
		animations_list.select(0)
			
	update_serial()

func _exit_tree():
	# Ensure we close the serial port when exiting the scene tree
	if serial.is_open():
		serial.close()

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


func _on_modes_list_item_selected(index):
	send_command_blackout()
	match index:
		0:
			# Default mode
			MODE = 0
			set_defaults(8, 255, 255)
		1:
			# Splash mode
			MODE = 1
			set_defaults(8, 255, 50)
		2:
			# Animation mode
			MODE = 2
			set_defaults(8, 255, 0)
			send_command_animation(0, 0)

func _on_animations_list_item_selected(index):
	if MODE == 2:
		match index:
			0:
				# Handle "RainbowColors" animation
				send_command_animation(index, 0)
			1:
				# Handle "RainbowStripeColor" animation
				send_command_animation(index, 1)
			2:
				# Handle "OceanColors" animation
				send_command_animation(index, 2)
			3:
				# Handle "CloudColors" animation
				send_command_animation(index, 3)
			4:
				# Handle "LavaColors" animation
				send_command_animation(index, 4)
			5:
				# Handle "ForestColors" animation
				send_command_animation(index, 5)
			6:
				# Handle "PartyColors" animation
				send_command_animation(index, 6)
			7:
				# Handle "SineWave" animation
				send_command_animation(index, 7)
			8:
				# Handle "SparkleDots" animation
				send_command_animation(index, 8)
			9:
				# Handle "Snake" animation
				send_command_animation(index, 9)

# Mode-specific settings function
func set_defaults(splash_length: int, brightness: int, fade_rate: int):
	splash_length_slider.value = splash_length
	brightness_slider.value = brightness
	fade_rate_slider.value = fade_rate

	# Send commands based on slider values
	send_command_splash_max_length(splash_length)
	send_command_set_brightness(brightness)
	send_command_fade_rate(fade_rate)
	
func _on_brightness_slider_value_changed(value):
	send_command_set_brightness(int(value))

func _on_fade_rate_slider_value_changed(value):
	send_command_fade_rate(int(value))

func _on_splash_length_slider_value_changed(value):
	send_command_splash_max_length(int(value))
