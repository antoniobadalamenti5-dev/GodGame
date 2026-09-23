class_name EventSystem
extends Node

signal event_started(event_type: int, event_name: String, duration: int, description: String)
signal event_ended(event_name: String)

enum EventType { NONE, DROUGHT, ABUNDANCE, FESTIVAL, STORM }

var current_event := EventType.NONE
var remaining_days := 0
var current_event_name := "Nessun Evento"


func advance_day(_day_number: int) -> void:
	if current_event != EventType.NONE:
		remaining_days -= 1
		print("⏳ Evento attivo: ", current_event_name, " (Giorni rimasti: ", remaining_days, ")")
		if remaining_days <= 0:
			end_event()
	else:
		# 15% di probabilità giornaliera che emerga un evento spontaneo
		if randf() < 0.15:
			_roll_random_event()


func trigger_event(type: int, duration_days: int) -> void:
	current_event = type
	remaining_days = duration_days
	
	var desc := ""
	match type:
		EventType.DROUGHT:
			current_event_name = "Siccità Implacabile"
			desc = "Il sole inaridisce i fiumi e raddoppia la sete dei mortali. Le città competono per l'acqua!"
		EventType.ABUNDANCE:
			current_event_name = "Abbondanza della Terra"
			desc = "La natura fiorisce a ritmo prodigioso. Bacche e alberi si moltiplicano ovunque!"
		EventType.FESTIVAL:
			current_event_name = "Festa Sacra della Devozione"
			desc = "I cittadini lasciano il lavoro per danzare e pregare al Tempio. La Fede si accumula rapidamente!"
		EventType.STORM:
			current_event_name = "Tempesta Divina"
			desc = "Venti furiosi e fulmini. I laghi traboccano d'acqua pura."

	event_started.emit(current_event, current_event_name, duration_days, desc)
	print("🌪️ EVENTO MONDIALE INIZIATO: ", current_event_name, " per ", duration_days, " giorni!")


func end_event() -> void:
	var prev_name = current_event_name
	current_event = EventType.NONE
	remaining_days = 0
	current_event_name = "Nessun Evento"
	event_ended.emit(prev_name)
	print("☀️ L'evento ", prev_name, " si è concluso. La terra torna alla normalità.")


func _roll_random_event() -> void:
	var types = [EventType.DROUGHT, EventType.ABUNDANCE, EventType.FESTIVAL, EventType.STORM]
	var selected: int = types[randi() % types.size()]
	trigger_event(selected, randi_range(2, 4))
