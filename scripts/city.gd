class_name City
extends Node2D

signal influence_radius_changed(new_radius: float)
signal resources_updated(food: float, wood: float)

@export var faction_id := "player" # "player" oppure "rival"
@export var city_name := "Aethelgard"
@export var base_influence_radius := 360.0
@export var stored_food := 40.0
@export var stored_wood := 25.0
@export var expansion_mindset := 20.0

@onready var world: GameWorld = get_parent() as GameWorld
@onready var temple: Temple = get_node_or_null("Temple")
@onready var god_state: GodState = get_node_or_null("../../GodState") if get_parent() != null else null

var influence_radius := 360.0


func _ready() -> void:
	_update_influence_radius()
	queue_redraw()


func deposit_food(amount: float) -> void:
	stored_food += amount
	resources_updated.emit(stored_food, stored_wood)


func deposit_wood(amount: float) -> void:
	stored_wood += amount
	resources_updated.emit(stored_food, stored_wood)


func advance_day(_day_number: int) -> void:
	# Inerzia culturale e crescita influenza
	if god_state != null and faction_id == "player":
		expansion_mindset = move_toward(expansion_mindset, god_state.expansion_directive, 1.0)
	
	_update_influence_radius()
	queue_redraw()


func _update_influence_radius() -> void:
	influence_radius = base_influence_radius + (expansion_mindset * 2.2)
	influence_radius_changed.emit(influence_radius)


func get_nearest_water(from_pos: Vector2) -> WaterSource:
	if world != null:
		return world.get_nearest_water(from_pos)
	return null


func get_nearest_food(from_pos: Vector2) -> BerryBush:
	if world != null:
		return world.get_nearest_food(from_pos)
	return null


func get_nearest_tree(from_pos: Vector2) -> Tree_class:
	if world != null:
		return world.get_nearest_tree(from_pos)
	return null


func get_meeting_place() -> Node2D:
	return get_node_or_null("MeetingPlace")


func get_active_construction_site() -> Node2D:
	return get_node_or_null("ConstructionSite")


func _draw() -> void:
	# Cerchio di influenza territoriale semi-trasparente
	var aura_color = Color(1.0, 0.85, 0.3, 0.08) if faction_id == "player" else Color(0.9, 0.35, 0.2, 0.08)
	var border_color = Color(1.0, 0.85, 0.3, 0.5) if faction_id == "player" else Color(0.9, 0.35, 0.2, 0.5)
	
	draw_circle(Vector2.ZERO, influence_radius, aura_color)
	draw_arc(Vector2.ZERO, influence_radius, 0.0, TAU, 64, border_color, 2.0)

	# Magazzino centrale
	var store_color = Color("#3e2723") if faction_id == "player" else Color("#431407")
	draw_rect(Rect2(-24, -24, 48, 48), store_color)
