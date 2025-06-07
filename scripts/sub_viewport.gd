extends SubViewportContainer

@onready var sub_viewport = $SubViewport

func _on_sub_view_port_bg_transparency_toggle_toggled(toggled_on):
	sub_viewport.transparent_bg = toggled_on
