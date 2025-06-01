extends VBoxContainer

@export var header_title: String = "Tab"
@export var is_open: bool = true

@onready var header_button: Button = $HeaderButton
@onready var v_box_content: VBoxContainer = $VBox_Content


func _ready():
	if not header_button or not v_box_content:
		push_error("CollapsibleTab is missing 'HeaderButton' or 'ContentPanel' child node!")
		return

	header_button.text = "▼ " + header_title
	header_button.pressed.connect(_on_header_pressed)

func _on_header_pressed():
	is_open = !is_open
	v_box_content.visible = is_open
	header_button.text = ("▼ " if is_open else "▶ ") + header_title
