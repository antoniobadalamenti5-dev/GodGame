class_name City
extends Node2D

signal housing_shortage(homeless_citizens: int)

@export var construction_site_scene: PackedScene
@export var construction_origin := Vector2(180, 130)
@export var god_state: GodState
@export var mentality_change_per_day := 5.0

@onready var citizens: Node2D = $Citizens
@onready var houses: Node2D = $Houses
@onready var construction_sites: Node2D = $ConstructionSites
var expansion_mindset := 0.0
@onready var social_structures: Node2D = $SocialStructures
@onready var temple: Temple = $Temple


func _ready() -> void:
	evaluate_housing()


func advance_day(_day_number: int) -> void:
	update_mentality()
	evaluate_housing()


func evaluate_housing() -> void:
	var remaining_capacity: int = get_total_housing_capacity()
	var homeless_citizens: int = 0

	for child in citizens.get_children():
		if child is Citizen:
			var has_home: bool = remaining_capacity > 0
			child.set_housed(has_home)

			if has_home:
				remaining_capacity -= 1
			else:
				homeless_citizens += 1

	if homeless_citizens > 0:
		housing_shortage.emit(homeless_citizens)
		print("Carenza abitativa: ", homeless_citizens, " cittadino/i senza casa.")
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
