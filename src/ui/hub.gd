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
	_reparent_inventory_to_root()
	_enhance_inventory_ui() # New styling + Filters + Toggle
	_create_currency_hud()
	_create_settings_button() # Add settings btn
	_create_left_sidebar() # Edit + Shop buttons
	_load_defaults()

	# Start with inventory hidden
	if editor_ui: editor_ui.visible = false
	if inventory_bar: inventory_bar.visible = false

# --- SIDEBAR & SHOP ---
var _in_shop_mode: bool = false

func _create_left_sidebar() -> void:
	# Check if Sidebar exists anywhere
	if has_node("HUDLayer/LeftSidebar"): return
	
	# Create a CanvasLayer to ensure UI floats above everything and doesn't move
	var hud_layer = CanvasLayer.new()
	hud_layer.name = "HUDLayer"
	add_child(hud_layer)
	
	# Container fixed to left inside CanvasLayer
	var sidebar = VBoxContainer.new()
	sidebar.name = "LeftSidebar"
	# Manual positioning to be 100% sure
	sidebar.position = Vector2(20, 100) 
	sidebar.custom_minimum_size = Vector2(100, 300)
	sidebar.add_theme_constant_override("separation", 20)
	
	hud_layer.add_child(sidebar)
	
	# Move Edit Button here
	# Note: We need to reparent carefully.
	var old_edit_btn = find_child("EditButton", true, false)
	if old_edit_btn:
		old_edit_btn.get_parent().remove_child(old_edit_btn)
		sidebar.add_child(old_edit_btn)
		# Style it bigger
		old_edit_btn.custom_minimum_size = Vector2(90, 90)
		old_edit_btn.text = "EDIT\nHOUSE"
	
	# Shop Button
	var shop_btn = Button.new()
	shop_btn.name = "ShopBtn" # Name it to find it later
	shop_btn.text = "SHOP"
	shop_btn.custom_minimum_size = Vector2(80, 80)
	shop_btn.pressed.connect(_on_shop_toggle)
	sidebar.add_child(shop_btn)

func _on_shop_toggle() -> void:
	if _in_shop_mode:
		_return_to_home()
	else:
		_go_to_shop()

func _return_to_home() -> void:
	_in_shop_mode = false
	
	# Teleport Player Character back to House
	if character_button and character_button.get_parent():
		character_button.get_parent().remove_child(character_button)
		var house = $Root/Content/HouseArea/House
		house.add_child(character_button)
		# Reset position to default (center-ish)
		character_button.position = Vector2(600, 0) # Default position from Hub.tscn
	
	# Slide Camera back to 0
	var tw = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property($Root/Content, "position:x", 0.0, 1.2)
	
	# Update Button Text
	if has_node("HUDLayer/LeftSidebar/ShopBtn"):
		get_node("HUDLayer/LeftSidebar/ShopBtn").text = "SHOP"
		
	# Re-enable Edit Button
	if has_node("HUDLayer/LeftSidebar/EditButton"):
		get_node("HUDLayer/LeftSidebar/EditButton").disabled = false

func _go_to_shop() -> void:
	_in_shop_mode = true
	
	# Close Edit Mode if active
	if housing_grid.is_editing:
		var edit_btn = get_node_or_null("HUDLayer/LeftSidebar/EditButton")
		if edit_btn: 
			edit_btn.button_pressed = false
			# Manually call logic
			_on_edit_button_toggled()
	
	# Disable Edit Button while in Shop (can't edit shop)
	if has_node("HUDLayer/LeftSidebar/EditButton"):
		get_node("HUDLayer/LeftSidebar/EditButton").disabled = true
	
	# Update Button Text
	if has_node("HUDLayer/LeftSidebar/ShopBtn"):
		get_node("HUDLayer/LeftSidebar/ShopBtn").text = "HOME"
	
	_transition_to_shop_room()

