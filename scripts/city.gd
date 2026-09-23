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
var max_food := 100.0
var max_wood := 100.0

var crop_fields: Array[CropField] = []
var warehouses: Array[Warehouse] = []
var laboratories: Array[Laboratory] = []
var pending_construction: String = "" # "Warehouse", "CropField", "Laboratory"
var research_points := 0.0


func _ready() -> void:
	_update_influence_radius()
	_update_max_capacity()
	queue_redraw()


func deposit_food(amount: float) -> void:
	stored_food = minf(stored_food + amount, max_food)
	resources_updated.emit(stored_food, stored_wood)


func deposit_wood(amount: float) -> void:
	stored_wood = minf(stored_wood + amount, max_wood)
	resources_updated.emit(stored_food, stored_wood)


func advance_day(_day_number: int) -> void:
	if god_state != null and faction_id == "player":
		expansion_mindset = move_toward(expansion_mindset, god_state.expansion_directive, 1.0)
	
	for field in crop_fields:
		field.advance_day()
		
	_update_influence_radius()
	queue_redraw()


func _update_influence_radius() -> void:
	influence_radius = base_influence_radius + (expansion_mindset * 2.2)
	influence_radius_changed.emit(influence_radius)


func _update_max_capacity() -> void:
	var bonus_capacity = 0.0
	for w in warehouses:
		bonus_capacity += w.capacity_bonus
	max_food = 100.0 + bonus_capacity
	max_wood = 100.0 + bonus_capacity


func get_nearest_water(from_pos: Vector2) -> WaterSource:
	if world != null:
		return world.get_nearest_water(from_pos)
	return null


func get_nearest_food(from_pos: Vector2) -> Node2D:
	# Controlla prima i campi coltivati pronti
	var nearest_field = null
	var min_dist_field = INF
	for field in crop_fields:
		if field.current_state == CropField.State.READY:
			var dist = from_pos.distance_squared_to(field.global_position)
			if dist < min_dist_field:
				min_dist_field = dist
				nearest_field = field
				
	# Controlla cespugli naturali
	var nearest_bush = null
	if world != null:
		nearest_bush = world.get_nearest_food(from_pos)
		
	# Restituisci il più vicino (privilegiando i campi se sono vicini, altrimenti i cespugli)
	if nearest_field != null and nearest_bush != null:
		if min_dist_field <= from_pos.distance_squared_to(nearest_bush.global_position) * 1.5:
			return nearest_field
		else:
			return nearest_bush
	elif nearest_field != null:
		return nearest_field
	return nearest_bush


func get_nearest_tree(from_pos: Vector2) -> Tree_class:
	if world != null:
		return world.get_nearest_tree(from_pos)
	return null


func get_nearest_empty_crop_field() -> CropField:
	for field in crop_fields:
		if field.current_state == CropField.State.EMPTY:
			return field
	return null


func get_meeting_place() -> Node2D:
	return get_node_or_null("MeetingPlace")


func get_active_construction_site() -> ConstructionSite:
	var site = get_node_or_null("ConstructionSite")
	if site != null and site is ConstructionSite and site.is_active:
		return site as ConstructionSite
	return null


func request_building(type: String) -> void:
	if get_active_construction_site() != null:
		return # Un cantiere è già attivo
		
	var site = get_node_or_null("ConstructionSite") as ConstructionSite
	if site == null:
		site = ConstructionSite.new()
		site.name = "ConstructionSite"
		add_child(site)
		
	if not site.construction_completed.is_connected(_on_construction_completed):
		site.construction_completed.connect(_on_construction_completed)
	
	pending_construction = type
	if type == "Warehouse":
		site.required_wood = 50.0
		# Posiziona in un punto semi-casuale
		site.position = Vector2(randf_range(-60, 60), randf_range(50, 100))
	elif type == "CropField":
		site.required_wood = 30.0
		# Posiziona più lontano
		site.position = Vector2(randf_range(80, 140) * (1 if randf() > 0.5 else -1), randf_range(-140, -80))
	elif type == "Laboratory":
		site.required_wood = 80.0
		# Posiziona al centro-alto
		site.position = Vector2(randf_range(-40, 40), randf_range(-60, -20))
		
	site.delivered_wood = 0.0
	site.is_completed = false
	site.activate()
	print(city_name, ": Cantiere aperto per ", type)


func _on_construction_completed() -> void:
	var site = get_node_or_null("ConstructionSite") as ConstructionSite
	if site == null:
		return
		
	if pending_construction == "Warehouse":
		var w = Warehouse.new()
		w.position = site.position
		add_child(w)
		warehouses.append(w)
		_update_max_capacity()
		print(city_name, ": Magazzino completato! Nuova capacità: ", max_food)
	elif pending_construction == "CropField":
		var f = CropField.new()
		f.position = site.position
		add_child(f)
		crop_fields.append(f)
		print(city_name, ": Campo agricolo completato!")
	elif pending_construction == "Laboratory":
		var lab = Laboratory.new()
		lab.position = site.position
		add_child(lab)
		laboratories.append(lab)
		print(city_name, ": Laboratorio completato!")
		
	site.is_active = false
	site.visible = false
	site.queue_redraw()
	pending_construction = ""

func add_research_points(amount: float) -> void:
	research_points += amount
	_check_for_upgrades()

func _check_for_upgrades() -> void:
	# Warehouse Level 2 costs 50 research points
	for w in warehouses:
		if not w.has_meta("level"):
			w.set_meta("level", 1)
		
		var w_level = w.get_meta("level")
		if w_level == 1 and research_points >= 50.0:
			research_points -= 50.0
			w.set_meta("level", 2)
			w.capacity_bonus = 200.0 # Raddoppia da 100 a 200
			_update_max_capacity()
			print("Magazzino potenziato al livello 2!")
			return

	# CropField Level 2 costs 40 research points
	for c in crop_fields:
		if not c.has_meta("level"):
			c.set_meta("level", 1)
		
		var c_level = c.get_meta("level")
		if c_level == 1 and research_points >= 40.0:
			research_points -= 40.0
			c.set_meta("level", 2)
			c.growth_time_days = max(1, c.growth_time_days - 1)
			c.food_yield += 25.0
			print("Campo agricolo potenziato al livello 2!")
			return
	pending_construction = ""


func _draw() -> void:
	# Cerchio di influenza territoriale semi-trasparente
	var aura_color = Color(1.0, 0.85, 0.3, 0.08) if faction_id == "player" else Color(0.9, 0.35, 0.2, 0.08)
	var border_color = Color(1.0, 0.85, 0.3, 0.5) if faction_id == "player" else Color(0.9, 0.35, 0.2, 0.5)
	
	draw_circle(Vector2.ZERO, influence_radius, aura_color)
	draw_arc(Vector2.ZERO, influence_radius, 0.0, TAU, 64, border_color, 2.0)

	# Magazzino centrale migliorato
	var store_color = Color("#3e2723") if faction_id == "player" else Color("#431407")
	draw_rect(Rect2(-24, -24, 48, 48), store_color)
	draw_rect(Rect2(-24, -24, 48, 48), Color("#2b1d14"), false, 3.0)
	draw_rect(Rect2(-12, -24, 24, 12), Color("#2b1d14")) # Porta scura
