extends MeshInstance3D

@export var bg_material : Material

@onready var change_bg_image_button = $"../CanvasLayer/ChangeBGImage_Button"
@onready var file_dialog = $"../CanvasLayer/BGImage_FileDialog"

@onready var bg_transparency_slider = $"../CanvasLayer/BGTransparency_Slider"

@onready var toggle_bg = $"../CanvasLayer/ToggleBG"

func _on_change_bg_image_button_pressed():
	file_dialog.popup()

func _on_file_dialog_file_selected(path):
	var image = Image.new()
	
	image.load(path)
	
	var image_texture = ImageTexture.new()
	
	image_texture.set_image(image)
	
	bg_material.albedo_color.a = 1
	bg_material.albedo_texture = image_texture
	
	bg_transparency_slider.value = 1
	toggle_bg.button_pressed = true

func _on_clear_bg_image_button_pressed():
	bg_material.albedo_texture = null
	toggle_bg.button_pressed = false

func _on_bg_transparency_slider_value_changed(value):
	bg_material.albedo_color.a = value