func _transition_to_shop_room() -> void:
	# 1. Create Shop Room if not exists
	var shop_root: Control
	if has_node("Root/Content/ShopArea"):
		shop_root = get_node("Root/Content/ShopArea")
	else:
		# Get parent size to match it
		var content = $Root/Content
		var parent_size = content.size
		if parent_size == Vector2.ZERO or parent_size.y < 100:
			# Fallback if size not ready - use viewport
			var vp_size = get_viewport_rect().size
			parent_size = Vector2(2500, vp_size.y)
		
		shop_root = Control.new()
		shop_root.name = "ShopArea"
		# Match House size: 2500px wide, full height
		shop_root.custom_minimum_size = Vector2(2500, parent_size.y)
		shop_root.size = Vector2(2500, parent_size.y)
		shop_root.position = Vector2(2500, 0) # Far right
		
		# Add Background Wall (use absolute positioning first, then anchors)
		var bg_wall = TextureRect.new()
		bg_wall.name = "BackgroundWall"
		bg_wall.texture = load("res://assets/sprites/wall_3.png")
		bg_wall.texture_repeat = TextureRect.TEXTURE_REPEAT_ENABLED
		bg_wall.position = Vector2(0, 0)
		bg_wall.size = Vector2(2500, parent_size.y - 100) # Leave 100px at bottom
		bg_wall.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg_wall.stretch_mode = TextureRect.STRETCH_TILE
		shop_root.add_child(bg_wall)
		
		# Add Floor (absolute positioning)
		var bg_floor = TextureRect.new()
		bg_floor.name = "BackgroundFloor"
		bg_floor.texture = load("res://assets/sprites/floor_3.png")
		bg_floor.texture_repeat = TextureRect.TEXTURE_REPEAT_ENABLED
		bg_floor.position = Vector2(0, parent_size.y - 150) # 150px from bottom
		bg_floor.size = Vector2(2500, 150) # 150px height
		bg_floor.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg_floor.stretch_mode = TextureRect.STRETCH_TILE
		shop_root.add_child(bg_floor)
		
		# Calculate floor top position for items
		var floor_y = parent_size.y - 150.0
		
		# NPC (Merchant) - Center Screen, standing on floor
		var npc = TextureRect.new()
		npc.name = "MerchantNPC"
		var npc_texture = load("res://assets/sprites/character.png")
		if not npc_texture:
			print("ERROR: Could not load character.png for NPC")
		npc.texture = npc_texture
		npc.flip_h = true # Face left towards arriving player
		# Position: center X, standing on floor
		# Use same size as character_button (240x370 from Hub.tscn)
		npc.position = Vector2(1200, floor_y - 370) # Center X, on floor
		npc.size = Vector2(240, 370) # Match character button size
		npc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		npc.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		shop_root.add_child(npc)
		
		# Debug: Print NPC info
		print("NPC created at: ", npc.position, " size: ", npc.size, " floor_y: ", floor_y)
		
		# Shop Title
		var title = Label.new()
		title.text = "MERCHANT"
		title.add_theme_font_size_override("font_size", 60)
		title.position = Vector2(1000, 50) # Top center
		shop_root.add_child(title)
		
		# Add Physical Items on floor
		_spawn_shop_item_physical(shop_root, "chair.png", 500, Vector2(700, floor_y - 240))
		_spawn_shop_item_physical(shop_root, "reloj.png", 150, Vector2(1400, floor_y - 400))
		_spawn_shop_item_physical(shop_root, "wall_3.png", 1000, Vector2(500, floor_y - 200))
		
		$Root/Content.add_child(shop_root)

	# 2. Teleport Player Character to Shop
	if character_button and character_button.get_parent():
		character_button.get_parent().remove_child(character_button)
		shop_root.add_child(character_button)
		# Position character at entrance (left side of shop)
		# Ensure character keeps its size from Hub.tscn (240x370)
		if character_button.size == Vector2.ZERO:
			character_button.size = Vector2(240, 370)
		var floor_y = shop_root.size.y - 150.0
		# Position on floor (same calculation as house: floor_y - character_height)
		character_button.position = Vector2(200, floor_y - 370) # Left side, on floor
	
	# 3. Move Camera to Shop
	var tw = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	# Slide Content to show Shop (at x=2500)
	# If House is at 0, Shop at 2500. Target Content.x = -2500.
	tw.tween_property($Root/Content, "position:x", -2500.0, 1.5)

