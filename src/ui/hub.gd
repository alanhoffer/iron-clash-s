extends Control

const GameConfig: Script = preload("res://src/config/game_config.gd")

@onready var api: Node = $ApiClient

@onready var backend_status: Label = %BackendStatus
@onready var housing_grid: Control = %HousingGrid
@onready var editor_ui: Control = %EditorUI
@onready var inventory_bar: Control = $Root/Content/HouseArea/House/EditorUI/InventoryBar
@onready var character_button: Button = $Root/Content/HouseArea/House/CharacterButton

@onready var character_panel: PanelContainer = %CharacterPanel
@onready var replay_panel: PanelContainer = %ReplayPanel

@onready var stats_label: RichTextLabel = %StatsLabel
@onready var seed_edit: LineEdit = %SeedEdit
@onready var fight_button: Button = $Root/Content/Panels/CharacterPanel/CharacterPanelMargin/CharacterPanelVBox/FightRow/Fight
@onready var log_label: RichTextLabel = %Log
@onready var a_hp: ProgressBar = %AHP
@onready var b_hp: ProgressBar = %BHP

var _base_url: String = "http://127.0.0.1:8000"

var _fighter_a := {
	"id": "player_1",
	"name": "Ares (placeholder)",
	"stats": {"hp": 120, "atk": 24, "dfn": 10, "spd": 18, "crit": 0.20, "eva": 0.08, "block": 0.10},
}

var _fighter_b := {
	"id": "bot_1",
	"name": "Shade (placeholder)",
	"stats": {"hp": 105, "atk": 20, "dfn": 12, "spd": 16, "crit": 0.15, "eva": 0.10, "block": 0.12},
}

func _ready() -> void:
	# Config (dev).
	_base_url = GameConfig.BACKEND_BASE_URL as String

	api.health_checked.connect(_on_health_checked)
	api.combat_simulated.connect(_on_combat_simulated)
	api.request_failed.connect(_on_request_failed)

	_refresh_stats_ui()
	backend_status.text = "Backend: checking… (%s)" % _base_url
	api.check_health(_base_url)
	
	housing_grid.gui_input.connect(_on_house_gui_input)
	
	_setup_inventory_icons()

func _on_house_gui_input(event: InputEvent) -> void:
	if housing_grid.is_editing or _dragging_type != "":
		return
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_move_character_to_mouse()

func _setup_inventory_icons() -> void:
	var hbox = inventory_bar.get_node("HBox")
	
	_set_btn_icon(hbox.get_node("ItemChair"), "chair.png")
	_set_btn_icon(hbox.get_node("ItemPic"), "reloj.png")
	
	_set_btn_icon(hbox.get_node("Wall1"), "wall_1.png")
	_set_btn_icon(hbox.get_node("Wall2"), "wall_2.png")
	
	_set_btn_icon(hbox.get_node("Floor1"), "floor_1.png")
	_set_btn_icon(hbox.get_node("Floor2"), "floor_2.png")
	_set_btn_icon(hbox.get_node("Floor3"), "floor_3.png")

func _set_btn_icon(btn: Button, icon_name: String) -> void:
	if not btn: return
	btn.text = ""
	btn.icon = load("res://assets/sprites/" + icon_name)
	btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.expand_icon = true
	# Hacer que el icono ocupe casi todo el boton
	btn.custom_minimum_size = Vector2(80, 80)

func _refresh_stats_ui() -> void:
	var s: Dictionary = _fighter_a["stats"]
	stats_label.text = (
		"[b]Stats[/b]\n"
		+ "HP: %s\n" % str(s["hp"])
		+ "ATK: %s\n" % str(s["atk"])
		+ "DEF: %s\n" % str(s["dfn"])
		+ "SPD: %s\n" % str(s["spd"])
		+ "CRIT: %s\n" % str(s["crit"])
		+ "EVA: %s\n" % str(s["eva"])
		+ "BLOCK: %s\n" % str(s["block"])
	)

func _on_character_pressed() -> void:
	replay_panel.visible = false
	character_panel.visible = true

func _on_char_close_pressed() -> void:
	character_panel.visible = false

func _on_replay_close_pressed() -> void:
	replay_panel.visible = false

func _on_fight_pressed() -> void:
	fight_button.disabled = true
	character_panel.visible = false
	replay_panel.visible = true

	log_label.text = "[i]Simulando combate en servidor…[/i]"

	var combat_seed := int(seed_edit.text) if seed_edit.text.is_valid_int() else 1

	var payload := {
		"seed": combat_seed,
		"a": _fighter_a,
		"b": _fighter_b,
		"max_events": 250,
	}
	api.simulate_combat(_base_url, payload)

func _on_health_checked(ok: bool) -> void:
	backend_status.text = "Backend: %s (%s)" % ["OK" if ok else "OFF", _base_url]

