extends Node2D

const CAMERA_SPEED := 700.0

@onready var camera: Camera2D = $Camera2D
@onready var time_system: TimeSystem = $TimeSystem
@onready var world: GameWorld = $World
@onready var city: City = $World/City
@onready var god_state: GodState = get_node_or_null("GodState")


func _ready() -> void:
	camera.offset = Vector2.ZERO
	camera.position = world.map_size / 2.0
	time_system.day_passed.connect(_on_day_passed)
	time_system.day_passed.connect(world.advance_day)
	time_system.day_passed.connect(city.advance_day)
	queue_redraw()


func _process(delta: float) -> void:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	camera.position += direction * CAMERA_SPEED * delta

	var half_viewport := get_viewport_rect().size / 2.0
	camera.position = camera.position.clamp(
		half_viewport,
		world.map_size - half_viewport
	)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if god_state == null:
			return

		# Tasto 1: Miracolo Pioggia della Vita (20 Fede)
		if event.keycode == KEY_1:
			if god_state.spend_faith(20.0):
				world.apply_rain_miracle()
				print("🌧️ Hai invocato la Pioggia della Vita (-20 Fede)!")

		# Tasto 2: Miracolo Crescita Silvana (25 Fede)
		elif event.keycode == KEY_2:
			if god_state.spend_faith(25.0):
				world.apply_tree_growth_miracle()
				print("🌲 Hai invocato la Crescita Silvana (-25 Fede)!")


func _on_day_passed(day_number: int) -> void:
	print("È iniziato il giorno ", day_number)
