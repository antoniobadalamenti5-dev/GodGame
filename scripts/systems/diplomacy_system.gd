class_name DiplomacySystem
extends Node

signal relation_changed(new_score: float, status_string: String)
signal trade_occurred(from_city: String, to_city: String, resource: String)
signal border_tension_raised(reason: String)

enum RelationStatus { WAR, TENSION, NEUTRAL, FRIENDLY, ALLIANCE }

@export var relation_score := 15.0 # Da -100 (Guerra) a +100 (Alleanza)
var current_status := RelationStatus.NEUTRAL
var border_friction := 0.0


func evaluate_daily_relations(city_a: City, city_b: City) -> void:
	if city_a == null or city_b == null:
		return

	# 1. Calcolo sovrapposizione geometrica delle aree di influenza
	var dist: float = city_a.global_position.distance_to(city_b.global_position)
	var combined_radius: float = city_a.influence_radius + city_b.influence_radius
	
	if dist < combined_radius:
		var overlap: float = combined_radius - dist
		border_friction = clampf((overlap / 300.0) * 100.0, 0.0, 100.0)
		# L'attrito territoriale consuma la diplomazia nel tempo
		relation_score -= border_friction * 0.04
		border_tension_raised.emit("Sovrapposizione dei confini territoriali (-" + str(int(border_friction * 0.04)) + ")")
	else:
		border_friction = 0.0
		# Distanza di sicurezza: lenta distensione naturale
		if relation_score < 20.0:
			relation_score = minf(relation_score + 1.0, 20.0)

	_update_status()


func record_trade(amount: float) -> void:
	relation_score = minf(relation_score + amount * 0.5, 100.0)
	trade_occurred.emit("Aethelgard", "Kael-Thar", "Provviste")
	_update_status()


func _update_status() -> void:
	relation_score = clampf(relation_score, -100.0, 100.0)
	var prev_status = current_status

	if relation_score <= -40.0:
		current_status = RelationStatus.WAR
	elif relation_score <= -10.0:
		current_status = RelationStatus.TENSION
	elif relation_score <= 40.0:
		current_status = RelationStatus.NEUTRAL
	elif relation_score <= 75.0:
		current_status = RelationStatus.FRIENDLY
	else:
		current_status = RelationStatus.ALLIANCE

	var status_names = ["GUERRA", "TENSIONE", "NEUTRALE", "AMICHEVOLE", "ALLEANZA"]
	var name_str = status_names[current_status]
	relation_changed.emit(relation_score, name_str)
	
	if prev_status != current_status:
		print("📜 RELAZIONE DIPLOMATICA MUTATA: ", name_str, " (Punteggio: ", int(relation_score), ")")
