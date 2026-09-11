class_name MeetingPlace
extends Node2D


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 42.0, Color("#75549c"))
	draw_circle(Vector2.ZERO, 27.0, Color("#9a78bd"))
