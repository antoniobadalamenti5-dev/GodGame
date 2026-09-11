extends Node2D

@export var max_amount := 100.0
@export var current_amount := 40.0
@export var regeneration_per_day := 10.0


func _ready() -> void:
	queue_redraw()


func take_water(requested_amount: float) -> float:
	var taken_amount: float = minf(requested_amount, current_amount)
	current_amount -= taken_amount
	queue_redraw()
	return taken_amount


func advance_day() -> void:
	current_amount = minf(current_amount + regeneration_per_day, max_amount)
	queue_redraw()
	print("Acqua disponibile: ", current_amount)


func _draw() -> void:
	var fullness := current_amount / max_amount
	var radius := 24.0 + 48.0 * fullness
	draw_circle(Vector2.ZERO, radius, Color("#3d8fd1"))
