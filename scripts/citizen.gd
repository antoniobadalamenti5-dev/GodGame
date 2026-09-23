class_name Citizen
extends Node2D

enum Activity {
	IDLE,
	GOING_TO_WATER,
	GOING_TO_FOOD,
	GOING_TO_TREE,
	GOING_TO_CONSTRUCTION_SITE,
	GOING_TO_SOCIAL_PLACE,
	DELIVERING_TO_CITY,
	GOING_TO_TEMPLE,
	FARMING
}

@export var need_action_threshold := 45.0
const WOOD_PER_TRIP := 20.0
const FOOD_PER_TRIP := 30.0

@export var city: City
@export var time_system: TimeSystem
@export var move_speed := 250.0
@export var thirst_loss_per_day := 3.0
@export var hunger_loss_per_day := 5.0
@export var shelter_loss_per_day := 8.0
@export var shelter_recovery_per_day := 12.0
@export var sociality_loss_per_day := 2.0
@export var devotion_loss_per_day := 4.0

var thirst := 50.0
var hunger := 80.0
var shelter := 100.0
@export var sociality := 100.0
var devotion := 70.0
var is_housed := false
var carried_wood := 0.0
var carried_food := 0.0
var activity: int = Activity.IDLE
var target: Node2D


func _ready() -> void:
	z_index = 2
	if city == null and get_parent() != null and get_parent().get_parent() is City:
		city = get_parent().get_parent() as City
	if time_system != null:
		time_system.day_passed.connect(advance_day)
	call_deferred("choose_next_action")
	queue_redraw()


