class_name Tree_class
extends Node2D

@export var max_wood := 80.0
@export var current_wood := 80.0
@export var regeneration_per_day := 2.0


func _ready() -> void:
	queue_redraw()


func take_wood(requested_amount: float) -> float:
	var taken_amount: float = minf(requested_amount, current_wood)
	current_wood -= taken_amount
	queue_redraw()
	return taken_amount


func advance_day() -> void:
	current_wood = minf(current_wood + regeneration_per_day, max_wood)
	queue_redraw()


func _draw() -> void:
	var fullness: float = current_wood / max_wood
	var canopy_radius: float = 24.0 + 24.0 * fullness

	draw_rect(Rect2(-8, 0, 16, 35), Color("#704831"))
	draw_circle(Vector2(0, -15), canopy_radius, Color("#3e7d45"))
