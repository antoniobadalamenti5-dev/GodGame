class_name GameHUD
extends CanvasLayer

var god_state: GodState
var time_system: TimeSystem
var event_system: EventSystem
var diplomacy_system: DiplomacySystem
var wolf_ref: SacredWolf
var game_manager: GameManager

# Riferimenti UI dinamici
var faith_label: Label
var faith_bar: ProgressBar
var day_label: Label
var diplomacy_label: Label
var event_banner: PanelContainer
var event_label: Label
var toast_panel: PanelContainer
var toast_label: Label
var toast_timer := 0.0

var btn_rain: Button
var btn_trees: Button
var btn_event: Button
var btn_wolf: Button


func _ready() -> void:
	_resolve_dependencies()
	_build_ui_layout()
	_connect_signals()


func _resolve_dependencies() -> void:
	var root = get_parent()
	if root is GameManager:
		game_manager = root
	god_state = root.get_node_or_null("GodState")
	time_system = root.get_node_or_null("TimeSystem")
	event_system = root.get_node_or_null("EventSystem")
	diplomacy_system = root.get_node_or_null("DiplomacySystem")
	wolf_ref = root.get_node_or_null("World/SacredWolf")


func _build_ui_layout() -> void:
	# Root Control Fullscreen
	var control = Control.new()
	control.set_anchors_preset(Control.PRESET_FULL_RECT)
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(control)

	# --- 1. TOP BAR CONTAINER ---
	var top_panel = PanelContainer.new()
	top_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_panel.position = Vector2(16, 16)
	top_panel.size = Vector2(1248, 56)
	control.add_child(top_panel)

	var top_hbox = HBoxContainer.new()
	top_hbox.add_theme_constant_override("separation", 16)
	top_panel.add_child(top_hbox)

	# Giorno
	day_label = Label.new()
	day_label.text = "☀️ Giorno 1"
	day_label.add_theme_font_size_override("font_size", 16)
	top_hbox.add_child(day_label)

	# Spazio
	var spacer1 = Control.new()
	spacer1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(spacer1)

	# Fede Divina
	var faith_box = HBoxContainer.new()
	faith_box.add_theme_constant_override("separation", 8)
	top_hbox.add_child(faith_box)

	faith_label = Label.new()
	faith_label.text = "⚡ Fede: 30 / 100"
	faith_label.add_theme_color_override("font_color", Color("#fbbf24"))
	faith_box.add_child(faith_label)

	faith_bar = ProgressBar.new()
	faith_bar.custom_minimum_size = Vector2(160, 20)
	faith_bar.max_value = 100.0
	faith_bar.value = 30.0
	faith_bar.show_percentage = false
	faith_box.add_child(faith_bar)

	# Spazio
	var spacer2 = Control.new()
	spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(spacer2)

	# Diplomazia con Kael-Thar
	diplomacy_label = Label.new()
	diplomacy_label.text = "🏰 Kael-Thar: Neutrale (15)"
	diplomacy_label.add_theme_color_override("font_color", Color("#fdba74"))
	top_hbox.add_child(diplomacy_label)

	# --- 2. BANNER EVENTO ATTIVO ---
	event_banner = PanelContainer.new()
	event_banner.position = Vector2(400, 80)
	event_banner.size = Vector2(480, 36)
	event_banner.visible = false
	control.add_child(event_banner)

	event_label = Label.new()
	event_label.text = "🌪️ Nessun Evento"
	event_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	event_banner.add_child(event_label)

	# --- 3. TOAST NOTIFICATION ---
	toast_panel = PanelContainer.new()
	toast_panel.position = Vector2(340, 130)
	toast_panel.size = Vector2(600, 44)
	toast_panel.visible = false
	control.add_child(toast_panel)

	toast_label = Label.new()
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.add_theme_color_override("font_color", Color("#fef08a"))
	toast_panel.add_child(toast_label)

	# --- 4. BOTTOM BAR CON PULSANTI MIRACOLO ---
	var bottom_panel = PanelContainer.new()
	bottom_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_panel.position = Vector2(16, 640)
	bottom_panel.size = Vector2(1248, 64)
	control.add_child(bottom_panel)

	var bottom_hbox = HBoxContainer.new()
	bottom_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_hbox.add_theme_constant_override("separation", 14)
	bottom_panel.add_child(bottom_hbox)

	btn_rain = Button.new()
	btn_rain.text = "[1] 🌧️ Pioggia della Vita (20 Fede)"
	btn_rain.pressed.connect(_on_rain_clicked)
	bottom_hbox.add_child(btn_rain)

	btn_trees = Button.new()
	btn_trees.text = "[2] 🌲 Crescita Silvana (25 Fede)"
	btn_trees.pressed.connect(_on_trees_clicked)
	bottom_hbox.add_child(btn_trees)

	btn_event = Button.new()
	btn_event.text = "[3] 🌪️ Scatena Siccità"
	btn_event.pressed.connect(_on_event_clicked)
	bottom_hbox.add_child(btn_event)

	btn_wolf = Button.new()
	btn_wolf.text = "[4] ✨ Benedici Lupo (15 Fede)"
	btn_wolf.pressed.connect(_on_wolf_clicked)
	bottom_hbox.add_child(btn_wolf)


func _connect_signals() -> void:
	if god_state != null:
		god_state.faith_changed.connect(_on_faith_changed)
		_on_faith_changed(god_state.current_faith, god_state.max_faith)

	if time_system != null:
		time_system.day_passed.connect(_on_day_passed)

	if diplomacy_system != null:
		diplomacy_system.relation_changed.connect(_on_relation_changed)

	if event_system != null:
		event_system.event_started.connect(_on_event_started)
		event_system.event_ended.connect(_on_event_ended)


func _process(delta: float) -> void:
	if toast_timer > 0.0:
		toast_timer -= delta
		if toast_timer <= 0.0:
			toast_panel.visible = false


func show_toast(text: String, duration := 3.5) -> void:
	toast_label.text = text
	toast_panel.visible = true
	toast_timer = duration


func _on_faith_changed(current: float, max_val: float) -> void:
	faith_label.text = "⚡ Fede: %d / %d" % [int(current), int(max_val)]
	faith_bar.value = current
	btn_rain.disabled = current < 20.0
	btn_trees.disabled = current < 25.0
	btn_wolf.disabled = current < 15.0


func _on_day_passed(day: int) -> void:
	day_label.text = "☀️ Giorno %d" % day


func _on_relation_changed(score: float, status_name: String) -> void:
	diplomacy_label.text = "🏰 Kael-Thar: %s (%d)" % [status_name, int(score)]


func _on_event_started(_type: int, event_name: String, days: int, _desc: String) -> void:
	event_banner.visible = true
	event_label.text = "🌪️ %s (%d giorni rimasti)" % [event_name, days]


func _on_event_ended(_name: String) -> void:
	event_banner.visible = false


func _on_rain_clicked() -> void:
	if game_manager != null:
		game_manager.trigger_miracle_rain()


func _on_trees_clicked() -> void:
	if game_manager != null:
		game_manager.trigger_miracle_trees()


func _on_event_clicked() -> void:
	if game_manager != null:
		game_manager.trigger_event_drought()


func _on_wolf_clicked() -> void:
	if game_manager != null:
		game_manager.trigger_wolf_blessing()
