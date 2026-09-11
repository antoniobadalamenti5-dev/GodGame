class_name Temple
extends Node2D


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-45, -35, 90, 70), Color("#b99b67"))
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-55, -35),
			Vector2(0, -75),
			Vector2(55, -35),
		]),
		Color("#775e44")
	)
	draw_rect(Rect2(-8, 0, 16, 35), Color("#4b3024"))
