class_name City
extends Node2D

signal housing_shortage(homeless_citizens: int)

@export var construction_site_scene: PackedScene
@export var citizen_scene: PackedScene
@export var construction_origin := Vector2(180, 130)
@export var god_state: GodState
@export var mentality_change_per_day := 5.0

@export_group("Magazzino Risorse")
@export var stored_food := 50.0
@export var stored_wood := 20.0
@export var food_surplus_for_birth := 80.0
@export var food_cost_per_birth := 30.0

@onready var citizens: Node2D = $Citizens
@onready var houses: Node2D = $Houses
@onready var construction_sites: Node2D = $ConstructionSites
var expansion_mindset := 0.0
@onready var social_structures: Node2D = $SocialStructures
@onready var temple: Temple = $Temple
@onready var world: GameWorld = get_parent() as GameWorld

@export var base_influence_radius := 350.0
var current_influence_radius := 350.0


func _ready() -> void:
	current_influence_radius = base_influence_radius
	evaluate_housing()
	queue_redraw()


func advance_day(day_number: int) -> void:
	update_mentality()
	update_influence_area()

	# Avanziamo il giorno per tutti i cittadini della città
	for child in citizens.get_children():
		if child is Citizen:
			child.advance_day(day_number)

	evaluate_housing()
	check_population_growth()
	queue_redraw()


func evaluate_housing() -> void:
	var total_capacity: int = get_total_housing_capacity()
	var population: int = citizens.get_child_count()
	var remaining_capacity: int = total_capacity
	var homeless_citizens: int = 0

	for child in citizens.get_children():
		if child is Citizen:
			var has_home: bool = remaining_capacity > 0
			child.set_housed(has_home)

			if has_home:
				remaining_capacity -= 1
			else:
				homeless_citizens += 1

	# Avvia una nuova casa se ci sono senzatetto OPPURE se la popolazione ha saturato la capacità
	if (homeless_citizens > 0 or population >= total_capacity) and get_active_construction_site() == null:
		housing_shortage.emit(homeless_citizens)
		print("Capacità abitativa al limite (", population, "/", total_capacity, ", senza casa: ", homeless_citizens, "). Avvio cantiere nuova casa.")
		start_housing_project()



func get_total_housing_capacity() -> int:
	var total_capacity: int = 0

	for child in houses.get_children():
		if child is House:
			total_capacity += child.capacity

	return total_capacity


func get_active_construction_site() -> ConstructionSite:
	for child in construction_sites.get_children():
		if child is ConstructionSite:
			if child.is_active and not child.is_completed:
				return child

	return null


func start_housing_project() -> void:
	if get_active_construction_site() != null:
		return

	if construction_site_scene == null:
		push_error("Assegna Construction Site Scene al nodo City.")
		return

	var site: ConstructionSite = construction_site_scene.instantiate()
	site.position = get_next_house_site_position()

	construction_sites.add_child(site)
	site.construction_completed.connect(_on_construction_completed.bind(site))
	site.activate()

	print("La città avvia un cantiere per una nuova casa.")


func get_next_house_site_position() -> Vector2:
	var house_count: int = houses.get_child_count()
	return construction_origin + Vector2(120.0 * house_count, 0.0)


func _on_construction_completed(site: ConstructionSite) -> void:
	var new_house: House = House.new()
	new_house.position = site.position

	houses.add_child(new_house)
	site.queue_free()

	print("Una nuova casa è stata completata.")
	evaluate_housing()

func get_meeting_place() -> MeetingPlace:
	for child in social_structures.get_children():
		if child is MeetingPlace:
			return child

	return null


func update_mentality() -> void:
	if temple == null or god_state == null:
		return

	expansion_mindset = move_toward(
		expansion_mindset,
		god_state.expansion_directive,
		mentality_change_per_day
	)

	print("Mentalità espansionista: ", expansion_mindset)


func get_world() -> GameWorld:
	if world == null:
		world = get_parent() as GameWorld
	return world



func get_nearest_water(from_position: Vector2) -> WaterSource:
	var w := get_world()
	return w.get_nearest_water(from_position) if w != null else null


func get_nearest_food(from_position: Vector2) -> BerryBush:
	var w := get_world()
	return w.get_nearest_food(from_position) if w != null else null


func get_nearest_tree(from_position: Vector2) -> Tree_class:
	var w := get_world()
	return w.get_nearest_tree(from_position) if w != null else null


func update_influence_area() -> void:
	var target_radius: float = base_influence_radius + (expansion_mindset / 100.0) * 350.0 + (houses.get_child_count() * 40.0)
	current_influence_radius = move_toward(current_influence_radius, target_radius, 25.0)
	queue_redraw()
	print("Area di influenza: raggio = ", int(current_influence_radius), " (target: ", int(target_radius), ")")


func is_position_in_influence(pos: Vector2) -> bool:
	return global_position.distance_to(pos) <= current_influence_radius


func deposit_food(amount: float) -> void:
	stored_food += amount
	queue_redraw()
	print("Cibo depositato al centro città (+", int(amount), "). Scorte: ", int(stored_food))


func take_food(requested_amount: float) -> float:
	var taken: float = minf(requested_amount, stored_food)
	stored_food -= taken
	queue_redraw()
	return taken


func deposit_wood(amount: float) -> void:
	stored_wood += amount
	queue_redraw()
	print("Legna depositata al centro città (+", int(amount), "). Scorte: ", int(stored_wood))


func take_wood(requested_amount: float) -> float:
	var taken: float = minf(requested_amount, stored_wood)
	stored_wood -= taken
	queue_redraw()
	return taken


func check_population_growth() -> void:
	if citizen_scene == null:
		return

	if stored_food >= food_surplus_for_birth:
		stored_food -= food_cost_per_birth
		spawn_citizen()
		print("SOVRABBONDANZA DI CIBO! Nasce un nuovo cittadino. Scorte cibo rimaste: ", int(stored_food))


func spawn_citizen() -> Citizen:
	if citizen_scene == null:
		return null

	var new_citizen: Citizen = citizen_scene.instantiate()
	var offset := Vector2(randf_range(-40, 40), randf_range(-40, 40))
	new_citizen.position = offset
	new_citizen.city = self
	citizens.add_child(new_citizen)
	evaluate_housing()
	return new_citizen


func _draw() -> void:
	# 1. Alone interno semitrasparente che evidenzia il suolo controllato
	draw_circle(Vector2.ZERO, current_influence_radius, Color(0.85, 0.72, 0.35, 0.08))

	# 2. Bordo di confine visibile (arco completo da 0 a TAU)
	draw_arc(Vector2.ZERO, current_influence_radius, 0.0, TAU, 96, Color(0.92, 0.78, 0.42, 0.6), 3.0, true)

	# 3. Magazzino centrale: basamento e barre indicatori risorse
	draw_rect(Rect2(-24, -24, 48, 48), Color("#3e2723"))
	draw_rect(Rect2(-20, -20, 40, 40), Color("#5d4037"))
	# Barra cibo (verde)
	var food_fill := clampf(stored_food / 100.0, 0.0, 1.0)
	draw_rect(Rect2(-16, -14, 32, 6), Color("#263238"))
	draw_rect(Rect2(-16, -14, 32 * food_fill, 6), Color("#7cb342"))
	# Barra legna (marrone chiaro)
	var wood_fill := clampf(stored_wood / 100.0, 0.0, 1.0)
	draw_rect(Rect2(-16, -4, 32, 6), Color("#263238"))
	draw_rect(Rect2(-16, -4, 32 * wood_fill, 6), Color("#bcaaa4"))
