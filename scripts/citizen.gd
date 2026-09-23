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
}

@export var need_action_threshold := 45.0
const WOOD_PER_TRIP := 20.0
const FOOD_PER_TRIP := 30.0
const CRITICAL_SOCIALITY_THRESHOLD := 20.0

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

	# 1. Sete
	if thirst <= hunger and thirst < need_action_threshold:
		var water_source = city.get_nearest_water(global_position)
		if water_source != null:
			activity = Activity.GOING_TO_WATER
			target = water_source
			return

	# 2. Fame
	if hunger < need_action_threshold:
		var needed: float = 100.0 - hunger
		if city.stored_food >= needed:
			activity = Activity.GOING_TO_FOOD
			target = city
			return
		else:
			var berry_bush = city.get_nearest_food(global_position)
			if berry_bush != null:
				activity = Activity.GOING_TO_FOOD
				target = berry_bush
				return

	# 3. Socialità critica
	if sociality <= CRITICAL_SOCIALITY_THRESHOLD and meeting_place != null:
		activity = Activity.GOING_TO_SOCIAL_PLACE
		target = meeting_place
		return

	# 4. Devozione verso il Tempio (se presente)
	if devotion < need_action_threshold and city.temple != null:
		activity = Activity.GOING_TO_TEMPLE
		target = city.temple
		return

	# 5. Lavoro al cantiere o socializzazione ordinaria
	if construction_site != null and city.expansion_mindset > 30.0:
		start_construction_work()
	elif sociality < need_action_threshold and meeting_place != null:
		activity = Activity.GOING_TO_SOCIAL_PLACE
		target = meeting_place
	else:
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
		elif target.has_method("take_food"):
			var gathered = target.take_food(FOOD_PER_TRIP)
			carried_food = gathered
			activity = Activity.DELIVERING_TO_CITY
			target = city
			return

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
				var needed_wood = site.wood_required - site.current_wood
				var wood_to_take = minf(city.stored_wood, needed_wood)
				city.stored_wood -= wood_to_take
				site.add_wood(wood_to_take)

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
	queue_redraw()


func _draw() -> void:
	var body_color: Color = Color("#d1b26f")

	if city != null and city.faction_id == "rival":
		body_color = Color("#e06d53") # Ocra/terracotta per cittadini rivali

	if activity == Activity.GOING_TO_WATER:
		body_color = Color("#5ca9e6")
	elif activity == Activity.GOING_TO_FOOD:
		body_color = Color("#81b85a")
	elif activity == Activity.GOING_TO_TREE:
		body_color = Color("#a26d3f")
	elif activity == Activity.GOING_TO_TEMPLE:
		body_color = Color("#fbc02d") # Dorato sacro

	draw_circle(Vector2.ZERO, 15.0, body_color)

	if carried_wood > 0.0:
		draw_circle(Vector2(18, 0), 7.0, Color("#704831"))
	if carried_food > 0.0:
		draw_circle(Vector2(-18, 0), 7.0, Color("#b24d62"))
