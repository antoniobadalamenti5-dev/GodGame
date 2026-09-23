class_name Tree_class
extends Node2D

@export var max_wood := 80.0
var current_wood := 80.0


func _ready() -> void:
	queue_redraw()


func advance_day() -> void:
	current_wood = minf(current_wood + 4.0, max_wood)
	queue_redraw()


func take_wood(amount: float) -> float:
	var taken = minf(current_wood, amount)
	current_wood -= taken
	queue_redraw()
	return taken


func _draw() -> void:
	var fullness = current_wood / max_wood if max_wood > 0.0 else 1.0
	draw_rect(Rect2(-7, 0, 14, 28), Color("#704831"))
	var r = 20.0 + (14.0 * fullness)
	draw_circle(Vector2(0, -10), r, Color("#38733e"))
	draw_arc(Vector2(0, -10), r, 0.0, TAU, 24, Color("#28582d"), 1.5)
