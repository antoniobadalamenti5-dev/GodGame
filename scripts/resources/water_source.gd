class_name WaterSource
extends Node2D

@export var max_amount := 180.0
var current_amount := 180.0


func _ready() -> void:
	queue_redraw()


func advance_day() -> void:
	current_amount = minf(current_amount + 12.0, max_amount)
	queue_redraw()


func take_water(amount: float) -> float:
	var taken = minf(current_amount, amount)
	current_amount -= taken
	queue_redraw()
	return taken


func _draw() -> void:
	var fullness = current_amount / max_amount if max_amount > 0.0 else 1.0
	var r = 24.0 + (32.0 * fullness)
	draw_circle(Vector2.ZERO, r, Color("#3d8fd1"))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 32, Color("#2b6ea6"), 2.0)
