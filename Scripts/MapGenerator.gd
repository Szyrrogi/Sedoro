extends Control

# --- NODES TO ASSIGN IN INSPECTOR ---
@export var game_manager: Node   # GameManager script (handles combat)
@export var combat_node: Node    # Main COMBAT node
@export var map_node: Node       # Main MAP node

# === ENEMY PREVIEW VARIABLES ===
@export var enemy_icons: Array[Texture2D]

# === NODE TYPE SPRITES ===
@export var node_type_sprites: Array[Texture2D]

# ==========================================
# USTAW W INSPEKTORZE – HUD na górze mapy
# ==========================================
@export var hud_hp_label: Label      # Label pokazujący HP gracza, np. "80 / 100"
@export var hud_gold_label: Label    # Label pokazujący złoto gracza, np. "42"

# ==========================================
# USTAW W INSPEKTORZE – Podgląd węzła (preview)
# ==========================================
@export var preview_gold_label: Label  # Label pokazujący złoto za walkę w podglądzie

# ==========================================
# USTAW W INSPEKTORZE – Podgląd talii
# ==========================================
@export var deck_viewer: Control        # DeckViewer node
@export var view_deck_button: Button    # Przycisk "Pokaż talię"

# ==========================================
# USTAW W INSPEKTORZE – Podgląd sklepu
# ==========================================
@export var shop_preview_texture: Texture2D  # Sprite wyświetlany przy hover na sklepie

# ==========================================

var map_enemies = {}
var preview_panel: Control
var enemies_icon_container: HBoxContainer
var rewards_icon_container: HBoxContainer

var map_rewards = {}
var map_gold = {}

const MIN_POS = 0
const MAX_POS = 6

var map_nodes = {}
var map_edges = []

var current_node = Vector2.ZERO

var is_dragging_map = false
var last_mouse_pos = Vector2.ZERO
var has_dragged_significantly = false

func _ready():
	randomize()
	_create_preview_ui()
	
	generate_map()
	assign_room_data()
	draw_map_visuals()
	
	if view_deck_button:
		view_deck_button.pressed.connect(_on_view_deck_pressed)
	
	await get_tree().process_frame
	var scroll = get_parent()
	if scroll is ScrollContainer:
		scroll.scroll_horizontal = 0

# ==========================================
# HUD – odświeżanie HP i złota (z Inspektora)
# ==========================================

func _process(_delta):
	if not game_manager:
		return
	if hud_hp_label and game_manager.player:
		var hp = game_manager.player.current_health
		var max_hp = game_manager.player.max_health
		hud_hp_label.text = str(hp) + " / " + str(max_hp)
	if hud_gold_label:
		hud_gold_label.text = str(game_manager.gold)

# ==========================================
# PREVIEW UI – budowane kodem (ikony wrogów i kart)
# ==========================================

func _create_preview_ui():
	var preview_layer = CanvasLayer.new()
	preview_layer.layer = 128
	add_child(preview_layer)
	
	preview_panel = Control.new()
	preview_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	preview_panel.offset_top = -350
	preview_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_layer.add_child(preview_panel)
	
	var main_hbox = HBoxContainer.new()
	main_hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_hbox.add_theme_constant_override("separation", 500)
	main_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_panel.add_child(main_hbox)
	
	# --- Lewa strona: przeciwnicy ---
	var enemies_vbox = VBoxContainer.new()
	enemies_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	enemies_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_hbox.add_child(enemies_vbox)
	
	var enemies_label = Label.new()
	enemies_label.text = "ENEMIES"
	enemies_label.add_theme_font_size_override("font_size", 24)
	enemies_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemies_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	enemies_vbox.add_child(enemies_label)
	
	enemies_icon_container = HBoxContainer.new()
	enemies_icon_container.alignment = BoxContainer.ALIGNMENT_CENTER
	enemies_icon_container.add_theme_constant_override("separation", 15)
	enemies_icon_container.custom_minimum_size = Vector2(0, 250)
	enemies_icon_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	enemies_vbox.add_child(enemies_icon_container)
	
	# --- Prawa strona: nagrody ---
	var rewards_vbox = VBoxContainer.new()
	rewards_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	rewards_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_hbox.add_child(rewards_vbox)
	
	var rewards_label = Label.new()
	rewards_label.text = "REWARDS"
	rewards_label.add_theme_font_size_override("font_size", 24)
	rewards_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rewards_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rewards_vbox.add_child(rewards_label)
	
	rewards_icon_container = HBoxContainer.new()
	rewards_icon_container.alignment = BoxContainer.ALIGNMENT_CENTER
	rewards_icon_container.custom_minimum_size = Vector2(0, 250)
	rewards_icon_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rewards_vbox.add_child(rewards_icon_container)
	
	preview_panel.visible = false

