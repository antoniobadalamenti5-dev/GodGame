class_name Warehouse
extends Node2D

@export var capacity_bonus := 100.0

func _ready() -> void:
	z_index = 1
	queue_redraw()

func _draw() -> void:
	# Isometric 3D rendering for Warehouse
	var w := 30.0
	var h := 35.0
	var d := 15.0 # y-scale per tile
	
	var base_y := 10.0
	
	# Colori
	var color_top := Color("#8d6e63")
	var color_left := Color("#5d4037")
	var color_right := Color("#3e2723")
	
	# Ombra alla base
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, base_y - d), Vector2(w + 5, base_y), 
		Vector2(0, base_y + d + 5), Vector2(-w - 5, base_y)
	]), Color(0, 0, 0, 0.3))
	
	# Faccia Sinistra
	draw_colored_polygon(PackedVector2Array([
		Vector2(-w, base_y), Vector2(0, base_y + d),
		Vector2(0, base_y + d - h), Vector2(-w, base_y - h)
	]), color_left)
	
	# Faccia Destra
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, base_y + d), Vector2(w, base_y),
		Vector2(w, base_y - h), Vector2(0, base_y + d - h)
	]), color_right)
	
	# Tetto (Faccia Superiore)
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, base_y - h - d), Vector2(w, base_y - h),
		Vector2(0, base_y + d - h), Vector2(-w, base_y - h)
	]), color_top)
	
	# Contorni per definire la forma 3D
	var outline_color = Color("#2b1d14")
	draw_line(Vector2(-w, base_y), Vector2(0, base_y + d), outline_color, 2.0)
	draw_line(Vector2(0, base_y + d), Vector2(w, base_y), outline_color, 2.0)
	draw_line(Vector2(-w, base_y), Vector2(-w, base_y - h), outline_color, 2.0)
	draw_line(Vector2(0, base_y + d), Vector2(0, base_y + d - h), outline_color, 2.0)
	draw_line(Vector2(w, base_y), Vector2(w, base_y - h), outline_color, 2.0)
	draw_line(Vector2(-w, base_y - h), Vector2(0, base_y + d - h), outline_color, 2.0)
	draw_line(Vector2(0, base_y + d - h), Vector2(w, base_y - h), outline_color, 2.0)
	draw_line(Vector2(w, base_y - h), Vector2(0, base_y - h - d), outline_color, 2.0)
	draw_line(Vector2(0, base_y - h - d), Vector2(-w, base_y - h), outline_color, 2.0)
	
	# Porta / Ingresso sulla faccia sinistra
	draw_colored_polygon(PackedVector2Array([
		Vector2(-20, base_y - 8), Vector2(-5, base_y + d - 10),
		Vector2(-5, base_y + d - 25), Vector2(-20, base_y - 23)
	]), Color("#212121"))
