class_name BerryBush
extends Node2D

@export var max_amount := 150.0
var current_amount := 150.0


func _ready() -> void:
	queue_redraw()


func advance_day() -> void:
	current_amount = minf(current_amount + 15.0, max_amount)
	queue_redraw()


func take_food(amount: float) -> float:
	var taken = minf(current_amount, amount)
	current_amount -= taken
	queue_redraw()
	return taken


func _draw() -> void:
	var fullness = current_amount / max_amount if max_amount > 0.0 else 1.0
	var r = 18.0 + (16.0 * fullness)
	draw_circle(Vector2.ZERO, r, Color("#6cab4b"))
	draw_circle(Vector2(6, -4), 4.0, Color("#b24d62"))
	draw_circle(Vector2(-6, 4), 4.0, Color("#b24d62"))
	draw_circle(Vector2(0, 6), 3.5, Color("#b24d62"))