func _on_request_failed(message: String) -> void:
	fight_button.disabled = false
	backend_status.text = "Backend: error"
	log_label.text = "[b]Error[/b]\n%s" % message

func _on_combat_simulated(replay: Dictionary) -> void:
	fight_button.disabled = false
	var events: Array = replay.get("events", [])
	var winner_id: String = replay.get("winner_id", "?")
	var final: Dictionary = replay.get("final", {})

	var a_final: Dictionary = final.get("a", {}) as Dictionary
	var b_final: Dictionary = final.get("b", {}) as Dictionary

	var a_hp_val := float(a_final.get("hp", _fighter_a["stats"]["hp"]))
	var b_hp_val := float(b_final.get("hp", _fighter_b["stats"]["hp"]))

	a_hp.max_value = float(_fighter_a["stats"]["hp"])
	b_hp.max_value = float(_fighter_b["stats"]["hp"])
	a_hp.value = a_hp_val
	b_hp.value = b_hp_val

	var sb := PackedStringArray()
	sb.append("[b]Winner:[/b] %s\n" % winner_id)
	sb.append("[b]Replay events:[/b]\n")

	for e in events:
		if typeof(e) != TYPE_DICTIONARY:
			continue
		var typ := str(e.get("type", ""))
		var data: Dictionary = e.get("data", {}) as Dictionary

		if typ == "attack":
			sb.append("- %s attacks %s\n" % [str(data.get("attacker_id", "?")), str(data.get("target_id", "?"))])
		elif typ == "result":
			var msg := str(data.get("msg", ""))
			if msg == "start":
				sb.append("- start\n")
			elif msg == "dodge":
				sb.append("  - dodge (%s)\n" % str(data.get("target_id", "?")))
			elif msg == "hit":
				sb.append(
					"  - hit dmg=%s crit=%s block=%s target_hp=%s\n"
					% [
						str(data.get("dmg", "?")),
						str(data.get("crit", false)),
						str(data.get("blocked", false)),
						str(data.get("target_hp", "?")),
					]
				)
			else:
				sb.append("- %s\n" % msg)
		elif typ == "end":
			sb.append("- end\n")

	log_label.text = "".join(sb)

var _dragging_type: String = ""
var _drag_preview: Control = null
var _char_tween: Tween

func _process(delta: float) -> void:
	if _drag_preview and is_instance_valid(_drag_preview):
		_drag_preview.global_position = get_global_mouse_position() - (_drag_preview.size / 2.0)
	
	_update_camera(delta)

func _update_camera(delta: float) -> void:
	var house_area = $Root/Content/HouseArea
	var house = $Root/Content/HouseArea/House
	
	if not house_area or not house: return

	var viewport_w = house_area.size.x
	var char_center_x = character_button.position.x + character_button.size.x / 2
	var target_house_x = (viewport_w / 2.0) - char_center_x
	
	var min_x = viewport_w - house.custom_minimum_size.x
	var max_x = 0.0
	
	if min_x > 0:
		target_house_x = (viewport_w - house.custom_minimum_size.x) / 2.0
	else:
		target_house_x = clamp(target_house_x, min_x, max_x)
		
	house.position.x = lerp(house.position.x, target_house_x, delta * 5.0)

func _input(event: InputEvent) -> void:
	if _dragging_type != "":
		if event is InputEventMouseButton:
			if not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_place_item()
			elif event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
				_cancel_drag()
		# Consumir input mientras arrastramos
		get_viewport().set_input_as_handled()
		return

func _move_character_to_mouse() -> void:
	var house = $Root/Content/HouseArea/House
	var local_mouse = house.get_local_mouse_position()
	
	# Clamp dentro de la casa
	var target_x = local_mouse.x - character_button.size.x / 2
	target_x = clamp(target_x, 0, house.custom_minimum_size.x - character_button.size.x)
	
	var sprite = character_button.get_node("CharacterBody")
	# Flip simple
	if target_x < character_button.position.x:
		sprite.flip_h = true
	else:
		sprite.flip_h = false
		
	var dist = abs(target_x - character_button.position.x)
	if dist > 10.0:
		if _char_tween: _char_tween.kill()
		_char_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		# Velocidad: 400px/s
		_char_tween.tween_property(character_button, "position:x", target_x, dist / 400.0)