func _spawn_shop_item_physical(parent: Control, icon: String, price: int, pos: Vector2) -> void:
	var cont = VBoxContainer.new()
	cont.position = pos
	# Center elements
	cont.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var tex = TextureRect.new()
	tex.texture = load("res://assets/sprites/" + icon)
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.custom_minimum_size = Vector2(150, 150) # Bigger icons
	cont.add_child(tex)
	
	var btn = Button.new()
	btn.text = "%s Coins" % price
	btn.custom_minimum_size = Vector2(120, 40)
	btn.pressed.connect(func(): print("Bought %s" % icon))
	cont.add_child(btn)
	
	parent.add_child(cont)

# --- INVENTORY & UI ---

func _enhance_inventory_ui() -> void:
	if not inventory_bar: return
	
	# 1. Aesthetics (Dark theme + Gold border)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.10, 0.95) # Dark Hades-like
	style.border_width_top = 2
	style.border_color = Color(0.6, 0.5, 0.3) # Goldish
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	inventory_bar.add_theme_stylebox_override("panel", style)
	
	# 2. Toggle Button (Minimize/Expand)
	var toggle_btn = Button.new()
	toggle_btn.text = "▼" # Down arrow
	toggle_btn.name = "ToggleBtn"
	toggle_btn.custom_minimum_size = Vector2(40, 24)
	toggle_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	toggle_btn.position = Vector2((inventory_bar.size.x - 40) / 2, -24)
	# Important: Add to InventoryBar so it moves with it
	inventory_bar.add_child(toggle_btn)
	toggle_btn.pressed.connect(_on_inventory_toggle_pressed.bind(toggle_btn))
	
	# 3. Structure for Filters (VBox)
	var items_hbox = inventory_bar.get_node_or_null("HBox")
	if not items_hbox: return
	
	# Create Main VBox
	var vbox = VBoxContainer.new()
	vbox.name = "InventoryVBox"
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	inventory_bar.add_child(vbox)
	
	# Create Filter Bar
	var filters_hbox = HBoxContainer.new()
	filters_hbox.name = "FiltersHBox"
	filters_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	filters_hbox.add_theme_constant_override("separation", 15)
	vbox.add_child(filters_hbox)
	
	# Move Items HBox into VBox
	items_hbox.get_parent().remove_child(items_hbox)
	vbox.add_child(items_hbox)
	items_hbox.alignment = BoxContainer.ALIGNMENT_CENTER # Center items too
	
	# 4. Create Filter Buttons
	var categories = ["All", "Furniture", "Structure"]
	for cat in categories:
		var btn = Button.new()
		btn.text = cat
		btn.toggle_mode = true
		if cat == "All": btn.button_pressed = true
		
		# Simple Button Style
		btn.custom_minimum_size = Vector2(100, 30)
		btn.pressed.connect(_on_filter_pressed.bind(cat, filters_hbox))
		filters_hbox.add_child(btn)

var _inventory_open: bool = true

func _on_inventory_toggle_pressed(btn: Button) -> void:
	_inventory_open = not _inventory_open
	
	var target_y: float
	var parent_h = inventory_bar.get_parent().size.y
	
	if _inventory_open:
		# Expand: anchor bottom with margin
		target_y = parent_h - inventory_bar.size.y - 20
		btn.text = "▼"
	else:
		# Collapse: hide below screen, leaving only the button visible?
		# Or just stick the top border at the bottom
		target_y = parent_h - 2 # Almost hidden
		btn.text = "▲" # Up arrow
	
	var tw = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(inventory_bar, "position:y", target_y, 0.3)

