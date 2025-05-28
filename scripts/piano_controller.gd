extends Node

@onready var serial_list: OptionButton = $"../CanvasLayer/Menu/Panel_Container/Margin_Sub/VBox_Root/HBox_Serial_Port_Container/SerialList"
@onready var open_close: Button = $"../CanvasLayer/Menu/Panel_Container/Margin_Sub/VBox_Root/HBox_C_Type_Container/OpenClose"
@onready var modes_list: OptionButton = $"../CanvasLayer/Menu/Panel_Container/Margin_Sub/VBox_Root/HBox_L_Mode_Container/ModesList"
@onready var animations_list: OptionButton = $"../CanvasLayer/Menu/Panel_Container/Margin_Sub/VBox_Root/HBox_Animation_Container/AnimationsList"
@onready var brightness_slider: HSlider = $"../CanvasLayer/Menu/Panel_Container/Margin_Sub/VBox_Root/HBox_Brightness_Container/Brightness_Slider"
@onready var fade_rate_slider: HSlider = $"../CanvasLayer/Menu/Panel_Container/Margin_Sub/VBox_Root/HBox_Fade_Container/Fade_Slider"
@onready var splash_length_slider: HSlider = $"../CanvasLayer/Menu/Panel_Container/Margin_Sub/VBox_Root/HBox_S_L_Container/Splash_Length_Slider"
@onready var bg_brightness_slider: HSlider = $"../CanvasLayer/Menu/Panel_Container/Margin_Sub/VBox_Root/HBox_BG_Brightness_Container/BG_Brightness_Slider"

@onready var piano_size_label: Label = $"../CanvasLayer/Menu/Panel_Container/Margin_Sub/VBox_Root/HBox_P_Size_Container/PianoSize_Label"
@onready var web_socket_toggle: CheckButton = $"../CanvasLayer/Menu/Panel_Container/Margin_Sub/VBox_Root/HBox_C_Type_Container/WebSocket_Toggle"

@onready var load_profile_file_dialog: FileDialog = $"../CanvasLayer/LoadProfileFileDialog"
@onready var save_profile_file_dialog: FileDialog = $"../CanvasLayer/SaveProfileFileDialog"

@onready var midi: Node3D = $".."
@onready var midi_bg: Node3D = $"../MIDI_BG"

@onready var midi_keyboard: Node3D = $"../MIDI_Keyboard"
@onready var midi_white_notes: Node3D = $"../MIDI_White_Notes"
@onready var midi_black_notes: Node3D = $"../MIDI_Black_Notes"
@onready var midi_white_note_particles: Node3D = $"../MIDI_WhiteNoteParticles"
@onready var midi_black_note_particles: Node3D = $"../MIDI_BlackNoteParticles"

@onready var world_environment: WorldEnvironment = $"../../WorldEnvironment"

var serial_thread : Thread = Thread.new()
var serial_queue : Array = []
var serial_lock : Mutex = Mutex.new()
var is_running : bool = true

var web_socket = WebSocketPeer.new()
var has_printed_open_message = false

var useESP32
var serial = SerialPort.new()
var port
var baudrate = 115200

var udp_peer: PacketPeerUDP = PacketPeerUDP.new()
var udp_port: int = 12345

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
const COMMAND_NOTE_ON_RANDOM_SERIAL = 16

var MODE = 0
var currentColor = Color(0.622,1.25,0)

var led_mode_list = ["Default", "Splash", "Random", "Velocity", "Animation"]
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

var counter: int = 0

var piano_size_labels = {
	0: "Piano 88 Keys",
	1: "Piano 76 Keys",
	2: "Piano 73 Keys",
	3: "Piano 61 Keys",
	4: "Piano 49 Keys"
}

var stripLedNum: int = 176
var firstNoteSelected: int = 21
var lastNoteSelected: int = 108

var fixLED_Toggle = false
var bgLED_Toggle = false
var octaveShift_Toggle = false

