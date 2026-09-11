class_name BerryBush
extends Node2D

@export var max_amount := 60.0
@export var current_amount := 25.0
@export var regeneration_per_day := 5.0


func _ready() -> void:
	queue_redraw()


func take_food(requested_amount: float) -> float:
	var taken_amount: float = minf(requested_amount, current_amount)
	current_amount -= taken_amount
	queue_redraw()
	return taken_amount


func advance_day() -> void:
	current_amount = minf(current_amount + regeneration_per_day, max_amount)
	queue_redraw()
	print("Bacche disponibili: ", current_amount)


func _draw() -> void:
	var fullness: float = current_amount / max_amount
	var radius: float = 18.0 + 30.0 * fullness
	draw_circle(Vector2.ZERO, radius, Color("#6cab4b"))
	draw_circle(Vector2(8, -6), 5.0, Color("#b24d62"))
	draw_circle(Vector2(-7, 5), 5.0, Color("#b24d62"))
