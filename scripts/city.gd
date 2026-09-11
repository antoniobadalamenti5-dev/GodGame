class_name City
extends Node2D

signal housing_shortage(homeless_citizens: int)

@onready var citizens: Node2D = $Citizens
@onready var houses: Node2D = $Houses
@onready var construction_sites: Node2D = $ConstructionSites


func _ready() -> void:
	for child in construction_sites.get_children():
		if child is ConstructionSite:
			child.construction_completed.connect(
				_on_construction_completed.bind(child)
			)

	evaluate_housing()


func advance_day(_day_number: int) -> void:
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

func start_housing_project() -> void:
	for child in construction_sites.get_children():
		if child is ConstructionSite:
			if not child.is_active and not child.is_completed:
				child.activate()
				print("La città avvia un cantiere per una nuova casa.")
				return

func _on_construction_completed(site: ConstructionSite) -> void:
	var new_house: House = House.new()
	new_house.position = site.position

	houses.add_child(new_house)
	site.queue_free()

	print("Una nuova casa è stata completata.")
	evaluate_housing()