func send_command(command_byte: int, args: Array):
	var message = PackedByteArray()
	message.append(COMMAND_BYTE1)
	message.append(COMMAND_BYTE2)
	message.append(command_byte)
	
	for arg in args:
		message.append(arg)
	if serial.is_open():
		serial.write_raw(message)

func send_json_command(action: String, value: Variant) -> void:
	var data = {
		"action": action,
		"value": value
	}
	
	var json_string = JSON.stringify(data)
	
	if web_socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		web_socket.send_text(json_string)
		print("Sent JSON Command: ", json_string)
	else:
		print("WebSocket is not connected")
		
func gamma_correction(value: float, gamma: float) -> int:
	return int(pow(clamp(value, 0.0, 1.0), gamma) * 255)

func create_hsb_data(action: String, index: int, hsb: Dictionary) -> Dictionary:
	var value = 0.0
	match index:
		0: value = hsb["hue"]
		1: value = hsb["saturation"]
		2: value = hsb["brightness"]
	
	return {
		"action": action,
		"value": value
	}

func send_command_update_color(c: Color):
	var gamma = 2.2
	
	var r = gamma_correction(c.r, gamma)
	var g = gamma_correction(c.g, gamma)
	var b = gamma_correction(c.b, gamma)

	var hsb = rgb_to_hsb(r / 255.0, g / 255.0, b / 255.0)
	
	if useESP32:
		var actions = ["Hue", "Saturation", "Brightness"]
		
		for i in range(3):
			var action = actions[i]
			var data = create_hsb_data(action, i, hsb)
			
			if data:
				send_json_command(data["action"], data["value"])
	else:
		if useESP32:
			print("WebSocket is not open or ESP32 logic is not active.")
		send_command(COMMAND_SET_GLOBAL_COLOR, [r, g, b])



func send_command_default_note_on(note: int, velocity : int):
	if useESP32:
		send_midi_note_on(note, velocity)
	else:
		send_command(COMMAND_NOTE_ON_DEFAULT, [note])

func send_command_note_on(note: int):
	if useESP32:
		send_midi_note_on(note, 0)
	else:
		var random_hue = randi_range(0, 359)

		var saturation = 1.0
		var brightness = 1.0

		var random_color = Color.from_hsv(random_hue / 360.0, saturation, brightness)

		var red = int(random_color.r * 255)
		var green = int(random_color.g * 255)
		var blue = int(random_color.b * 255)
		
		send_command(COMMAND_NOTE_ON_RANDOM_SERIAL, [red, green, blue, note])

func send_command_set_brightness(brightness: int):
	send_command(COMMAND_SET_BRIGHTNESS, [brightness])

func send_command_splash(velocity: int, note: int):
	if useESP32:
		send_command_default_note_on(note, velocity)
	else:
		send_command(COMMAND_SPLASH, [velocity, note])

func send_command_fade_rate(fade_rate: int):
	send_command(COMMAND_FADE_RATE, [fade_rate])

func send_command_animation(animation_index: int, hue: int):
	send_command(COMMAND_ANIMATION, [animation_index, hue])

func send_command_blackout():
	send_command(COMMAND_BLACKOUT, [])

func send_command_note_off(note: int):
	if useESP32:
		send_midi_note_off(note)
	else:
		send_command(COMMAND_NOTE_OFF, [note])

func send_command_splash_max_length(value: int):
	send_command(COMMAND_SPLASH_MAX_LENGTH, [value])

func send_command_set_bg(hue: int, saturation: int, brightness: int):
	send_command(COMMAND_SET_BG, [hue, saturation, brightness])

func send_command_velocity(velocity: int, note: int):
	if useESP32:
		send_command_default_note_on(note, velocity)
	else:
		send_command(COMMAND_VELOCITY, [velocity, note])

func send_command_strip_direction(direction: int, num_leds: int):
	send_command(COMMAND_STRIP_DIRECTION, [direction, num_leds])