func _on_filter_pressed(category: String, filter_container: HBoxContainer) -> void:
	# Untoggle others (Radio behavior)
	for btn in filter_container.get_children():
		if btn is Button:
			btn.set_pressed_no_signal(btn.text == category)
	
	# Filter Logic
	var items_hbox = inventory_bar.get_node("InventoryVBox/HBox")
	if not items_hbox: return
	
	for child in items_hbox.get_children():
		if not child is Button: continue
		
		var type = child.get_meta("category", "misc")
		
		if category == "All":
			child.visible = true
		elif category == "Furniture":
			child.visible = (type == "furniture")
		elif category == "Structure":
			child.visible = (type == "structure")

func _create_currency_hud() -> void:
	# Check if TopBar exists
	if not has_node("Root/TopBar"): return
	
	var top_bar = get_node("Root/TopBar")
	
	# Create HUD container
	var hud = HBoxContainer.new()
	hud.name = "CurrencyHUD"
	hud.add_theme_constant_override("separation", 20)
	
	# Add spacer to push HUD to left (if TopBar is HBox)
	# But TopBar usually has Title centered. Let's just insert at index 0
	top_bar.add_child(hud)
	top_bar.move_child(hud, 0) # Leftmost
	
	# Coins (Soft)
	var coins_box = _create_currency_item("Coins: 1,500", Color(1, 0.9, 0.4))
	hud.add_child(coins_box)
	
	# Gems (Hard) - Aura Gems
	var gems_box = _create_currency_item("Aura Gems: 50", Color(0.8, 0.4, 1.0))
	hud.add_child(gems_box)

func _create_currency_item(text: String, color: Color) -> PanelContainer:
	var p = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.5)
	style.set_corner_radius_all(4)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	p.add_theme_stylebox_override("panel", style)
	
	var lbl = Label.new()
	lbl.text = text
	lbl.modulate = color
	lbl.add_theme_font_size_override("font_size", 16)
	p.add_child(lbl)
	return p

func _create_settings_button() -> void:
	if not has_node("Root/TopBar"): return
	var top_bar = get_node("Root/TopBar")
	
	# Try to find a right-aligned container or add one
	var right_container = top_bar.get_node_or_null("RightContainer")
	if not right_container:
		right_container = HBoxContainer.new()
		right_container.name = "RightContainer"
		right_container.alignment = BoxContainer.ALIGNMENT_END
		# Push to right using size flags
		right_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top_bar.add_child(right_container)
	
	var btn = Button.new()
	btn.text = "⚙" # Settings Icon Placeholder
	btn.add_theme_font_size_override("font_size", 20)
	btn.custom_minimum_size = Vector2(40, 40)
	
	btn.pressed.connect(func(): print("Open Settings Menu"))
	
	right_container.add_child(btn)

func _load_defaults() -> void:
	if housing_grid.has_node("BackgroundWall"):
		var w = housing_grid.get_node("BackgroundWall")
		var tex = load("res://assets/sprites/wall_3.png")
		if tex: w.texture = tex
	
	if housing_grid.has_node("BackgroundFloor"):
		var f = housing_grid.get_node("BackgroundFloor")
		var tex = load("res://assets/sprites/floor_3.png")
		if tex: f.texture = tex

func _reparent_inventory_to_root() -> void:
	# Move InventoryBar to $Root/Content so it stays fixed on screen (HUD)
	# instead of moving with the House/Camera inside HouseArea.
	if inventory_bar and inventory_bar.get_parent():
		inventory_bar.get_parent().remove_child(inventory_bar)
		var content = $Root/Content
		content.add_child(inventory_bar)
		# Anchor bottom-center
		inventory_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		inventory_bar.position.y = content.size.y - inventory_bar.size.y - 20


func _on_house_gui_input(event: InputEvent) -> void:
	if housing_grid.is_editing or _dragging_type != "":
		return
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_move_character_to_mouse()

