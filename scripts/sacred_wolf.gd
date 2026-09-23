class_name SacredWolf
extends Node2D

signal nature_evolved(new_nature: String, level: int)
signal wolf_action_performed(action_text: String)

enum State { PATROLLING_BORDER, WATCHING_TRIBE, HUNTING, RESTING_AT_ALTAR }
enum Nature { PROTECTIVE_GUARDIAN, FIERCE_BEAST, MYSTIC_GUIDE }

@export var move_speed := 180.0
@export var aura_radius := 110.0

var current_state := State.WATCHING_TRIBE
var current_nature := Nature.PROTECTIVE_GUARDIAN

var xp := 0.0
var level := 1
var protect_score := 15.0
var hunt_score := 5.0

var target_position := Vector2.ZERO
var city_ref: City = null
var patrol_angle := 0.0
var is_blessed := false
var blessing_timer := 0.0
var hunt_timer := 0.0


func _ready() -> void:
	z_index = 3
	queue_redraw()


func _process(delta: float) -> void:
	if is_blessed:
		blessing_timer -= delta
		if blessing_timer <= 0.0:
			is_blessed = false

	if target_position != Vector2.ZERO and global_position.distance_to(target_position) > 6.0:
		var speed = move_speed * (1.6 if is_blessed else 1.0)
		global_position = global_position.move_toward(target_position, speed * delta)
	else:
		_choose_next_behavior()

	if current_state == State.HUNTING:
		hunt_timer -= delta
		if hunt_timer <= 0.0:
			# Il lupo ha finito la caccia, porta cibo alla città
			if city_ref != null:
				city_ref.deposit_food(50.0) # Il lupo porta molta carne!
				wolf_action_performed.emit("Il Lupo Sacro ha portato della carne alla città affamata!")
				print("🐺 Il Lupo Sacro ha cacciato con successo (+50 cibo)!")
			current_state = State.WATCHING_TRIBE
			_choose_next_behavior()

	queue_redraw()


func _choose_next_behavior() -> void:
	if city_ref == null:
		return

	# Emergenza Cibo: Il lupo caccia per salvare la città
	if city_ref.stored_food < 20.0 and current_state != State.HUNTING:
		current_state = State.HUNTING
		hunt_timer = 5.0 # Impiega 5 secondi per cacciare
		# Va nel bosco a caso
		target_position = city_ref.global_position + Vector2(randf_range(-400, 400), randf_range(-400, 400))
		wolf_action_performed.emit("Il Lupo Sacro sente la fame dei fedeli e parte per la caccia.")
		return

	match current_state:
		State.WATCHING_TRIBE:
			current_state = State.PATROLLING_BORDER
			patrol_angle += randf_range(0.8, 1.6)
			var r = city_ref.influence_radius * 0.85
			target_position = city_ref.global_position + Vector2(cos(patrol_angle), sin(patrol_angle)) * r
			wolf_action_performed.emit("Il Lupo Sacro va a pattugliare i confini del territorio.")

		State.PATROLLING_BORDER:
			current_state = State.WATCHING_TRIBE
			target_position = city_ref.global_position + Vector2(randf_range(-60, 60), randf_range(40, 100))
			wolf_action_performed.emit("Il Lupo Sacro torna a vegliare accanto al Tempio.")


func advance_day(_day_number: int) -> void:
	xp += 10.0
	if xp >= float(level * 40):
		level += 1
		print("🐺 IL LUPO SACRO È SALITO DI LIVELLO! Livello attuale: ", level)

	if city_ref != null:
		if city_ref.expansion_mindset > 60.0:
			hunt_score += 4.0
		else:
			protect_score += 4.0

	var prev_nature = current_nature
	if protect_score >= hunt_score * 1.4:
		current_nature = Nature.PROTECTIVE_GUARDIAN
	elif hunt_score >= protect_score * 1.4:
		current_nature = Nature.FIERCE_BEAST
	else:
		current_nature = Nature.MYSTIC_GUIDE

	if prev_nature != current_nature:
		var nature_names = ["Guardiano Protettore", "Fiera Guerriera", "Guida Mistica"]
		nature_evolved.emit(nature_names[current_nature], level)
		print("🐺 L'INDOLE DEL LUPO SI È EVOLUTA: ", nature_names[current_nature])

	queue_redraw()


func apply_divine_blessing(duration := 15.0) -> void:
	is_blessed = true
	blessing_timer = duration
	xp += 25.0
	print("✨ BENEDIZIONE DIVINA CONCESSA AL LUPO SACRO! Aura e velocità potenziate!")
	queue_redraw()


func _draw() -> void:
	var aura_color: Color
	match current_nature:
		Nature.PROTECTIVE_GUARDIAN:
			aura_color = Color(0.3, 0.7, 1.0, 0.25)
		Nature.FIERCE_BEAST:
			aura_color = Color(1.0, 0.25, 0.2, 0.25)
		Nature.MYSTIC_GUIDE:
			aura_color = Color(0.8, 0.4, 1.0, 0.25)

	if is_blessed:
		aura_color = Color(1.0, 0.85, 0.2, 0.55)

	draw_circle(Vector2.ZERO, aura_radius, aura_color)
	draw_arc(Vector2.ZERO, aura_radius, 0.0, TAU, 32, Color(aura_color.r, aura_color.g, aura_color.b, 0.8), 2.0)

	var body_color := Color("#eceff1") if current_nature == Nature.PROTECTIVE_GUARDIAN else Color("#37474f")
	
	# Ombra
	draw_circle(Vector2(0, 6), 18.0, Color(0, 0, 0, 0.3))

	# Corpo principale
	draw_circle(Vector2.ZERO, 16.0, body_color)
	draw_circle(Vector2.ZERO, 16.0, body_color.darkened(0.4), false, 2.0)

	# Orecchie
	var ear_poly_left = PackedVector2Array([Vector2(-12, -12), Vector2(-6, -26), Vector2(0, -12)])
	var ear_poly_right = PackedVector2Array([Vector2(0, -12), Vector2(6, -26), Vector2(12, -12)])
	draw_colored_polygon(ear_poly_left, body_color)
	draw_colored_polygon(ear_poly_right, body_color)
	draw_polyline(ear_poly_left, body_color.darkened(0.4), 2.0)
	draw_polyline(ear_poly_right, body_color.darkened(0.4), 2.0)

	# Muso
	var snout_poly = PackedVector2Array([Vector2(-8, 8), Vector2(0, 18), Vector2(8, 8)])
	draw_colored_polygon(snout_poly, body_color.darkened(0.1))
	draw_polyline(snout_poly, body_color.darkened(0.5), 1.5)

	# Naso
	draw_circle(Vector2(0, 18), 3.0, Color("#1a1a1a"))

	# Occhi sacri
	var eye_color := Color("#00e5ff") if current_nature == Nature.PROTECTIVE_GUARDIAN else Color("#ff1744")
	draw_circle(Vector2(-6, -2), 3.0, eye_color)
	draw_circle(Vector2(6, -2), 3.0, eye_color)
	# Brillio occhio
	draw_circle(Vector2(-6, -2), 1.0, Color.WHITE)
	draw_circle(Vector2(6, -2), 1.0, Color.WHITE)