var transposition : int = 0

func map_midi_note_to_led(midi_note: int, lowest_note: int, highest_note: int, strip_led_number: int, out_min: int) -> int:
	var offset = Global.offset_map.get(midi_note, 0)
	
	midi_note -= transposition
	
	var out_max = out_min + strip_led_number - 1
	var mapped_led = (midi_note - lowest_note) * float(out_max - out_min) / float(highest_note - lowest_note)

	mapped_led += offset

	return int(mapped_led) + out_min

func fixed_map_midi_note_to_led(midi_note: int, lowest_note: int, highest_note: int, strip_led_number: int, out_min: int) -> int:
	midi_note -= transposition
	
	var out_max = out_min + strip_led_number - 1
	var mapped_led = (midi_note - lowest_note) * float(out_max - out_min) / float(highest_note - lowest_note)

	if midi_note >= 57:
		mapped_led -= 1

	if midi_note >= 93:
		mapped_led -= 1

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

	udp_peer.set_broadcast_enabled(true)
	udp_peer.set_dest_address("255.255.255.255", udp_port)

	_request_esp32_ip()

	serial_thread.start(_thread_serial_handler)

	OS.open_midi_inputs()

func _exit_tree():
	if serial.is_open():
		send_command_set_bg(0,0,0)
		send_command_blackout()
		serial.close()

	is_running = false

	if serial_thread:
		serial_thread.wait_to_finish()

func _input(event):
	if event is InputEventMIDI:
		if event.message == MIDI_MESSAGE_NOTE_ON:
			midi_white_notes.on_note_on(event.pitch)
			midi_black_notes.on_note_on(event.pitch)

			midi_keyboard.update_key_material(event.pitch, true)
			midi_white_note_particles.spawn_particle(event.pitch)
			midi_black_note_particles.spawn_particle(event.pitch)
			

			var notePushed

			if fixLED_Toggle:
				notePushed = fixed_map_midi_note_to_led(event.pitch, firstNoteSelected, lastNoteSelected, stripLedNum, 1)
			else:
				notePushed = map_midi_note_to_led(event.pitch, firstNoteSelected, lastNoteSelected, stripLedNum, 1)

			var command_data = {
				"mode": MODE,
				"velocity": event.velocity,
				"notePushed": notePushed,
				"type": "note_on"
			}

			serial_lock.lock()
			serial_queue.append(command_data)
			serial_lock.unlock()

		elif event.message == MIDI_MESSAGE_NOTE_OFF:
			midi_white_notes.on_note_off(event.pitch)
			midi_black_notes.on_note_off(event.pitch)
			
			midi_keyboard.update_key_material(event.pitch, false)
			midi_white_note_particles.stop_particle(event.pitch)
			midi_black_note_particles.stop_particle(event.pitch)
			
			var notePushed

			if fixLED_Toggle:
				notePushed = fixed_map_midi_note_to_led(event.pitch, firstNoteSelected, lastNoteSelected, stripLedNum, 1)
			else:
				notePushed = map_midi_note_to_led(event.pitch, firstNoteSelected, lastNoteSelected, stripLedNum, 1)

			var command_data = {
				"notePushed": notePushed,
				"type": "note_off"
			}

			serial_lock.lock()
			serial_queue.append(command_data)
			serial_lock.unlock()


func _thread_serial_handler():
	while is_running:
		
		serial_lock.lock()

		if serial_queue.size() > 0:
			var command_data = serial_queue.pop_front()

			serial_lock.unlock()

			if command_data.type == "note_on":
				
				match command_data.mode:
					0:
						send_command_default_note_on(command_data.notePushed, command_data.velocity)
					1:
						send_command_splash(command_data.velocity, command_data.notePushed)
					2:
						send_command_note_on(command_data.notePushed)
					3:
						send_command_velocity(command_data.velocity, command_data.notePushed)

			elif command_data.type == "note_off":
				send_command_note_off(command_data.notePushed)
		else:
			serial_lock.unlock()

		OS.delay_msec(10)

