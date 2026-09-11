class_name House
extends Node2D

@export var capacity: int = 2


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-35, -25, 70, 50), Color("#9a724c"))
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-45, -25),
			Vector2(0, -55),
			Vector2(45, -25),
		]),
		Color("#704431")
	)
	draw_rect(Rect2(-8, 2, 16, 23), Color("#4b3024"))
