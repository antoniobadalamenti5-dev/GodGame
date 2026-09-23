class_name ConstructionSite
extends Node2D

signal construction_completed

@export var required_wood := 60.0

var delivered_wood := 0.0
var is_active := false
var is_completed := false


func _ready() -> void:
	visible = false
	queue_redraw()


func activate() -> void:
	if is_active or is_completed:
		return

	is_active = true
	visible = true
	queue_redraw()


func deliver_wood(requested_amount: float) -> float:
	if not is_active or is_completed:
		return 0.0

	var remaining_wood: float = required_wood - delivered_wood
	var accepted_amount: float = minf(requested_amount, remaining_wood)

	delivered_wood += accepted_amount
	print("Legno nel cantiere: ", delivered_wood, " / ", required_wood)
	queue_redraw()

	if delivered_wood >= required_wood:
		is_completed = true
		construction_completed.emit()

	return accepted_amount


func _draw() -> void:
	var progress: float = delivered_wood / required_wood

	# Base sterrata/ombra
	draw_rect(Rect2(-42, -27, 84, 54), Color(0, 0, 0, 0.2))
	draw_rect(Rect2(-40, -25, 80, 50), Color("#7b6545"))
	draw_rect(Rect2(-40, -25, 80, 50), Color("#5a4830"), false, 2.0)
	
	# Assi di legno incrociate (struttura base)
	draw_line(Vector2(-35, -20), Vector2(35, 20), Color("#c28b52"), 3.0)
	draw_line(Vector2(35, -20), Vector2(-35, 20), Color("#c28b52"), 3.0)
	draw_line(Vector2(-35, -20), Vector2(35, 20), Color("#5a4830"), 1.0)
	draw_line(Vector2(35, -20), Vector2(-35, 20), Color("#5a4830"), 1.0)

	# Barra di progresso integrata
	draw_rect(Rect2(-45, 30, 90, 10), Color("#263238"))
	draw_rect(Rect2(-45, 30, 90, 10), Color("#101518"), false, 2.0)
	
	draw_rect(Rect2(-45, 30, 90 * progress, 10), Color("#81b85a"))
	draw_rect(Rect2(-45, 30, 90 * progress, 10), Color("#43a047"), false, 1.0)
