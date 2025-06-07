extends CanvasLayer

const OFFSET := 5.0

@onready var fps = $"../SubViewportContainer/SubViewport/FPS"

@onready var x_lines = [
	$XLineA,
	$XLineB
]

@onready var y_lines = [
	$YLineA,
	$YLineB
]

@onready var drag_points := get_children().filter(
	func(n): return n.name.begins_with("DragPoint")
)

func _ready() -> void:
	for point in drag_points:
		point.connect("position_changed", _on_point_moved)
	update_lines()
	
func _on_point_moved() -> void:
	update_lines()

func handle_overlay():
	print('test')

func offset_line(p1: Vector2, p2: Vector2, line_offset: float) -> Array:
	var direction = (p2 - p1).normalized()
	return [
		p1 + direction * line_offset,
		p2 - direction * line_offset
	]

func update_lines() -> void:
	x_lines[0].points = offset_line($DragPoint1.position, $DragPoint2.position, OFFSET)
	x_lines[1].points = offset_line($DragPoint3.position, $DragPoint4.position, OFFSET)
	y_lines[0].points = offset_line($DragPoint5.position, $DragPoint6.position, OFFSET)
	y_lines[1].points = offset_line($DragPoint7.position, $DragPoint8.position, OFFSET)
