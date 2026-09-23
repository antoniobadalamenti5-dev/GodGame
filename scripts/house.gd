class_name House
extends Node2D

@export var capacity: int = 2


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	# Ombra
	draw_rect(Rect2(-32, -22, 70, 50), Color(0, 0, 0, 0.3))
	
	# Muro
	draw_rect(Rect2(-35, -25, 70, 50), Color("#9a724c"))
	draw_rect(Rect2(-35, -25, 70, 50), Color("#704431"), false, 2.0)
	
	# Tetto
	var roof_poly = PackedVector2Array([
		Vector2(-45, -25),
		Vector2(0, -55),
		Vector2(45, -25),
	])
	draw_colored_polygon(roof_poly, Color("#704431"))
	draw_polyline(roof_poly, Color("#4b3024"), 2.0)
	
	# Finestra
	draw_rect(Rect2(-20, -10, 10, 10), Color("#4b3024"))
	draw_rect(Rect2(-20, -10, 10, 10), Color("#2b1d14"), false, 1.0)
	draw_rect(Rect2(-20, -5, 10, 1), Color("#2b1d14"))
	draw_rect(Rect2(-15, -10, 1, 10), Color("#2b1d14"))
	
	# Porta
	draw_rect(Rect2(5, 2, 16, 23), Color("#4b3024"))
	draw_rect(Rect2(5, 2, 16, 23), Color("#2b1d14"), false, 2.0)
