extends Node2D

const MAP_SIZE := Vector2(4096, 2560)
const CELL_SIZE := 128.0
const CAMERA_SPEED := 700.0

@onready var camera: Camera2D = $Camera2D


func _ready() -> void:
	camera.offset = Vector2.ZERO
	camera.position = MAP_SIZE / 2.0
	queue_redraw()


func _process(delta: float) -> void:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	camera.position += direction * CAMERA_SPEED * delta

	var half_viewport := get_viewport_rect().size / 2.0
	camera.position = camera.position.clamp(
		half_viewport,
		MAP_SIZE - half_viewport
	)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, MAP_SIZE), Color("#577a4b"))

	for x in range(0, int(MAP_SIZE.x) + 1, int(CELL_SIZE)):
		draw_line(Vector2(x, 0), Vector2(x, MAP_SIZE.y), Color("#45643c"), 2.0)

	for y in range(0, int(MAP_SIZE.y) + 1, int(CELL_SIZE)):
		draw_line(Vector2(0, y), Vector2(MAP_SIZE.x, y), Color("#45643c"), 2.0)

	draw_circle(MAP_SIZE / 2.0, 24.0, Color("#d4b16a"))
