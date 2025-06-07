# DraggablePoint.gd
extends Control

@export var point_color: Color

signal position_changed

var dragging := false

func _ready() -> void:
	modulate = point_color
	
func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed
	elif event is InputEventMouseMotion and dragging:
		position += event.relative
		emit_signal("position_changed")