func _process(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		target = null
		if activity != Activity.IDLE:
			activity = Activity.IDLE
			choose_next_action()
		return

	global_position = global_position.move_toward(
		target.global_position,
		move_speed * delta
	)

	if global_position.distance_to(target.global_position) < 4.0:
		complete_current_action()


func advance_day(_day_number: int) -> void:
	thirst = maxf(thirst - thirst_loss_per_day, 0.0)
	hunger = maxf(hunger - hunger_loss_per_day, 0.0)
	sociality = maxf(sociality - sociality_loss_per_day, 0.0)
	devotion = maxf(devotion - devotion_loss_per_day, 0.0)

	if is_housed:
		shelter = minf(shelter + shelter_recovery_per_day, 100.0)
	else:
		shelter = maxf(shelter - shelter_loss_per_day, 0.0)

	choose_next_action()
	queue_redraw()


func choose_next_action() -> void:
	if city == null:
		activity = Activity.IDLE
		target = null
		return

	if carried_food > 0.0 or carried_wood > 0.0:
		activity = Activity.DELIVERING_TO_CITY
		target = city
		return

	var meeting_place = city.get_meeting_place()
	var construction_site = city.get_active_construction_site()

	# Controllo macro-strategico per nuovi edifici
	if city.pending_construction == "":
		var num_citizens = 1
		var citizens_node = city.get_node_or_null("Citizens")
		if citizens_node != null:
			num_citizens = max(1, citizens_node.get_child_count())
		
		var recommended_crop_fields = ceili(num_citizens / 4.0)
		var recommended_warehouses = ceili(num_citizens / 6.0)
		
		if city.crop_fields.size() < recommended_crop_fields:
			city.request_building("CropField")
		elif city.warehouses.size() < recommended_warehouses or (city.stored_wood >= city.max_wood * 0.9 or city.stored_food >= city.max_food * 0.9):
			city.request_building("Warehouse")
	
	construction_site = city.get_active_construction_site()

	# Sistema Utility-Based
	var score_thirst = (100.0 - thirst) * 1.5
	var score_hunger = (100.0 - hunger) * 1.2
	var score_social = (100.0 - sociality) * 0.8
	var score_devotion = (100.0 - devotion) * 0.9
	var score_construction = 0.0
	
	if construction_site != null:
		score_construction = 65.0 # Priorità alta per costruire

	# Priorità al lavoro agricolo (seminare campi vuoti)
	var empty_field = city.get_nearest_empty_crop_field()
	var score_farming = 0.0
	if empty_field != null and hunger >= 50.0: # Se non stanno morendo di fame immediata
		score_farming = 70.0

	var max_score = maxf(maxf(score_thirst, score_hunger), maxf(score_social, score_devotion))
	max_score = maxf(max_score, maxf(score_construction, score_farming))
	
	if max_score < (100.0 - need_action_threshold) and max_score < 50.0:
		activity = Activity.IDLE
		target = null
		return

	# Selezione Azione in base al punteggio maggiore
	if max_score == score_thirst:
		var water_source = city.get_nearest_water(global_position)
		if water_source != null:
			activity = Activity.GOING_TO_WATER
			target = water_source
			return

	if max_score == score_hunger:
		var needed: float = 100.0 - hunger
		if city.stored_food >= needed:
			activity = Activity.GOING_TO_FOOD
			target = city
			return
		else:
			var food_source = city.get_nearest_food(global_position)
			if food_source != null:
				activity = Activity.GOING_TO_FOOD
				target = food_source
				return

	if max_score == score_farming and empty_field != null:
		activity = Activity.FARMING
		target = empty_field
		return

	if max_score == score_construction and construction_site != null:
		start_construction_work()
		return

	if max_score == score_social and meeting_place != null:
		activity = Activity.GOING_TO_SOCIAL_PLACE
		target = meeting_place
		return

	if max_score == score_devotion and city.temple != null:
		activity = Activity.GOING_TO_TEMPLE
		target = city.temple
		return

	activity = Activity.IDLE
	target = null


func start_construction_work() -> void:
	if city == null:
		return
	var site = city.get_active_construction_site()
	if site == null:
		activity = Activity.IDLE
		target = null
		return

	if city.stored_wood >= WOOD_PER_TRIP:
		activity = Activity.GOING_TO_CONSTRUCTION_SITE
		target = site
	else:
		var tree = city.get_nearest_tree(global_position)
		if tree != null:
			activity = Activity.GOING_TO_TREE
			target = tree
		else:
			activity = Activity.IDLE
			target = null


func complete_current_action() -> void:
	if target == null:
		return

	if activity == Activity.GOING_TO_WATER:
		if target.has_method("take_water"):
			var drunk = target.take_water(100.0 - thirst)
			thirst = minf(thirst + drunk, 100.0)

	elif activity == Activity.GOING_TO_FOOD:
		if target == city:
			var needed = 100.0 - hunger
			var consumed = minf(city.stored_food, needed)
			city.stored_food -= consumed
			hunger = minf(hunger + consumed, 100.0)
		elif target is CropField:
			var gathered = target.take_food(FOOD_PER_TRIP)
			carried_food = gathered
			activity = Activity.DELIVERING_TO_CITY
			target = city
			return
		elif target.has_method("take_food"): # BerryBush
			var gathered = target.take_food(FOOD_PER_TRIP)
			carried_food = gathered
			activity = Activity.DELIVERING_TO_CITY
			target = city
			return
			
	elif activity == Activity.FARMING:
		if target is CropField:
			target.plant_seeds()

	elif activity == Activity.GOING_TO_TREE:
		if target.has_method("take_wood"):
			var chopped = target.take_wood(WOOD_PER_TRIP)
			carried_wood = chopped
			activity = Activity.DELIVERING_TO_CITY
			target = city
			return

	elif activity == Activity.GOING_TO_CONSTRUCTION_SITE:
		if city != null:
			var site = city.get_active_construction_site()
			if site != null:
				var needed_wood = site.required_wood - site.delivered_wood
				var wood_to_take = minf(city.stored_wood, needed_wood)
				wood_to_take = minf(wood_to_take, WOOD_PER_TRIP) # Limite trasporto
				city.stored_wood -= wood_to_take
				site.deliver_wood(wood_to_take)

	elif activity == Activity.GOING_TO_SOCIAL_PLACE:
		sociality = 100.0

	elif activity == Activity.GOING_TO_TEMPLE:
		if city != null and city.temple != null:
			city.temple.receive_prayer(city.god_state)
			devotion = 100.0

	elif activity == Activity.DELIVERING_TO_CITY:
		if carried_food > 0.0:
			city.deposit_food(carried_food)
			carried_food = 0.0
		if carried_wood > 0.0:
			city.deposit_wood(carried_wood)
			carried_wood = 0.0

	activity = Activity.IDLE
	target = null
	choose_next_action()
	queue_redraw()


func _draw() -> void:
	var body_color: Color = Color("#d1b26f")
	
	if city != null and city.faction_id == "rival":
		body_color = Color("#e06d53")

	if activity == Activity.GOING_TO_WATER:
		body_color = Color("#5ca9e6")
	elif activity == Activity.GOING_TO_FOOD:
		body_color = Color("#81b85a")
	elif activity == Activity.GOING_TO_TREE:
		body_color = Color("#a26d3f")
	elif activity == Activity.GOING_TO_TEMPLE:
		body_color = Color("#fbc02d")
	elif activity == Activity.FARMING:
		body_color = Color("#f57f17")

	# Ombra
	draw_circle(Vector2(0, 4), 16.0, Color(0, 0, 0, 0.3))
	
	# Corpo
	draw_circle(Vector2.ZERO, 15.0, body_color)
	# Contorno corpo
	draw_circle(Vector2.ZERO, 15.0, body_color.darkened(0.4), false, 2.0)

	# Se fa farming, disegna un piccolo cappello
	if activity == Activity.FARMING:
		draw_arc(Vector2(0, -5), 18.0, PI, TAU, 16, Color("#d4a373"), 4.0)

	if carried_wood > 0.0:
		draw_rect(Rect2(12, -6, 12, 12), Color("#704831"))
		draw_rect(Rect2(12, -6, 12, 12), Color("#3e2723"), false, 1.0)
	if carried_food > 0.0:
		draw_circle(Vector2(-18, 0), 7.0, Color("#b24d62"))
		draw_circle(Vector2(-18, 0), 7.0, Color("#5e1e2d"), false, 1.0)
