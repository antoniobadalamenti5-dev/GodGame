class_name GameManager
extends Node2D

const CAMERA_SPEED := 750.0

@onready var camera: Camera2D = get_node_or_null("Camera2D")
@onready var time_system: TimeSystem = get_node_or_null("TimeSystem")
@onready var world: GameWorld = get_node_or_null("World")
@onready var city: City = get_node_or_null("World/City")
@onready var rival_city: City = get_node_or_null("World/RivalCity")
@onready var god_state: GodState = get_node_or_null("GodState")
@onready var diplomacy: DiplomacySystem = get_node_or_null("DiplomacySystem")
@onready var event_system: EventSystem = get_node_or_null("EventSystem")
@onready var wolf: SacredWolf = get_node_or_null("World/SacredWolf")
@onready var hud: GameHUD = get_node_or_null("UI")


func _ready() -> void:
	# BOOTSTRAP AUTOMATICO: se un nodo manca nella scena, viene istanziato automaticamente in codice!
	_auto_bootstrap_alpha_systems()
	
	if camera != null and world != null:
		camera.offset = Vector2.ZERO
		camera.position = city.global_position if city != null else world.map_size / 2.0

	# Connessione al ciclo temporale
	if time_system != null:
		if world != null:
			time_system.day_passed.connect(world.advance_day)
		if city != null:
			time_system.day_passed.connect(city.advance_day)
		if rival_city != null:
			time_system.day_passed.connect(rival_city.advance_day)
		if diplomacy != null and city != null and rival_city != null:
			time_system.day_passed.connect(func(_d): diplomacy.evaluate_daily_relations(city, rival_city))
		if event_system != null:
			time_system.day_passed.connect(event_system.advance_day)
		if wolf != null:
			wolf.city_ref = city
			time_system.day_passed.connect(wolf.advance_day)

	print("✨ GOD GAME 2D ALPHA INIZIALIZZATO: Tutti i sistemi sono operativi!")


func _auto_bootstrap_alpha_systems() -> void:
	# 1. World
	if world == null:
		world = GameWorld.new()
		world.name = "World"
		add_child(world)
		move_child(world, 0)

	# 2. Camera2D
	if camera == null:
		camera = Camera2D.new()
		camera.name = "Camera2D"
		add_child(camera)

	# 3. TimeSystem
	if time_system == null:
		time_system = TimeSystem.new()
		time_system.name = "TimeSystem"
		add_child(time_system)

	# 4. GodState
	if god_state == null:
		god_state = GodState.new()
		god_state.name = "GodState"
		add_child(god_state)

	# 5. DiplomacySystem
	if diplomacy == null:
		diplomacy = DiplomacySystem.new()
		diplomacy.name = "DiplomacySystem"
		add_child(diplomacy)

	# 6. EventSystem
	if event_system == null:
		event_system = EventSystem.new()
		event_system.name = "EventSystem"
		add_child(event_system)

	# 7. Player City (Aethelgard)
	if city == null:
		city = City.new()
		city.name = "City"
		city.city_name = "Aethelgard"
		city.faction_id = "player"
		city.position = Vector2(2048, 1280)
		world.add_child(city)

	# Tempio e MeetingPlace in Aethelgard
	if city.temple == null and city.get_node_or_null("Temple") == null:
		var temple = Temple.new()
		temple.name = "Temple"
		temple.position = Vector2(0, 80)
		city.add_child(temple)
		city.temple = temple

	if city.get_meeting_place() == null:
		var bonfire = Node2D.new()
		bonfire.name = "MeetingPlace"
		bonfire.position = Vector2(0, -90)
		city.add_child(bonfire)

	# Popolazione iniziale di Aethelgard se assente
	if city.get_node_or_null("Citizens") == null:
		var citizens_container = Node2D.new()
		citizens_container.name = "Citizens"
		city.add_child(citizens_container)
		for i in range(12):
			var c = Citizen.new()
			c.name = "Citizen_" + str(i + 1)
			c.position = Vector2(randf_range(-80, 80), randf_range(-80, 80))
			c.city = city
			c.time_system = time_system
			citizens_container.add_child(c)

	# 8. Rival City (Kael-Thar) - Fase 8
	if rival_city == null:
		rival_city = City.new()
		rival_city.name = "RivalCity"
		rival_city.city_name = "Kael-Thar"
		rival_city.faction_id = "rival"
		rival_city.position = Vector2(3150, 1750)
		rival_city.stored_food = 45.0
		rival_city.stored_wood = 40.0
		world.add_child(rival_city)

		var rival_bonfire = Node2D.new()
		rival_bonfire.name = "MeetingPlace"
		rival_bonfire.position = Vector2(0, -60)
		rival_city.add_child(rival_bonfire)

		var rival_citizens = Node2D.new()
		rival_citizens.name = "Citizens"
		rival_city.add_child(rival_citizens)
		for i in range(6):
			var rc = Citizen.new()
			rc.name = "RivalCitizen_" + str(i + 1)
			rc.position = Vector2(randf_range(-70, 70), randf_range(-70, 70))
			rc.city = rival_city
			rc.time_system = time_system
			rival_citizens.add_child(rc)

	# 9. Sacred Wolf (Lupo Sacro) - Fase 10
	if wolf == null:
		wolf = SacredWolf.new()
		wolf.name = "SacredWolf"
		wolf.position = Vector2(2150, 1350)
		wolf.city_ref = city
		world.add_child(wolf)

	# 10. UI CanvasLayer HUD
	if hud == null:
		hud = GameHUD.new()
		hud.name = "UI"
		add_child(hud)


func _process(delta: float) -> void:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if camera != null:
		camera.position += direction * CAMERA_SPEED * delta
		var half_viewport := get_viewport_rect().size / 2.0
		if world != null:
			camera.position = camera.position.clamp(half_viewport, world.map_size - half_viewport)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		# Tasto 1: Miracolo Pioggia della Vita (20 Fede)
		if event.keycode == KEY_1:
			trigger_miracle_rain()

		# Tasto 2: Miracolo Crescita Silvana (25 Fede)
		elif event.keycode == KEY_2:
			trigger_miracle_trees()

		# Tasto 3: Scatena Evento Mondiale (Siccità)
		elif event.keycode == KEY_3:
			trigger_event_drought()

		# Tasto 4: Benedizione Divina sul Lupo Sacro (15 Fede)
		elif event.keycode == KEY_4:
			trigger_wolf_blessing()


func trigger_miracle_rain() -> void:
	if god_state != null and god_state.spend_faith(20.0):
		if world != null:
			world.apply_rain_miracle()
		if hud != null:
			hud.show_toast("🌧️ MIRACOLO: Pioggia della Vita ricarica tutti i laghi e bacche!")


func trigger_miracle_trees() -> void:
	if god_state != null and god_state.spend_faith(25.0):
		if world != null:
			world.apply_tree_growth_miracle()
		if hud != null:
			hud.show_toast("🌲 MIRACOLO: Crescita Silvana rigenera tutti gli alberi!")


func trigger_event_drought() -> void:
	if event_system != null:
		event_system.trigger_event(EventSystem.EventType.DROUGHT, 3)
		if hud != null:
			hud.show_toast("☀️ EVENTO: Siccità Implacabile scatenata per 3 giorni!")


func trigger_wolf_blessing() -> void:
	if wolf != null and god_state != null and god_state.spend_faith(15.0):
		wolf.apply_divine_blessing()
		if hud != null:
			hud.show_toast("🐺 BENEDIZIONE DIVINA: Il Lupo Sacro risplende d'oro e accelera!")