func _on_node_hovered(grid_pos: Vector2):
	# Pokazuj podgląd tylko dla węzłów, na które można się przenieść
	if not is_move_valid(grid_pos):
		return

	var room_type = map_nodes.get(grid_pos, -1)

	# --- Sklep (typ 4) – osobny podgląd ---
	if room_type == 4:
		for child in enemies_icon_container.get_children():
			child.queue_free()
		for child in rewards_icon_container.get_children():
			child.queue_free()

		# Ikona sklepu
		var shop_icon = TextureRect.new()
		shop_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shop_icon.custom_minimum_size = Vector2(300, 300)
		shop_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		shop_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if shop_preview_texture:
			shop_icon.texture = shop_preview_texture
		enemies_icon_container.add_child(shop_icon)

		# Opis po prawej
		var desc = Label.new()
		desc.text = "🏪 SKLEP\n\n• Kup kartę\n• Ulecz się (10 💰)\n• Usuń kartę z talii"
		desc.add_theme_font_size_override("font_size", 26)
		desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD
		desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rewards_icon_container.add_child(desc)

		if preview_gold_label:
			preview_gold_label.text = ""
			preview_gold_label.visible = false

		preview_panel.visible = true
		return

	if not map_enemies.has(grid_pos):
		return

	# --- Rysuj przeciwników ---
	var enemies_list = map_enemies[grid_pos]
	for child in enemies_icon_container.get_children():
		child.queue_free()
		
	for enemy_id in enemies_list:
		var icon_rect = TextureRect.new()
		if enemy_id < enemy_icons.size() and enemy_icons[enemy_id] != null:
			icon_rect.texture = enemy_icons[enemy_id]
		else:
			push_warning("Missing icon for enemy ID: ", enemy_id)
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_rect.custom_minimum_size = Vector2(300, 300)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		enemies_icon_container.add_child(icon_rect)
		
	# --- Rysuj nagrody (karty) ---
	for child in rewards_icon_container.get_children():
		child.queue_free()
		
	if map_rewards.has(grid_pos):
		var rewards_list = map_rewards[grid_pos]
		const SCENA_KARTY = preload("res://Object/Card.tscn")
		for card_id in rewards_list:
			var card_wrapper = Control.new()
			card_wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card_wrapper.custom_minimum_size = Vector2(200, 300)
			
			var card_inst = SCENA_KARTY.instantiate()
			card_wrapper.add_child(card_inst)
			card_inst.setup_card(card_id)
			card_inst.scale_normal = Vector2(0.5, 0.5)
			card_inst.scale_hover = Vector2(0.5, 0.5)
			card_inst.scale = Vector2(0.5, 0.5)
			card_inst.set_start_position(Vector2(80, 120))
			_wylacz_kolizje_dla_myszki(card_inst)
			rewards_icon_container.add_child(card_wrapper)
	
	# --- Złoto za walkę – aktualizuje label z Inspektora ---
	if preview_gold_label:
		if map_gold.has(grid_pos) and map_gold[grid_pos] > 0:
			preview_gold_label.text = "💰 +" + str(map_gold[grid_pos]) + " złota"
		else:
			preview_gold_label.text = ""
		preview_gold_label.visible = true
			
	preview_panel.visible = true

func _on_node_unhovered():
	preview_panel.visible = false
	if preview_gold_label:
		preview_gold_label.visible = false

func assign_room_data():
	map_enemies.clear()
	map_rewards.clear()
	map_gold.clear()
	for grid_pos in map_nodes.keys():
		var room_type = map_nodes[grid_pos]
		
		if room_type == 4 or room_type == 3:
			pass
		else:
			if game_manager and game_manager.has_method("get_random_enemy_encounter"):
				map_enemies[grid_pos] = game_manager.get_random_enemy_encounter(room_type)
			else:
				map_enemies[grid_pos] = [0]
			
			var total_gold = 0
			for enemy_id in map_enemies[grid_pos]:
				if EnemyDatabase.ENEMY.has(enemy_id):
					total_gold += EnemyDatabase.ENEMY[enemy_id][4]
			map_gold[grid_pos] = total_gold
			
		if game_manager and game_manager.has_method("get_random_card_rewards"):
			map_rewards[grid_pos] = game_manager.get_random_card_rewards()
		else:
			map_rewards[grid_pos] = []


# ==========================================
# 1. MAP GENERATION LOGIC
# ==========================================

