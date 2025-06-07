extends Control

@onready var webcam_list = $SubViewportContainer/SubViewport/MIDI/CanvasLayer/Menu/Panel_Container/Margin_Sub/ScrollContainer/VBoxContainer/MarginContainer_WebcamControls/VBox_IO/VBox_Content/HBox_Webcam_Container/WebcamList
@onready var start_stop_button = $SubViewportContainer/SubViewport/MIDI/CanvasLayer/Menu/Panel_Container/Margin_Sub/ScrollContainer/VBoxContainer/MarginContainer_WebcamControls/VBox_IO/VBox_Content/HBox_Webcam_Container/StartStop
@onready var texture_rect = $TextureRect
@onready var sub_view_port_bg_transparency_toggle = $SubViewportContainer/SubViewport/MIDI/CanvasLayer/Menu/Panel_Container/Margin_Sub/ScrollContainer/VBoxContainer/MarginContainer_WebcamControls/VBox_IO/VBox_Content/HBox_Webcam_Controls_Container/SubViewPortBG_Transparency_Toggle

var feeds: Array[CameraFeed]
var feed: CameraFeed
var camera_texture: CameraTexture
var black_texture: ImageTexture

var webcam_options: Array[Dictionary] = []

func _ready():
	CameraServer.set_monitoring_feeds(true)

	var black_image = Image.create(1, 1, false, Image.FORMAT_RGBA8)
	black_image.set_pixel(0, 0, Color.BLACK)
	black_texture = ImageTexture.create_from_image(black_image)
	texture_rect.texture = black_texture

	feeds = CameraServer.feeds()
	webcam_list.clear()
	webcam_options.clear()

	if feeds.is_empty():
		webcam_list.add_item("No cameras detected")
		webcam_list.set_item_disabled(0, true)
		start_stop_button.disabled = true
		return

	for feed_index in feeds.size():
		var camera_feed = feeds[feed_index]
		var formats = camera_feed.get_formats()

		if formats.is_empty():
			continue

		for format_index in formats.size():
			var format = formats[format_index]
			if not format.has("format") or format["format"] != "RGB24":
				continue  # Skip non-RGB24 formats

			var cam_name = camera_feed.get_name()
			var width = format["width"]
			var height = format["height"]
			var fps = int(round(float(format["frame_numerator"]) / format["frame_denominator"]))
			var item_label = "%s - %dx%d@%dHz" % [cam_name, width, height, fps]

			webcam_list.add_item(item_label)
			webcam_options.append({
				"feed_index": feed_index,
				"format_index": format_index
			})


	# Auto-select first item
	if not webcam_options.is_empty():
		webcam_list.select(0)
		_on_webcam_list_item_selected(0)

	start_stop_button.text = "Start"
	sub_view_port_bg_transparency_toggle.button_pressed = false

func _on_webcam_list_item_selected(index):
	if webcam_options.is_empty() or index >= webcam_options.size():
		return

	var option = webcam_options[index]
	var feed_index = option["feed_index"]
	var format_index = option["format_index"]

	feed = feeds[feed_index]
	var formats = feed.get_formats()

	if format_index >= formats.size():
		push_error("Invalid format index.")
		return

	var format = formats[format_index]
	var success = feed.set_format(format_index, format)
	print("Set format success: ", success, " -> ", format)

	if not success:
		push_error("Failed to set camera format.")
		return

	var fps = float(format["frame_numerator"]) / format["frame_denominator"]
	print("Using format with FPS: ", fps)

	feed.set_active(false)
	start_stop_button.text = "Start"
	sub_view_port_bg_transparency_toggle.button_pressed = false
	texture_rect.texture = black_texture

func _on_start_stop_toggled(toggled_on):
	if not feed:
		return

	feed.set_active(toggled_on)
	start_stop_button.text = "Stop" if toggled_on else "Start"
	sub_view_port_bg_transparency_toggle.button_pressed = toggled_on

	if toggled_on:
		camera_texture = CameraTexture.new()
		camera_texture.set_camera_feed_id(feed.get_id())
		texture_rect.texture = camera_texture
	else:
		texture_rect.texture = black_texture

func _on_sub_view_port_flip_x_toggle_toggled(toggled_on):
	texture_rect.flip_h = toggled_on

func _on_sub_view_port_flip_y_toggle_toggled(toggled_on):
	texture_rect.flip_v = toggled_on