func _process(_delta):
	if useESP32:
		web_socket.poll()
		udp_peer.set_broadcast_enabled(true)

		var state = web_socket.get_ready_state()

		if state == WebSocketPeer.STATE_OPEN:
			if not has_printed_open_message:
				print("WebSocket is open.")
				has_printed_open_message = true
			
			#while web_socket.get_available_packet_count() > 0:

			#	var packet = web_socket.get_packet()
			#	var json_string = packet.get_string_from_utf8()
				
			#	var json = JSON.new()
			#	var error = json.parse(json_string)
			#	if error == OK:
			#		var json_data = json.data
			#		print("Parsed JSON Data: ", json_data)
			#	else:
			#		print("Failed to parse JSON: ", json.get_error_message(), " at line ", json.get_error_line())

		elif state == WebSocketPeer.STATE_CLOSED:
			var code = web_socket.get_close_code()
			var reason = web_socket.get_close_reason()

			print("WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])

			set_process(false)

		while udp_peer.get_available_packet_count() > 0:

			_on_data_received()
			udp_peer.set_broadcast_enabled(false)

func update_serial():
	port = serial_list.get_item_text(serial_list.selected)
	serial.port = port

func _on_serial_list_item_selected(index):
	port = serial_list.get_item_text(index)

func _on_open_close_toggled(button_pressed):
	if button_pressed:
		if web_socket_toggle.button_pressed:
			print("ESP32 logic is now active.")
			web_socket.connect_to_url("ws://pianolux3d.local:81")
			useESP32 = true
			open_close.text = "Close"
		else:
			serial.baudrate = baudrate
			serial.open(port)
			if serial.is_open():
				button_pressed = false
				open_close.text = "Close"
				print("serial open: ", serial.port)
			else:
				print("Failed to open serial port.")
	else:
		if web_socket_toggle.button_pressed:
			if web_socket.get_ready_state() == web_socket.STATE_OPEN:
				web_socket.close()
				print("WebSocket closed.")
			useESP32 = false
			open_close.text = "Open"
		else:
			serial.close()
			if not serial.is_open():
				button_pressed = true
				open_close.text = "Open"
				print("serial closed: ", serial.port)
			else:
				print("Failed to close serial port.")

func _on_modes_list_item_selected(index):
	send_command_blackout()
	match index:
		0:
			MODE = 0
			if useESP32:
				send_json_command("ChangeLEDModeAction", 0)
			set_defaults(8, 255, 255)
		1:
			MODE = 1
			if useESP32:
				send_json_command("ChangeLEDModeAction", 1)
			set_defaults(8, 255, 55)
		2:
			MODE = 2
			if useESP32:
				send_json_command("ChangeLEDModeAction", 2)
			set_defaults(8, 255, 255)
		3:
			MODE = 3
			if useESP32:
				send_json_command("ChangeLEDModeAction", 3)
			set_defaults(8, 255, 255)
		4:
			MODE = 4
			if useESP32:
				send_json_command("ChangeLEDModeAction", 4)
				set_defaults(8, 255, 0)
			send_command_animation(0, 0)

func _on_animations_list_item_selected(index):
	if MODE == 4:
		match index:
			0:
				if useESP32:
					send_json_command("ChangeAnimationAction", 0)
				else:
					send_command_animation(index, 0)
				
			1:
				if useESP32:
					send_json_command("ChangeAnimationAction", 1)
				else:
					send_command_animation(index, 1)
				
			2:
				if useESP32:
					send_json_command("ChangeAnimationAction", 2)
				else:
					send_command_animation(index, 2)
				
			3:
				if useESP32:
					send_json_command("ChangeAnimationAction", 3)
				else:
					send_command_animation(index, 3)
				
			4:
				if useESP32:
					send_json_command("ChangeAnimationAction", 4)
				else:
					send_command_animation(index, 4)
				
			5:
				if useESP32:
					send_json_command("ChangeAnimationAction", 5)
				else:
					send_command_animation(index, 5)
				
			6:
				if useESP32:
					send_json_command("ChangeAnimationAction", 6)
				else:
					send_command_animation(index, 6)
				
			7:
				if useESP32:
					send_json_command("ChangeAnimationAction", 7)
				else:
					send_command_animation(index, 7)
				
			8:
				if useESP32:
					send_json_command("ChangeAnimationAction", 8)
				else:
					send_command_animation(index, 8)

			9:
				if useESP32:
					send_json_command("ChangeAnimationAction", 9)
				else:
					send_command_animation(index, 9)

func set_defaults(splash_length: int, brightness: int, fade_rate: int):
	splash_length_slider.value = splash_length
	brightness_slider.value = brightness
	fade_rate_slider.value = fade_rate

	send_command_splash_max_length(splash_length)
	send_command_set_brightness(brightness)
	send_command_fade_rate(fade_rate)
	
func _on_brightness_slider_value_changed(value):
	if useESP32:
		send_json_command("Brightness", value)
	else:
		send_command_set_brightness(int(value))

func _on_fade_slider_value_changed(value: float) -> void:
	if useESP32:
		send_json_command("Fade", value)
	else:
		send_command_fade_rate(int(value))

func _on_splash_length_slider_value_changed(value):
	if useESP32:
		send_json_command("Splash", value)
	else:
		send_command_splash_max_length(int(value))

func rgb_to_hsb(r: float, g: float, b: float) -> Dictionary:
	var max_val = max(r, g, b)
	var min_val = min(r, g, b)
	var delta = max_val - min_val

	var hue = 0.0
	var saturation = 0.0
	var brightness = max_val

	if delta > 0.0:
		saturation = delta / max_val

		if max_val == r:
			hue = (g - b) / delta
		elif max_val == g:
			hue = 2.0 + (b - r) / delta
		else:
			hue = 4.0 + (r - g) / delta

		hue *= 60.0
		if hue < 0.0:
			hue += 360.0

	return {
		"hue": hue / 360.0 * 255,
		"saturation": saturation * 255,
		"brightness": brightness * 255
	}

func update_bg_color(value: float) -> void:
	
	var red = currentColor.r
	var green = currentColor.g
	var blue = currentColor.b

	var hsb = rgb_to_hsb(red, green, blue)

	var hue = int(hsb["hue"])
	var saturation = int(hsb["saturation"])
	var brightness = int(value)
	
	if bgLED_Toggle:
		send_command_set_bg(hue, saturation, brightness)
		
func _on_bg_brightness_slider_value_changed(value):
	if useESP32:
		send_json_command("Background", value)
	else:
		update_bg_color(value)

func _on_bgled_toggle_toggled(toggled_on):
	if toggled_on:
		bgLED_Toggle = true

		if useESP32:
			send_json_command("BGAction", 1)
		else:

			send_command_set_bg(0,0,50)
	else:
		bgLED_Toggle = false

		if useESP32:
			send_json_command("BGAction", 0)
		else:
			send_command_set_bg(0,0,0)

func update_piano_size_label():
	piano_size_label.text = piano_size_labels.get(counter, "Unknown Size")

func update_piano_size_settings():
	match counter:
		0:
			stripLedNum = 176
			firstNoteSelected = 21
			lastNoteSelected = 108
		1:
			stripLedNum = 152
			firstNoteSelected = 28
			lastNoteSelected = 103
		2:
			stripLedNum = 146
			firstNoteSelected = 28
			lastNoteSelected = 100
		3:
			stripLedNum = 122
			firstNoteSelected = 36
			lastNoteSelected = 96
		4:
			stripLedNum = 98
			firstNoteSelected = 36
			lastNoteSelected = 84

func _on_dec_p_size_button_pressed() -> void:
	if counter > 0:
		counter -= 1

		update_piano_size_settings()
		update_piano_size_label()

func _on_inc_p_size_button_pressed() -> void:
	if counter < 4:
		counter += 1

		update_piano_size_settings()
		update_piano_size_label()

func _on_fix_led_toggle_toggled(toggled_on):
	if toggled_on:
		fixLED_Toggle = true
	else:
		fixLED_Toggle = false

func _on_revled_toggle_toggled(toggled_on):
	if toggled_on:
		if useESP32:
			send_json_command("DirectionAction", 1)
		else:
			send_command_strip_direction(1, stripLedNum)
	else:
		if useESP32:
			send_json_command("DirectionAction", 0)
		else:
			send_command_strip_direction(0, stripLedNum)

func _on_update_bg_button_pressed() -> void:
	if useESP32:
		if bgLED_Toggle:
			send_json_command("BGAction", 1)
	else:
		update_bg_color(bg_brightness_slider.value)

func _on_transposition_slider_value_changed(value):
	if octaveShift_Toggle:
		transposition = -value * 12
	else:
		transposition = -value

func _on_t_octave_button_toggled(toggled_on: bool) -> void:
	print('tasetase')
	if toggled_on:
		octaveShift_Toggle = true
	else:
		octaveShift_Toggle = false

func _request_esp32_ip():
	var request_buffer = PackedByteArray()
	var request_data = "ScanRequest".to_ascii_buffer()
	request_buffer.append_array(request_data)
	udp_peer.put_packet(request_buffer)
	print("Sending: ", request_buffer)
	print("Broadcast request sent.")

func _on_data_received():
	var packet = udp_peer.get_packet()
	var ip_address = _parse_ip_from_packet(packet)
	if ip_address != "":
		print("Received IP address: ", ip_address)
		udp_peer.set_dest_address(ip_address, udp_port)

func _parse_ip_from_packet(packet: PackedByteArray):
	if packet.size() == 4:
		var octets = [packet[0], packet[1], packet[2], packet[3]]
		var ip_str = str(octets[0]) + "." + str(octets[1]) + "." + str(octets[2]) + "." + str(octets[3])
		return ip_str
	else:
		print("Invalid packet size: ", packet.size())
		return ""

func send_midi_note_on(note: int, velocity: int):

	if MODE != 4:
		var message: PackedByteArray = PackedByteArray()
		message.append(note-1)
		message.append(velocity)
		
		udp_peer.put_packet(message)
		#print("MIDI message sent:", message)

func send_midi_note_off(note: int):
	if MODE != 4:
		var message: PackedByteArray = PackedByteArray()
		message.append(note-1)
		udp_peer.put_packet(message)
		#print("MIDI message sent:", message)
		
func _on_color_picker_color_changed(color: Color) -> void:
	var dark_color = Color(color.r * 0.8, color.g * 0.8, color.b * 0.8, color.a)

	stop_all_notes_and_particles()

	midi_keyboard.white_note_mesh_color = color
	midi_keyboard.black_note_mesh_color = dark_color

	midi_keyboard.white_notes_on_mat.emission = color
	midi_keyboard.black_notes_on_mat.emission = dark_color
	
	midi_keyboard.white_notes_on_mat.albedo_color = color
	midi_keyboard.black_notes_on_mat.albedo_color = dark_color

	for key_name in midi_keyboard.light_nodes.keys():
		var light_holder = midi_keyboard.light_nodes[key_name]
		var is_black = midi_keyboard.is_black_key(int(key_name))

		var light: OmniLight3D = light_holder.get_child(0)
		if light:
			light.light_color = midi_keyboard.black_note_mesh_color if is_black else midi_keyboard.white_note_mesh_color

	for note_array_w in midi_white_notes.active_notes.values():
		for note_data in note_array_w:
			var shader_material = note_data.shader_material
			if shader_material:
				shader_material.set_shader_parameter("white_key_color", midi_keyboard.white_note_mesh_color)
				shader_material.set_shader_parameter("black_key_color", midi_keyboard.black_note_mesh_color)
	for note_array_b in midi_black_notes.active_notes.values():
		for note_data in note_array_b:
			var shader_material = note_data.shader_material
			if shader_material:
				shader_material.set_shader_parameter("white_key_color", midi_keyboard.white_note_mesh_color)
				shader_material.set_shader_parameter("black_key_color", midi_keyboard.black_note_mesh_color)

	currentColor = color
	send_command_update_color(color)

func stop_all_notes_and_particles() -> void:
	var all_active_note_pitches = []
	all_active_note_pitches.append_array(midi_white_notes.active_notes.keys())
	all_active_note_pitches.append_array(midi_black_notes.active_notes.keys())
	
	var unique_pitches = {}
	
	for p in midi_white_note_particles.active_particles.keys(): 
		unique_pitches[p] = true

	for p in midi_black_note_particles.active_particles.keys(): 
		unique_pitches[p] = true

	for p in all_active_note_pitches: 
		unique_pitches[p] = true

	for pitch_val in unique_pitches.keys():
		midi_white_note_particles.stop_particle(pitch_val)
		midi_black_note_particles.stop_particle(pitch_val)
		
		if midi_keyboard.is_black_key(pitch_val):
			midi_black_notes.on_note_off(pitch_val)
		else:
			midi_white_notes.on_note_off(pitch_val)
			midi_keyboard.update_key_material(pitch_val, false)
		
func _on_save_profile_button_pressed() -> void:
	save_profile_file_dialog.visible = true

func _on_save_profile_file_dialog_file_selected(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		
		var position_z = midi.position.z
		var scale = midi.scale

		var offsets = {}
		for pitch in Global.offset_map.keys():
			offsets[str(pitch)] = Global.offset_map[pitch]

		var data = {
			"position": {"z": position_z},
			"scale": {"x": scale.x, "y": scale.y, "z": scale.z},
			"offsets": offsets
		}

		var json_data = JSON.stringify(data)

		file.store_string(json_data)
		file.close()

		print("Profile saved successfully to:", path)
	else:
		print("Error opening file for writing.")

func _on_load_profile_button_pressed() -> void:
	load_profile_file_dialog.visible = true

func _on_load_profile_file_dialog_file_selected(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var file_content = file.get_as_text().strip_edges()
		file.close()

		var json_parser = JSON.new()
		var error_code = json_parser.parse(file_content)
		
		if error_code == OK:
			var data = json_parser.get_data()

			var position_z = data["position"]["z"]
			var scale = Vector3(data["scale"]["x"], data["scale"]["y"], data["scale"]["z"])
			midi.scale = scale
			midi.position.z = position_z

			Global.offset_map.clear()
			for pitch in data["offsets"].keys():
				var offset = int(data["offsets"][pitch])
				Global.offset_map[int(pitch)] = offset

			print("Profile loaded successfully from:", path)
		else:
			print("Error parsing JSON from file. Error: ", json_parser.error_message())
	else:
		print("Error opening file for reading.")

func _on_note_rot_x_slider_value_changed(value: float) -> void:
	midi_bg.rotation_degrees.x = value
		
	midi_white_notes.rotation_degrees.x = value
	midi_black_notes.rotation_degrees.x = value
	midi_white_note_particles.rotation_degrees.x = value
	midi_black_note_particles.rotation_degrees.x = value
	
func _on_world_color_picker_color_changed(color: Color) -> void:
	world_environment.environment.background_color = color

func _on_midi_speed_slider_value_changed(value: float) -> void:
	midi_white_notes.speed = value
	midi_black_notes.speed = value

func _on_load_fspy_pressed() -> void:
	Global.player.handle_fspy()
