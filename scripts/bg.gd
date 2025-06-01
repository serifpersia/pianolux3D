extends Node3D

@export var bg_material : Material

@onready var change_bg_image_button: Button = $"../CanvasLayer/Menu/Panel_Container/Margin_Sub/ScrollContainer/VBoxContainer/MarginContainer_IO/VBox_IO/VBox_Content/HBox_B_C_B_Container/Change_BG_Image_Button"
@onready var bg_image_file_dialog: FileDialog = $"../CanvasLayer/BGImage_FileDialog"
@onready var bg_transparency_slider: HSlider = $"../CanvasLayer/Menu/Panel_Container/Margin_Sub/ScrollContainer/VBoxContainer/MarginContainer_Visiblity/VBox_Visiblity/VBox_Content/HBox_BG_T_Container/BG_Transparency_Slider"
@onready var toggle_bg: CheckButton = $"../CanvasLayer/Menu/Panel_Container/Margin_Sub/ScrollContainer/VBoxContainer/MarginContainer_Visiblity/VBox_Visiblity/VBox_Content/HBox_K_B_Container/BG_Toggle"

func _ready() -> void:
	get_child(0).material_override = bg_material
	
func _on_change_bg_image_button_pressed():
	bg_image_file_dialog.popup()

func _on_bg_image_file_dialog_file_selected(path: String) -> void:
	var image = Image.new()
	
	image.load(path)
	
	var image_texture = ImageTexture.new()
	
	image_texture.set_image(image)
	
	bg_material.albedo_color.a = 1
	bg_material.albedo_color = Color(1,1,1)
	bg_material.albedo_texture = image_texture
	
	bg_transparency_slider.value = 1
	toggle_bg.button_pressed = true

func _on_clear_bg_image_button_pressed():
	bg_material.albedo_texture = null
	bg_material.albedo_color = Color(0.1, 0.1, 0.1)
	toggle_bg.button_pressed = false

func _on_bg_transparency_slider_value_changed(value):
	bg_material.albedo_color.a = value
