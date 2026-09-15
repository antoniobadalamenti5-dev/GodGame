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

var thirst := 50.0
var hunger := 80.0
var shelter := 100.0
@export var sociality := 100.0
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

	if global_position.distance_to(target.global_position) < 2.0:
		complete_current_action()


func advance_day(_day_number: int) -> void:
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

	# Se il cittadino trasporta cibo o legna, prima la consegna al magazzino
	if carried_food > 0.0:
		activity = Activity.DELIVERING_TO_CITY
		target = city
		return

	var meeting_place: MeetingPlace = city.get_meeting_place()
	var construction_site: ConstructionSite = city.get_active_construction_site()

	# 1. Sete (priorità vitale massima)
	if thirst <= hunger and thirst < need_action_threshold:
		var water_source: WaterSource = city.get_nearest_water(global_position)
		if water_source != null:
			activity = Activity.GOING_TO_WATER
			target = water_source
			print("Il cittadino cerca acqua.")
			return

	# 2. Fame (priorità vitale)
	if hunger < need_action_threshold:
		var needed: float = 100.0 - hunger
		# Se il magazzino cittadino ha abbastanza cibo, mangia al centro città
		if city.stored_food >= needed:
			activity = Activity.GOING_TO_FOOD
			target = city
			print("Il cittadino va a mangiare al magazzino cittadino.")
			return
		else:
			# Altrimenti va ai cespugli a raccogliere provviste per sé e per la comunità
			var berry_bush: BerryBush = city.get_nearest_food(global_position)
			if berry_bush != null:
				activity = Activity.GOING_TO_FOOD
				target = berry_bush
				print("Il cittadino cerca cibo nei cespugli.")
				return

	# 3. Socialità critica
	if sociality <= CRITICAL_SOCIALITY_THRESHOLD and meeting_place != null:
		activity = Activity.GOING_TO_SOCIAL_PLACE
		target = meeting_place
		print("Il cittadino ha urgente bisogno di compagnia.")
		return

	# 4. Scelta ponderata tra cantiere e socialità
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
		# Se non ha bisogni e la scorta della città è sotto la soglia di nascita, contribuisce raccogliendo cibo
		if city.stored_food < city.food_surplus_for_birth:
			var bush: BerryBush = city.get_nearest_food(global_position)
			if bush != null and bush.current_amount > 0.0:
				activity = Activity.GOING_TO_FOOD
				target = bush
				print("Il cittadino raccoglie cibo per aumentare le scorte comunitarie.")
				return

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
		# Se la città ha legna in magazzino, la preleva da lì per velocizzare il lavoro
		if city.stored_wood >= WOOD_PER_TRIP:
			activity = Activity.GOING_TO_TREE
			target = city
			print("Il cittadino preleva legna dal magazzino per il cantiere.")
		else:
			var nearest_tree: Tree_class = city.get_nearest_tree(global_position)
			if nearest_tree != null:
				activity = Activity.GOING_TO_TREE
				target = nearest_tree
				print("Il cittadino cerca legno nella foresta.")
			else:
				activity = Activity.IDLE
				target = null


func complete_current_action() -> void:
	if activity == Activity.GOING_TO_WATER:
		var target_water := target as WaterSource
		if target_water != null and is_instance_valid(target_water):
			var water_needed: float = 100.0 - thirst
			var water_collected: float = target_water.take_water(water_needed)
			thirst = minf(thirst + water_collected, 100.0)
			print("Il cittadino ha bevuto. Sete: ", int(thirst))

	elif activity == Activity.GOING_TO_FOOD:
		var food_needed: float = 100.0 - hunger
		if target == city:
			# Ha mangiato al magazzino cittadino
			var taken := city.take_food(food_needed)
			hunger = minf(hunger + taken, 100.0)
			print("Il cittadino ha mangiato dal magazzino. Fame: ", int(hunger))
		else:
			var target_food := target as BerryBush
			if target_food != null and is_instance_valid(target_food):
				var collected: float = target_food.take_food(FOOD_PER_TRIP)
				var consumed: float = minf(collected, food_needed)
				hunger = minf(hunger + consumed, 100.0)
				var surplus: float = collected - consumed
				if surplus > 0.0:
					carried_food = surplus
					activity = Activity.DELIVERING_TO_CITY
					target = city
					print("Il cittadino trasporta ", int(carried_food), " cibo di scorta al magazzino.")
					queue_redraw()
					return
				print("Il cittadino ha mangiato bacche. Fame: ", int(hunger))

	elif activity == Activity.GOING_TO_SOCIAL_PLACE:
		sociality = 100.0
		print("Il cittadino ha socializzato.")

	elif activity == Activity.GOING_TO_TREE:
		if target == city:
			carried_wood = city.take_wood(WOOD_PER_TRIP)
		else:
			var target_tree := target as Tree_class
			if target_tree != null and is_instance_valid(target_tree):
				carried_wood = target_tree.take_wood(WOOD_PER_TRIP)

		if carried_wood > 0.0:
			activity = Activity.GOING_TO_CONSTRUCTION_SITE
			target = city.get_active_construction_site()
			print("Il cittadino trasporta ", int(carried_wood), " legno al cantiere.")
			queue_redraw()
			return

	elif activity == Activity.GOING_TO_CONSTRUCTION_SITE:
		var site: ConstructionSite = target as ConstructionSite

		if site == null or not is_instance_valid(site):
			if carried_wood > 0.0:
				activity = Activity.DELIVERING_TO_CITY
				target = city
				return
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
	elif activity == Activity.DELIVERING_TO_CITY:
		body_color = Color("#e57373")

	draw_circle(Vector2.ZERO, 15.0, body_color)

	if carried_wood > 0.0:
		draw_circle(Vector2(18, 0), 7.0, Color("#704831"))
	if carried_food > 0.0:
		draw_circle(Vector2(-18, 0), 7.0, Color("#b24d62"))


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
