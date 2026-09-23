class_name GameWorld
extends Node2D

@export var map_size := Vector2(4096, 2560)
@onready var resources: Node2D = get_node_or_null("Resources")

const CELL_SIZE := 128.0

@export_group("Generazione Risorse")
@export var tree_count := 40
@export var berry_count := 16
@export var city_safe_radius := 420.0

var atmosphere_tint := Color(0, 0, 0, 0)


func _ready() -> void:
	if resources == null:
		resources = Node2D.new()
		resources.name = "Resources"
		add_child(resources)
	generate_world_resources()
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, map_size), Color("#577a4b"))

	for x in range(0, int(map_size.x) + 1, int(CELL_SIZE)):
		draw_line(Vector2(x, 0), Vector2(x, map_size.y), Color("#45643c"), 2.0)

	for y in range(0, int(map_size.y) + 1, int(CELL_SIZE)):
		draw_line(Vector2(0, y), Vector2(map_size.x, y), Color("#45643c"), 2.0)

	# Tinta atmosferica per eventi climatici (Siccità, Abbondanza, Tempesta)
	if atmosphere_tint.a > 0.01:
		draw_rect(Rect2(Vector2.ZERO, map_size), atmosphere_tint)


func advance_day(_day_number: int) -> void:
	if resources != null:
		for resource in resources.get_children():
			if resource.has_method("advance_day"):
				resource.advance_day()


# --- MIRACOLI DIVINI ---
func apply_rain_miracle() -> void:
	if resources != null:
		for child in resources.get_children():
			if child is WaterSource:
				child.current_amount = minf(child.current_amount + 80.0, child.max_amount)
				child.queue_redraw()
			elif child is BerryBush:
				child.current_amount = minf(child.current_amount + 60.0, child.max_amount)
				child.queue_redraw()
	print("🌧️ MIRACOLO DELLA PIOGGIA: Laghi e bacche ricaricati dal cielo!")


func apply_tree_growth_miracle() -> void:
	if resources != null:
		for child in resources.get_children():
			if child is Tree_class:
				child.current_wood = minf(child.current_wood + 40.0, child.max_wood)
				child.queue_redraw()
	print("🌲 MIRACOLO SILVANO: Gli alberi della foresta sono rifioriti!")


func set_atmosphere(color: Color) -> void:
	atmosphere_tint = color
	queue_redraw()


func get_nearest_water(from_position: Vector2) -> WaterSource:
	var nearest: WaterSource = null
	var min_dist_sq := INF
	if resources != null:
		for child in resources.get_children():
			if child is WaterSource and child.current_amount > 0.0:
				var dist_sq := from_position.distance_squared_to(child.global_position)
				if dist_sq < min_dist_sq:
					min_dist_sq = dist_sq
					nearest = child
	return nearest


func get_nearest_food(from_position: Vector2) -> BerryBush:
	var nearest: BerryBush = null
	var min_dist_sq := INF
	if resources != null:
		for child in resources.get_children():
			if child is BerryBush and child.current_amount > 0.0:
				var dist_sq := from_position.distance_squared_to(child.global_position)
				if dist_sq < min_dist_sq:
					min_dist_sq = dist_sq
					nearest = child
	return nearest


func get_nearest_tree(from_position: Vector2) -> Tree_class:
	var nearest: Tree_class = null
	var min_dist_sq := INF
	if resources != null:
		for child in resources.get_children():
			if child is Tree_class and child.current_wood > 0.0:
				var dist_sq := from_position.distance_squared_to(child.global_position)
				if dist_sq < min_dist_sq:
					min_dist_sq = dist_sq
					nearest = child
	return nearest


func generate_world_resources() -> void:
	if resources == null:
		return
	for child in resources.get_children():
		resources.remove_child(child)
		child.queue_free()

	_create_water_source(Vector2(1100, 750), 180.0)
	_create_water_source(Vector2(3000, 850), 140.0)
	_create_water_source(Vector2(2100, 2050), 160.0)

	var forest_centers := [
		Vector2(1000, 1600),
		Vector2(3200, 1650),
		Vector2(1650, 550)
	]

	var trees_per_cluster: int = int(float(tree_count) / float(forest_centers.size()))
	for center in forest_centers:
		for i in range(trees_per_cluster):
			var offset := Vector2(randf_range(-260, 260), randf_range(-200, 200))
			var tree_pos: Vector2 = (center + offset).clamp(Vector2(100, 100), map_size - Vector2(100, 100))
			_create_tree(tree_pos)

	for i in range(berry_count):
		var bush_pos := Vector2(
			randf_range(200, map_size.x - 200),
			randf_range(200, map_size.y - 200)
		)
		_create_berry_bush(bush_pos)


func _create_water_source(pos: Vector2, capacity: float) -> void:
	var water := WaterSource.new()
	water.position = pos
	water.max_amount = capacity
	water.current_amount = capacity
	resources.add_child(water)


func _create_tree(pos: Vector2) -> void:
	var tree := Tree_class.new()
	tree.position = pos
	resources.add_child(tree)


func _create_berry_bush(pos: Vector2) -> void:
	var bush := BerryBush.new()
	bush.position = pos
	resources.add_child(bush)
