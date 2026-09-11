class_name Citizen
extends Node2D

enum Activity {
	IDLE,
	GOING_TO_WATER,
	GOING_TO_FOOD,
}

const NEED_ACTION_THRESHOLD := 70.0

@export var water_source: WaterSource
@export var berry_bush: BerryBush
@export var time_system: TimeSystem
@export var move_speed := 250.0
@export var thirst_loss_per_day := 3.0
@export var hunger_loss_per_day := 5.0

var thirst := 50.0
var hunger := 80.0
var activity: int = Activity.IDLE
var target: Node2D


func _ready() -> void:
	time_system.day_passed.connect(_on_day_passed)
	choose_next_action()
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
	choose_next_action()
	queue_redraw()


func choose_next_action() -> void:
	if thirst <= hunger and thirst < NEED_ACTION_THRESHOLD:
		activity = Activity.GOING_TO_WATER
		target = water_source
		print("Il cittadino cerca acqua.")
	elif hunger < NEED_ACTION_THRESHOLD:
		activity = Activity.GOING_TO_FOOD
		target = berry_bush
		print("Il cittadino cerca cibo.")
	else:
		activity = Activity.IDLE
		target = null


func complete_current_action() -> void:
	if activity == Activity.GOING_TO_WATER:
		thirst = minf(thirst + water_source.take_water(35.0), 100.0)
		print("Il cittadino ha bevuto. Sete: ", thirst)

	if activity == Activity.GOING_TO_FOOD:
		hunger = minf(hunger + berry_bush.take_food(30.0), 100.0)
		print("Il cittadino ha mangiato. Fame: ", hunger)

	activity = Activity.IDLE
	target = null
	queue_redraw()


func _draw() -> void:
	var body_color: Color = Color("#d1b26f")

	if activity == Activity.GOING_TO_WATER:
		body_color = Color("#5ca9e6")
	elif activity == Activity.GOING_TO_FOOD:
		body_color = Color("#81b85a")

	draw_circle(Vector2.ZERO, 15.0, body_color)

	var thirst_ratio: float = thirst / 100.0
	var hunger_ratio: float = hunger / 100.0

	draw_rect(Rect2(-20, -30, 40, 4), Color("#263238"))
	draw_rect(Rect2(-20, -30, 40 * thirst_ratio, 4), Color("#3d8fd1"))

	draw_rect(Rect2(-20, -23, 40, 4), Color("#263238"))
	draw_rect(Rect2(-20, -23, 40 * hunger_ratio, 4), Color("#6cab4b"))
