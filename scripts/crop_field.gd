class_name CropField
extends Node2D

enum State { EMPTY, GROWING, READY }

@export var growth_time_days := 3
@export var food_yield := 50.0

var current_state: State = State.EMPTY
var growth_progress_days := 0

func _ready() -> void:
	z_index = 0
	queue_redraw()

func advance_day() -> void:
	if current_state == State.GROWING:
		growth_progress_days += 1
		if growth_progress_days >= growth_time_days:
			current_state = State.READY
		queue_redraw()

func plant_seeds() -> void:
	if current_state == State.EMPTY:
		current_state = State.GROWING
		growth_progress_days = 0
		queue_redraw()

func take_food(amount: float) -> float:
	if current_state == State.READY:
		# L'intero campo viene raccolto in un colpo (semplificazione o yield parziale)
		var gathered = minf(amount, food_yield)
		# Se si raccoglie tutto
		current_state = State.EMPTY
		growth_progress_days = 0
		queue_redraw()
		return gathered
	return 0.0

func _draw() -> void:
	# Isometric 3D rendering for CropField
	var w := 35.0
	var d := 18.0
	
	var base_y := 0.0
	
	var soil_top := Color("#4e342e")
	var soil_side_left := Color("#3e2723")
	var soil_side_right := Color("#2b1d14")
	
	var top_poly = PackedVector2Array([
		Vector2(0, base_y - d), Vector2(w, base_y), 
		Vector2(0, base_y + d), Vector2(-w, base_y)
	])
	
	# Base di terra spessa
	var depth = 6.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(-w, base_y), Vector2(0, base_y + d),
		Vector2(0, base_y + d + depth), Vector2(-w, base_y + depth)
	]), soil_side_left)
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, base_y + d), Vector2(w, base_y),
		Vector2(w, base_y + depth), Vector2(0, base_y + d + depth)
	]), soil_side_right)
	
	# Faccia Superiore (Terreno)
	draw_colored_polygon(top_poly, soil_top)
	
	# Contorno
	draw_polyline(top_poly, Color("#1f1009"), 2.0)
	
	# Linee di aratura isometriche
	for i in range(-20, 25, 10):
		var p1 = Vector2(i, base_y - d * (1.0 - abs(i)/w))
		var p2 = Vector2(i, base_y + d * (1.0 - abs(i)/w))
		# Approssimazione di linee isometriche per non complicare troppo
		draw_line(Vector2(i, base_y - d/1.5), Vector2(i, base_y + d/1.5), Color("#3e2723"), 1.5)
	
	if current_state == State.GROWING:
		var progress_ratio = float(growth_progress_days) / float(growth_time_days)
		var plant_color = Color("#81b85a").lerp(Color("#558b2f"), progress_ratio)
		var size = 2.0 + (3.0 * progress_ratio)
		
		# Distribuisci piantine sulla griglia isometrica
		for x in [-15, 0, 15]:
			for y in [-8, 0, 8]:
				var pos = Vector2(x, y + base_y)
				draw_circle(pos, size, plant_color)
				draw_circle(pos, size, plant_color.darkened(0.3), false, 1.0)
				
	elif current_state == State.READY:
		# Piante alte da raccolto
		for x in [-18, -9, 0, 9, 18]:
			for y in [-10, -5, 0, 5, 10]:
				var offset_y = abs(x) * 0.2
				var base = Vector2(x, y + base_y - offset_y)
				var tip = Vector2(x, y + base_y - 12 - offset_y)
				
				draw_line(base, tip, Color("#fbc02d"), 2.0)
				draw_circle(tip, 2.5, Color("#f57f17"))
				# Dettaglio 3D della spiga
				draw_circle(tip, 2.5, Color("#e65100"), false, 1.0)
