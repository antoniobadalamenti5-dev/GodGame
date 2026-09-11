class_name Citizen
extends Node2D

enum Activity {
	IDLE,
	GOING_TO_WATER,
	GOING_TO_FOOD,
	GOING_TO_TREE,
	GOING_TO_CONSTRUCTION_SITE,
	GOING_TO_SOCIAL_PLACE,
}

@export var need_action_threshold := 45.0
const WOOD_PER_TRIP := 20.0
const CRITICAL_SOCIALITY_THRESHOLD := 20.0

@export var water_source: WaterSource
@export var berry_bush: BerryBush
@export var tree: Tree_class
@export var city: City
@export var time_system: TimeSystem
@export var move_speed := 250.0
@export var thirst_loss_per_day := 3.0
@export var hunger_loss_per_day := 5.0
@export var shelter_loss_per_day := 8.0
@export var shelter_recovery_per_day := 12.0
@export var sociality_loss_per_day := 2.0

var thirst := 50.0
var hunger := 80.0
var shelter := 100.0
@export var sociality := 100.0
var is_housed := false
var carried_wood := 0.0
var activity: int = Activity.IDLE
var target: Node2D


func _ready() -> void:
	z_index = 2
	time_system.day_passed.connect(_on_day_passed)
	call_deferred("choose_next_action")
	queue_redraw()


func _process(delta: float) -> void:
	if target == null:
		return

	global_position = global_position.move_toward(
		target.global_position,
		move_speed * delta
	)

	if global_position.distance_to(target.global_position) < 2.0:
		complete_current_action()


func _on_day_passed(_day_number: int) -> void:
	thirst = maxf(thirst - thirst_loss_per_day, 0.0)
	hunger = maxf(hunger - hunger_loss_per_day, 0.0)
	sociality = maxf(sociality - sociality_loss_per_day, 0.0)

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

	var meeting_place: MeetingPlace = city.get_meeting_place()
	var construction_site: ConstructionSite = city.get_active_construction_site()

	if thirst <= hunger and thirst < need_action_threshold:
		activity = Activity.GOING_TO_WATER
		target = water_source
		print("Il cittadino cerca acqua.")
		return

	if hunger < need_action_threshold:
		activity = Activity.GOING_TO_FOOD
		target = berry_bush
		print("Il cittadino cerca cibo.")
		return

	if sociality <= CRITICAL_SOCIALITY_THRESHOLD and meeting_place != null:
		activity = Activity.GOING_TO_SOCIAL_PLACE
		target = meeting_place
		print("Il cittadino ha urgente bisogno di compagnia.")
		return

	var social_score := -1.0
	if sociality < need_action_threshold and meeting_place != null:
		social_score = 100.0 - sociality

	var construction_score := -1.0
	if construction_site != null:
		construction_score = city.expansion_mindset

	if construction_score > social_score:
		start_construction_work()
	elif social_score >= 0.0:
		activity = Activity.GOING_TO_SOCIAL_PLACE
		target = meeting_place
		print("Il cittadino sceglie di socializzare.")
	else:
		activity = Activity.IDLE
		target = null


func start_construction_work() -> void:
	var site: ConstructionSite = city.get_active_construction_site()

	if site == null:
		activity = Activity.IDLE
		target = null
		return

	if carried_wood > 0.0:
		activity = Activity.GOING_TO_CONSTRUCTION_SITE
		target = site
		print("Il cittadino porta legno al cantiere.")
	else:
		activity = Activity.GOING_TO_TREE
		target = tree
		print("Il cittadino cerca legno.")


func complete_current_action() -> void:
	if activity == Activity.GOING_TO_WATER:
		var water_needed: float = 100.0 - thirst
		var water_collected: float = water_source.take_water(water_needed)

		thirst = minf(thirst + water_collected, 100.0)
		print("Il cittadino ha bevuto. Sete: ", thirst)

	elif activity == Activity.GOING_TO_FOOD:
		var food_needed: float = 100.0 - hunger
		var food_collected: float = berry_bush.take_food(food_needed)

		hunger = minf(hunger + food_collected, 100.0)
		print("Il cittadino ha mangiato. Fame: ", hunger)

	elif activity == Activity.GOING_TO_SOCIAL_PLACE:
		sociality = 100.0
		print("Il cittadino ha socializzato.")

	elif activity == Activity.GOING_TO_TREE:
		carried_wood = tree.take_wood(WOOD_PER_TRIP)

		if carried_wood > 0.0:
			activity = Activity.GOING_TO_CONSTRUCTION_SITE
			target = city.get_active_construction_site()
			print("Il cittadino trasporta ", carried_wood, " legno.")
			queue_redraw()
			return

	elif activity == Activity.GOING_TO_CONSTRUCTION_SITE:
		var site: ConstructionSite = target as ConstructionSite

		if site == null or not is_instance_valid(site):
			carried_wood = 0.0
		elif site.is_active and not site.is_completed:
			carried_wood -= site.deliver_wood(carried_wood)
			print("Il cittadino consegna legno al cantiere.")

			if site.is_completed:
				carried_wood = 0.0
				print("Il cantiere ha abbastanza legno.")
			else:
				start_construction_work()
				queue_redraw()
				return

	activity = Activity.IDLE
	target = null
	queue_redraw()




func set_housed(value: bool) -> void:
	is_housed = value
	queue_redraw()


func _draw() -> void:
	var body_color: Color = Color("#d1b26f")

	if activity == Activity.GOING_TO_WATER:
		body_color = Color("#5ca9e6")
	elif activity == Activity.GOING_TO_FOOD:
		body_color = Color("#81b85a")
	elif activity == Activity.GOING_TO_TREE:
		body_color = Color("#a26d3f")
	elif activity == Activity.GOING_TO_CONSTRUCTION_SITE:
		body_color = Color("#cf9c54")
	elif activity == Activity.GOING_TO_SOCIAL_PLACE:
		body_color = Color("#9a78bd")

	draw_circle(Vector2.ZERO, 15.0, body_color)

	if carried_wood > 0.0:
		draw_circle(Vector2(18, 0), 7.0, Color("#704831"))

	var thirst_ratio: float = thirst / 100.0
	var hunger_ratio: float = hunger / 100.0
	var shelter_ratio: float = shelter / 100.0
	var sociality_ratio: float = sociality / 100.0

	draw_rect(Rect2(-20, -9, 40, 4), Color("#263238"))
	draw_rect(Rect2(-20, -9, 40 * sociality_ratio, 4), Color("#9a78bd"))

	draw_rect(Rect2(-20, -30, 40, 4), Color("#263238"))
	draw_rect(Rect2(-20, -30, 40 * thirst_ratio, 4), Color("#3d8fd1"))

	draw_rect(Rect2(-20, -23, 40, 4), Color("#263238"))
	draw_rect(Rect2(-20, -23, 40 * hunger_ratio, 4), Color("#6cab4b"))

	draw_rect(Rect2(-20, -16, 40, 4), Color("#263238"))
	draw_rect(Rect2(-20, -16, 40 * shelter_ratio, 4), Color("#c28b52"))
