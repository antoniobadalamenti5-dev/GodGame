extends Node2D

const CAMERA_SPEED := 700.0

@onready var camera: Camera2D = $Camera2D
@onready var time_system = $TimeSystem
@onready var world = $World
@onready var city: City = $World/City

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


func _on_day_passed(day_number: int) -> void:
	print("È iniziato il giorno ", day_number)
