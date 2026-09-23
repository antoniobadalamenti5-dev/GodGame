class_name Laboratory
extends Node2D

@export var max_workers := 2
var current_workers := 0
var level := 1

func _ready() -> void:
	z_index = 1
	queue_redraw()

func add_worker() -> bool:
	if current_workers < max_workers:
		current_workers += 1
		queue_redraw()
		return true
	return false

func remove_worker() -> void:
	if current_workers > 0:
		current_workers -= 1
		queue_redraw()

func do_research() -> float:
	# Genera punti ricerca proporzionali al livello
	return 2.5 * level

func _draw() -> void:
	# Isometric 3D rendering for Laboratory (Tower / Hut)
	var w := 20.0
	var h := 50.0
	var d := 10.0
	
	var base_y := 10.0
	
	var color_left := Color("#37474f")
	var color_right := Color("#263238")
	var color_top := Color("#546e7a")
	
	# Ombra
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, base_y - d), Vector2(w + 5, base_y), 
		Vector2(0, base_y + d + 5), Vector2(-w - 5, base_y)
	]), Color(0, 0, 0, 0.3))
	
	# Corpo principale (Torre in pietra scura)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-w, base_y), Vector2(0, base_y + d),
		Vector2(0, base_y + d - h), Vector2(-w, base_y - h)
	]), color_left)
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, base_y + d), Vector2(w, base_y),
		Vector2(w, base_y - h), Vector2(0, base_y + d - h)
	]), color_right)
	
	# Tetto spiovente magico
	var roof_h = 30.0
	var color_roof := Color("#673ab7")
	draw_colored_polygon(PackedVector2Array([
		Vector2(-w - 4, base_y - h + 4), Vector2(0, base_y + d - h + 4),
		Vector2(0, base_y - h - roof_h)
	]), color_roof)
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, base_y + d - h + 4), Vector2(w + 4, base_y - h + 4),
		Vector2(0, base_y - h - roof_h)
	]), color_roof.darkened(0.2))
	
	# Dettagli magici (Rune)
	var rune_color := Color("#00e5ff") if current_workers > 0 else Color("#00838f")
	draw_line(Vector2(-10, base_y - 20), Vector2(-5, base_y - 25), rune_color, 2.0)
	draw_line(Vector2(-5, base_y - 25), Vector2(-10, base_y - 30), rune_color, 2.0)
	draw_line(Vector2(-7, base_y - 25), Vector2(-1, base_y - 25), rune_color, 2.0)
	
	# Finestra circolare
	draw_circle(Vector2(0, base_y - h - 10), 4.0, rune_color)
	draw_circle(Vector2(0, base_y - h - 10), 4.0, Color("#111"), false, 1.5)
	
	# Porta
	draw_colored_polygon(PackedVector2Array([
		Vector2(-12, base_y - 3), Vector2(-4, base_y + d - 5),
		Vector2(-4, base_y + d - 20), Vector2(-12, base_y - 18)
	]), Color("#111"))
