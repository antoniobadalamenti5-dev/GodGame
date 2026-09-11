class_name TimeSystem
extends Node

signal day_passed(day_number: int)

@export var seconds_per_day := 2.0

var current_day := 0
var elapsed_time := 0.0


func _process(delta: float) -> void:
	elapsed_time += delta

	if elapsed_time >= seconds_per_day:
		elapsed_time -= seconds_per_day
		current_day += 1
		day_passed.emit(current_day)
