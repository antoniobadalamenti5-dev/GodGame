class_name Temple
extends Node2D

signal offering_received(faith_gained: float)

@export var faith_per_prayer := 6.0
@export var faith_per_food_unit := 0.8

var total_prayers_received := 0


func _ready() -> void:
	queue_redraw()


func receive_prayer(god_state: GodState) -> void:
	total_prayers_received += 1
	if god_state != null:
		god_state.add_faith(faith_per_prayer)
	offering_received.emit(faith_per_prayer)
	print("🏛️ Un fedele ha pregato al Tempio. Preghiere totali: ", total_prayers_received)
	queue_redraw()


func receive_food_offering(food_amount: float, god_state: GodState) -> void:
	var faith_gain := food_amount * faith_per_food_unit
	if god_state != null:
		god_state.add_faith(faith_gain)
	offering_received.emit(faith_gain)
	print("🏛️ Offerta di cibo sull'altare (+", int(food_amount), " cibo -> +", int(faith_gain), " fede).")
	queue_redraw()


func _draw() -> void:
	# Basamento del Tempio
	draw_rect(Rect2(-45, -35, 90, 70), Color("#b99b67"))
	# Frontone triangolare monumentale
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-55, -35),
			Vector2(0, -75),
			Vector2(55, -35),
		]),
		Color("#775e44")
	)
	# Portale sacro d'ingresso
	draw_rect(Rect2(-8, 0, 16, 35), Color("#4b3024"))
	
	# Aura della Fede dorata pulsante
	var aura_alpha := 0.25 + minf(float(total_prayers_received) * 0.04, 0.45)
	draw_circle(Vector2(0, -18), 16.0, Color(1.0, 0.88, 0.35, aura_alpha))