func get_room_type() -> int:
	var r = randf()
	if r < 0.15: return 3
	elif r < 0.30: return 2
	else: return 1

func add_edge(from_node: Vector2, to_node: Vector2):
	for edge in map_edges:
		if edge["from"] == from_node and edge["to"] == to_node:
			return
	map_edges.append({"from": from_node, "to": to_node})

func generate_random_level(prev_lvl: int, curr_lvl: int):
	var prev_nodes = []
	for key in map_nodes.keys():
		if key.x == prev_lvl:
			prev_nodes.append(key.y)
			
	for pos in prev_nodes:
		var created_connection = false
		
		if randf() < 0.80:
			map_nodes[Vector2(curr_lvl, pos)] = get_room_type()
			add_edge(Vector2(prev_lvl, pos), Vector2(curr_lvl, pos))
			created_connection = true
			
		if pos > MIN_POS and randf() < 0.60:
			map_nodes[Vector2(curr_lvl, pos - 1)] = get_room_type()
			add_edge(Vector2(prev_lvl, pos), Vector2(curr_lvl, pos - 1))
			created_connection = true
			
		if pos < MAX_POS and randf() < 0.60:
			map_nodes[Vector2(curr_lvl, pos + 1)] = get_room_type()
			add_edge(Vector2(prev_lvl, pos), Vector2(curr_lvl, pos + 1))
			created_connection = true

		if not created_connection:
			map_nodes[Vector2(curr_lvl, pos)] = get_room_type()
			add_edge(Vector2(prev_lvl, pos), Vector2(curr_lvl, pos))

func get_closest(target: float, array: Array) -> float:
	var closest = array[0]
	var min_dist = abs(array[0] - target)
	for val in array:
		var dist = abs(val - target)
		if dist < min_dist:
			min_dist = dist
			closest = val
	return closest

func generate_map():
	map_nodes.clear()
	map_edges.clear()

	map_nodes[Vector2(1, 3)] = 1

	for pos in [0, 2, 4, 6]:
		map_nodes[Vector2(2, pos)] = 1
		add_edge(Vector2(1, 3), Vector2(2, pos))

	generate_random_level(2, 3)
	generate_random_level(3, 4)
	generate_random_level(4, 5)

	var l6_positions = [1, 3, 5]
	for pos in l6_positions:
		map_nodes[Vector2(6, pos)] = 4

	var l5_nodes = []
	for key in map_nodes.keys():
		if key.x == 5:
			l5_nodes.append(key.y)
			
	for p5 in l5_nodes:
		var closest_p6 = get_closest(p5, l6_positions)
		add_edge(Vector2(5, p5), Vector2(6, closest_p6))
		
	for p6 in l6_positions:
		var closest_p5 = get_closest(p6, l5_nodes)
		add_edge(Vector2(5, closest_p5), Vector2(6, p6))

	generate_random_level(6, 7)
	map_nodes[Vector2(8, 3)] = 5
	
	var l7_nodes = []
	for key in map_nodes.keys():
		if key.x == 7:
			l7_nodes.append(key.y)
	for p7 in l7_nodes:
		add_edge(Vector2(7, p7), Vector2(8, 3))

# ==========================================
# 2. VISUALS AND DRAWING
# ==========================================

func grid_to_pixel(grid_pos: Vector2) -> Vector2:
	var x_pixel = 150 + ((grid_pos.x - 1) * 120)
	var y_pixel = 100 + (grid_pos.y * 100)
	return Vector2(x_pixel, y_pixel)

func draw_map_visuals():
	for edge in map_edges:
		var line = Line2D.new()
		line.add_point(grid_to_pixel(edge["from"]))
		line.add_point(grid_to_pixel(edge["to"]))
		line.width = 4
		line.default_color = Color(0.3, 0.3, 0.3, 0.0)
		line.set_meta("from", edge["from"])
		line.set_meta("to", edge["to"])
		add_child(line)

	for grid_pos in map_nodes.keys():
		var room_type = map_nodes[grid_pos]
		var btn = Button.new()
		btn.position = grid_to_pixel(grid_pos) - Vector2(25, 25)
		btn.custom_minimum_size = Vector2(50, 50)
		btn.text = ""
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		var style_empty = StyleBoxEmpty.new()
		btn.add_theme_stylebox_override("normal", style_empty)
		btn.add_theme_stylebox_override("hover", style_empty)
		btn.add_theme_stylebox_override("pressed", style_empty)
		btn.add_theme_stylebox_override("disabled", style_empty)
		btn.add_theme_stylebox_override("focus", style_empty)
		
		var sprite_index = room_type - 1
		if sprite_index >= 0 and sprite_index < node_type_sprites.size() and node_type_sprites[sprite_index] != null:
			var tex_rect = TextureRect.new()
			tex_rect.texture = node_type_sprites[sprite_index]
			tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
			tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			btn.add_child(tex_rect)
		else:
			btn.text = str(room_type)
		
		var color = Color.WHITE
		match room_type:
			1: color = Color("A8E6CF")
			2: color = Color("FFD3B6")
			3: color = Color("FF8A8A")
			4: color = Color("C3B1E1")
			5: color = Color("FDFD96")
		btn.modulate = color
		
		btn.mouse_entered.connect(_on_node_hovered.bind(grid_pos))
		btn.mouse_exited.connect(_on_node_unhovered)
		btn.pressed.connect(_on_node_clicked.bind(grid_pos, room_type))
		btn.set_meta("grid_pos", grid_pos)
		btn.mouse_filter = Control.MOUSE_FILTER_PASS
		add_child(btn)
		
	update_path_visuals()

