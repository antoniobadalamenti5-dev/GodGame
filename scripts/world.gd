extends Node2D

@export var map_size := Vector2(4096, 2560)
@onready var resources: Node2D = $Resources

const CELL_SIZE := 128.0


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, map_size), Color("#577a4b"))

	for x in range(0, int(map_size.x) + 1, int(CELL_SIZE)):
		draw_line(Vector2(x, 0), Vector2(x, map_size.y), Color("#45643c"), 2.0)

	for y in range(0, int(map_size.y) + 1, int(CELL_SIZE)):
		draw_line(Vector2(0, y), Vector2(map_size.x, y), Color("#45643c"), 2.0)

	draw_circle(map_size / 2.0, 24.0, Color("#d4b16a"))

func advance_day(_day_number: int) -> void:
	for resource in resources.get_children():
		if resource.has_method("advance_day"):
			resource.advance_day()