func _place_item() -> void:
	if not housing_grid: return
	
	# Lógica para consumibles (Pintura/Suelo)
	if _dragging_type.begins_with("wall_"):
		var wall = housing_grid.get_node("BackgroundWall")
		if wall:
			wall.texture = load("res://assets/sprites/%s.png" % _dragging_type)
		_cancel_drag()
		return
		
	elif _dragging_type.begins_with("floor_"):
		var fl = housing_grid.get_node("BackgroundFloor")
		if fl:
			fl.texture = load("res://assets/sprites/%s.png" % _dragging_type)
		_cancel_drag()
		return

	# Lógica para Muebles
	var item := TextureRect.new()
	# Permitir clicks futuros
	item.mouse_filter = Control.MOUSE_FILTER_STOP
	item.set_meta("type", _dragging_type)
	item.gui_input.connect(_on_placed_item_input.bind(item))
	
	item.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	item.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	var mouse_pos_local := housing_grid.get_local_mouse_position()
	
	if _dragging_type == "chair":
		item.texture = load("res://assets/sprites/chair.png")
		item.size = Vector2(160, 240)
		
		housing_grid.get_node("FloorLayer").add_child(item)
		
		# Animación: Caída con rebote + Pop de escala
		# Empezamos en la posición del mouse
		item.position = Vector2(mouse_pos_local.x - 80, mouse_pos_local.y - 120)
		item.scale = Vector2(0.5, 0.5)
		item.pivot_offset = item.size / 2 # Pivot al centro para escalar bien
		
	# Meta Y (Suelo - altura)
		# Piso visual empieza en -150. Queremos que pisen cerca del borde inferior del piso.
		# Ajuste a ojo: size.y - 40
		var floor_y := housing_grid.size.y - 40
		var target_y := floor_y - 240
		
		var tween = create_tween().set_parallel(true)
		tween.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		tween.tween_property(item, "position:y", target_y, 0.8)
		
		tween.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(item, "scale", Vector2(1, 1), 0.6)
		
	elif _dragging_type == "pic":
		item.texture = load("res://assets/sprites/reloj.png")
		item.size = Vector2(120, 120)
		item.pivot_offset = item.size / 2
		item.position = mouse_pos_local - Vector2(60, 60)
		item.scale = Vector2(0.1, 0.1)
		
		# Añadir a capa de pared
		housing_grid.get_node("WallLayer").add_child(item)
		
		# Animación: Pop simple
		var tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(item, "scale", Vector2(1, 1), 0.5)
	
	_cancel_drag()


func _cancel_drag() -> void:
	# Reactivar input del personaje
	character_button.mouse_filter = Control.MOUSE_FILTER_STOP
	# Mostrar inventario de nuevo
	inventory_bar.visible = true

	_dragging_type = ""
	if _drag_preview:
		_drag_preview.queue_free()
		_drag_preview = null

func _on_placed_item_input(event: InputEvent, item: Control) -> void:
	if not housing_grid.is_editing:
		return
	if _dragging_type != "":
		return # Ya estamos arrastrando algo
		
	# Pickup: Al apretar click sobre un item colocado
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var type = item.get_meta("type", "") as String
		if type != "":
			item.queue_free()
			_start_drag(type)
			# Consumir el evento para que no propague
			get_viewport().set_input_as_handled()

func _on_edit_button_toggled() -> void:
	var btn: Button = $Root/TopBar/EditButton
	editor_ui.visible = btn.button_pressed
	housing_grid.is_editing = btn.button_pressed

func _on_item_chair_button_down() -> void:
	_start_drag("chair")

func _on_item_pic_button_down() -> void:
	_start_drag("pic")

func _on_wall1_down() -> void:
	_start_drag("wall_1")

func _on_wall2_down() -> void:
	_start_drag("wall_2")

func _on_floor1_down() -> void:
	_start_drag("floor_1")

func _on_floor2_down() -> void:
	_start_drag("floor_2")

func _on_floor3_down() -> void:
	_start_drag("floor_3")

func _start_drag(type: String) -> void:
	# Desactivar input del personaje para que no bloquee el drop
	character_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Ocultar inventario para ver el piso
	inventory_bar.visible = false
	
	if _drag_preview:
		_drag_preview.queue_free()
	
	_dragging_type = type
	_drag_preview = TextureRect.new()
	_drag_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_drag_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_drag_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_drag_preview.modulate = Color(1, 1, 1, 0.7) # Semi-transparente
	
	if type == "chair":
		_drag_preview.texture = load("res://assets/sprites/chair.png")
		_drag_preview.size = Vector2(160, 240)
		# Feedback visual al arrastrar: un poco más grande
		_drag_preview.scale = Vector2(1.1, 1.1)
		
	elif type == "pic":
		_drag_preview.texture = load("res://assets/sprites/reloj.png")
		_drag_preview.size = Vector2(120, 120)
		_drag_preview.scale = Vector2(1.1, 1.1)
		
	elif type.begins_with("wall_") or type.begins_with("floor_"):
		# Preview: un cuadrado con la textura
		_drag_preview.texture = load("res://assets/sprites/%s.png" % type)
		_drag_preview.size = Vector2(64, 64)
		_drag_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_drag_preview.stretch_mode = TextureRect.STRETCH_SCALE
	
	if is_instance_valid(_drag_preview) and not _drag_preview.is_inside_tree():
		add_child(_drag_preview)