# ==========================================
# 3. INTERACTION AND MOVEMENT
# ==========================================

func _on_node_clicked(grid_pos: Vector2, room_type: int):
	if has_dragged_significantly: return
		
	if is_move_valid(grid_pos):
		if current_node != Vector2.ZERO and not visited_nodes.has(current_node):
			visited_nodes.append(current_node)
		current_node = grid_pos
		update_path_visuals()
		
		var room_enemies = []
		if map_enemies.has(grid_pos): room_enemies = map_enemies[grid_pos]
			
		var room_rewards = []
		if map_rewards.has(grid_pos): room_rewards = map_rewards[grid_pos]
		
		var room_gold = 0
		if map_gold.has(grid_pos): room_gold = map_gold[grid_pos]
		if game_manager and "pending_gold" in game_manager:
			game_manager.pending_gold = room_gold
			
		trigger_room_action(room_type, room_enemies, room_rewards)

func _on_view_deck_pressed():
	if not deck_viewer or not game_manager: return
	var deck_data    = game_manager.deck.deck_data       if game_manager.deck    else []
	var discard_data = game_manager.discard.discard_data if game_manager.discard else []
	if deck_viewer.has_method("show_deck"):
		deck_viewer.show_deck(deck_data, discard_data)

func trigger_room_action(room_type: int, room_enemies: Array, room_rewards: Array):
	if not game_manager or not combat_node or not map_node:
		return
	map_node.hide()
	# Pole 4 = Sklep
	if room_type == 4:
		game_manager.open_shop()
	else:
		combat_node.show()
		game_manager.start_combat(room_enemies, room_rewards, room_type)

func is_move_valid(target_pos: Vector2) -> bool:
	if current_node == Vector2.ZERO:
		return target_pos == Vector2(1, 3)
	for edge in map_edges:
		if edge["from"] == current_node and edge["to"] == target_pos:
			return true
	return false

var visited_nodes: Array = []

func update_path_visuals():
	for child in get_children():
		if child is Line2D:
			var from_pos = child.get_meta("from")
			var to_pos = child.get_meta("to")
			if visited_nodes.has(from_pos) and (visited_nodes.has(to_pos) or to_pos == current_node):
				child.default_color = Color.YELLOW
				child.width = 5
			elif from_pos == current_node:
				child.default_color = Color.WHITE
				child.width = 4
			else:
				child.default_color = Color(0.4, 0.4, 0.4, 0.5)
				child.width = 3

	for child in get_children():
		if child is Button:
			var node_pos = child.get_meta("grid_pos")
			child.modulate.a = 1.0
			if node_pos == current_node:
				child.disabled = true
			elif is_move_valid(node_pos):
				child.disabled = false
			else:
				child.disabled = node_pos.x <= current_node.x


func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging_map = true
				last_mouse_pos = event.global_position
				has_dragged_significantly = false
			else:
				is_dragging_map = false
	elif event is InputEventMouseMotion and is_dragging_map:
		var delta = last_mouse_pos - event.global_position
		if delta.length() > 5:
			has_dragged_significantly = true
		var scroll = get_parent()
		if scroll is ScrollContainer:
			scroll.scroll_horizontal += int(delta.x)
			scroll.scroll_vertical += int(delta.y)
		last_mouse_pos = event.global_position


func _wylacz_kolizje_dla_myszki(wezel: Node):
	if wezel is CollisionObject2D:
		wezel.input_pickable = false
	for dziecko in wezel.get_children():
		_wylacz_kolizje_dla_myszki(dziecko)
