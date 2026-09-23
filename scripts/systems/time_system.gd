class_name TimeSystem
extends Node

signal day_passed(day_number: int)

@export var seconds_per_day := 10.0

var current_day := 1
var day_timer := 0.0
var is_paused := false
var speed_multiplier := 1.0


func _process(delta: float) -> void:
	if is_paused:
		return
	day_timer += delta * speed_multiplier
	if day_timer >= seconds_per_day:
		day_timer = 0.0
		current_day += 1
		day_passed.emit(current_day)
		print("☀️ NUOVO GIORNO SPUNTATO: Giorno ", current_day)


func advance_day_manually() -> void:
	day_timer = 0.0
	current_day += 1
	day_passed.emit(current_day)