func _setup_inventory_icons() -> void:
	var hbox = inventory_bar.get_node("HBox")
	
	_set_btn_icon(hbox.get_node("ItemChair"), "chair.png", "furniture")
	_set_btn_icon(hbox.get_node("ItemPic"), "reloj.png", "furniture")
	
	_set_btn_icon(hbox.get_node("Wall1"), "wall_1.png", "structure")
	_set_btn_icon(hbox.get_node("Wall2"), "wall_2.png", "structure")
	
	# Auto-add Wall3 if missing (cloning Wall2 properties)
	if not hbox.has_node("Wall3") and hbox.has_node("Wall2"):
		var w3 = hbox.get_node("Wall2").duplicate()
		w3.name = "Wall3"
		hbox.add_child(w3)
		# Clear old signal, connect new one
		if w3.button_down.is_connected(_on_wall2_down):
			w3.button_down.disconnect(_on_wall2_down)
		w3.button_down.connect(_on_wall3_down)
		
	if hbox.has_node("Wall3"):
		_set_btn_icon(hbox.get_node("Wall3"), "wall_3.png", "structure")
	
	_set_btn_icon(hbox.get_node("Floor1"), "floor_1.png", "structure")
	_set_btn_icon(hbox.get_node("Floor2"), "floor_2.png", "structure")
	_set_btn_icon(hbox.get_node("Floor3"), "floor_3.png", "structure")

func _set_btn_icon(btn: Button, icon_name: String, category: String = "misc") -> void:
	if not btn: return
	btn.text = ""
	btn.icon = load("res://assets/sprites/" + icon_name)
	btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.expand_icon = true
	# Set metadata for filtering
	btn.set_meta("category", category)
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
	# Camera follows character in both House and Shop
	if _in_shop_mode:
		# In Shop: camera is already positioned by Content.x tween
		# We could add fine-tuning here if needed
		return
	
	# In House: original camera logic
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
	# Determine current area (House or Shop)
	var current_area: Control
	var area_size: float
	
	if _in_shop_mode and has_node("Root/Content/ShopArea"):
		current_area = get_node("Root/Content/ShopArea")
		area_size = current_area.size.x
	else:
		current_area = $Root/Content/HouseArea/House
		area_size = current_area.custom_minimum_size.x
	
	if not current_area: return
	
	var local_mouse = current_area.get_local_mouse_position()
	
	# Clamp dentro del área actual
	var target_x = local_mouse.x - character_button.size.x / 2
	target_x = clamp(target_x, 0, area_size - character_button.size.x)
	
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
		
		# "Master Size" logic: assets are big (512x512 usually), we scale them down.
		# Silla is Medium -> 0.5 scale of standard 512 = ~256px height.
		# Original code used fixed Vector2(160, 240). Let's keep consistency but prepare for auto-scale.
		item.size = Vector2(160, 240) # Keeping this for now to match current sprites
		
		# Shadow
		var shadow = Panel.new()
		# Simple oval shadow using stylebox
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0, 0, 0, 0.4)
		style.set_corner_radius_all(100)
		shadow.add_theme_stylebox_override("panel", style)
		shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shadow.show_behind_parent = true
		
		# Shadow size & pos relative to item
		shadow.custom_minimum_size = Vector2(120, 40)
		shadow.size = Vector2(120, 40)
		shadow.position = Vector2((item.size.x - shadow.size.x) / 2, item.size.y - 30)
		item.add_child(shadow)
		
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
	# Check if button moved to sidebar
	var btn: Button
	# Look in HUDLayer first
	if has_node("HUDLayer/LeftSidebar/EditButton"):
		btn = get_node("HUDLayer/LeftSidebar/EditButton")
	elif has_node("Root/LeftSidebar/EditButton"):
		btn = get_node("Root/LeftSidebar/EditButton")
	else:
		# Fallback - might be in root TopBar if init failed
		btn = find_child("EditButton", true, false)
		
	if not btn: return # Safety
		
	editor_ui.visible = btn.button_pressed
	housing_grid.is_editing = btn.button_pressed
	
	# Show/Hide Inventory
	if inventory_bar:
		inventory_bar.visible = btn.button_pressed

func _on_item_chair_button_down() -> void:
	_start_drag("chair")

func _on_item_pic_button_down() -> void:
	_start_drag("pic")

func _on_wall1_down() -> void:
	_start_drag("wall_1")

func _on_wall2_down() -> void:
	_start_drag("wall_2")

func _on_wall3_down() -> void:
	_start_drag("wall_3")

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
