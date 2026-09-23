class_name GodState
extends Node

signal faith_changed(current_faith: float, max_faith: float)
signal miracle_invoked(miracle_name: String, cost: float)

@export_range(0.0, 100.0, 1.0) var expansion_directive := 0.0
@export var max_faith := 100.0
var current_faith := 35.0


func _ready() -> void:
	call_deferred("emit_faith_state")


func emit_faith_state() -> void:
	faith_changed.emit(current_faith, max_faith)


func add_faith(amount: float) -> void:
	current_faith = minf(current_faith + amount, max_faith)
	faith_changed.emit(current_faith, max_faith)
	print("✨ FEDE DIVINA AUMENTATA: +", int(amount), " (Totale: ", int(current_faith), "/", int(max_faith), ")")


func spend_faith(amount: float) -> bool:
	if current_faith >= amount:
		current_faith -= amount
		faith_changed.emit(current_faith, max_faith)
		return true
	print("❌ Fede insufficiente! Richiesti: ", int(amount), ", Disponibili: ", int(current_faith))
	return false
