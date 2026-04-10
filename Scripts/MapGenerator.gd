extends Control

# --- NODES TO ASSIGN IN INSPECTOR ---
@export var game_manager: Node   # GameManager script (handles combat)
@export var combat_node: Node    # Main COMBAT node
@export var map_node: Node       # Main MAP node

# === ENEMY PREVIEW VARIABLES ===
@export var enemy_icons: Array[Texture2D] # Drag images here! Index 0 = enemy ID 0, etc.

var map_enemies = {} 
var preview_panel: Control # Zmieniono na zwykły Control
var enemies_icon_container: HBoxContainer 
var rewards_icon_container: HBoxContainer # NOWY: pojemnik na przyszłe nagrody
# ============================================

var map_rewards = {} # Słownik przechowujący wylosowane nagrody dla pokojów

const MIN_POS = 0
const MAX_POS = 6

var map_nodes = {} # Dictionary: key is Vector2(level, position), value is room type
var map_edges = [] # Array of dictionaries: {"from": Vector2, "to": Vector2}

var current_node = Vector2.ZERO # (0,0) means we haven't started yet

var is_dragging_map = false
var last_mouse_pos = Vector2.ZERO
var has_dragged_significantly = false 

func _ready():
	randomize()
	_create_preview_ui() # Tworzymy stały panel na dole
	
	generate_map()
	assign_room_data() 
	draw_map_visuals()
	
	await get_tree().process_frame
	var scroll = get_parent()
	if scroll is ScrollContainer:
		scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)

# ==========================================
# TOOLTIP PREVIEW SYSTEM
# ==========================================

# ==========================================
# FIXED BOTTOM PREVIEW SYSTEM
# ==========================================

# ==========================================
# FIXED BOTTOM PREVIEW SYSTEM
# ==========================================

func _create_preview_ui():
	var preview_layer = CanvasLayer.new()
	preview_layer.layer = 128 
	add_child(preview_layer)
	
	preview_panel = Control.new()
	preview_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	preview_panel.offset_top = -350
	preview_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE # Ignoruj myszkę
	preview_layer.add_child(preview_panel)
	
	var main_hbox = HBoxContainer.new()
	main_hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_hbox.add_theme_constant_override("separation", 500)
	main_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE # Ignoruj myszkę
	preview_panel.add_child(main_hbox)
	
	var enemies_vbox = VBoxContainer.new()
	enemies_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	enemies_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE # Ignoruj myszkę
	main_hbox.add_child(enemies_vbox)
	
	var enemies_label = Label.new()
	enemies_label.text = "ENEMIES"
	enemies_label.add_theme_font_size_override("font_size", 24)
	enemies_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemies_label.mouse_filter = Control.MOUSE_FILTER_IGNORE # Ignoruj myszkę
	enemies_vbox.add_child(enemies_label)
	
	enemies_icon_container = HBoxContainer.new()
	enemies_icon_container.alignment = BoxContainer.ALIGNMENT_CENTER 
	enemies_icon_container.add_theme_constant_override("separation", 15) 
	enemies_icon_container.custom_minimum_size = Vector2(0, 250)
	enemies_icon_container.mouse_filter = Control.MOUSE_FILTER_IGNORE # Ignoruj myszkę
	enemies_vbox.add_child(enemies_icon_container)
	
	var rewards_vbox = VBoxContainer.new()
	rewards_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	rewards_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE # Ignoruj myszkę
	main_hbox.add_child(rewards_vbox)
	
	var rewards_label = Label.new()
	rewards_label.text = "REWARDS"
	rewards_label.add_theme_font_size_override("font_size", 24)
	rewards_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rewards_label.mouse_filter = Control.MOUSE_FILTER_IGNORE # Ignoruj myszkę
	rewards_vbox.add_child(rewards_label)
	
	rewards_icon_container = HBoxContainer.new()
	rewards_icon_container.alignment = BoxContainer.ALIGNMENT_CENTER
	rewards_icon_container.custom_minimum_size = Vector2(0, 250)
	rewards_icon_container.mouse_filter = Control.MOUSE_FILTER_IGNORE # Ignoruj myszkę
	rewards_vbox.add_child(rewards_icon_container)
	
	preview_panel.visible = false

func _on_node_hovered(grid_pos: Vector2):
	if map_enemies.has(grid_pos):
		# ==========================================
		# 1. RYSOWANIE PRZECIWNIKÓW
		# ==========================================
		var enemies_list = map_enemies[grid_pos]
		for child in enemies_icon_container.get_children():
			child.queue_free()
			
		for enemy_id in enemies_list:
			var icon_rect = TextureRect.new()
			if enemy_id < enemy_icons.size() and enemy_icons[enemy_id] != null:
				icon_rect.texture = enemy_icons[enemy_id]
			else:
				push_warning("Missing icon for enemy ID: ", enemy_id)
				
			icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE # Ignoruj myszkę
			icon_rect.custom_minimum_size = Vector2(300, 300)
			icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			enemies_icon_container.add_child(icon_rect)
			
		# ==========================================
		# 2. RYSOWANIE NAGRÓD (KARTY)
		# ==========================================
		for child in rewards_icon_container.get_children():
			child.queue_free()
			
		if map_rewards.has(grid_pos):
			var rewards_list = map_rewards[grid_pos]
			
			# !!! PODMIEŃ NA SWOJĄ ŚCIEŻKĘ !!!
			const SCENA_KARTY = preload("res://Object/Card.tscn")
			
			for card_id in rewards_list:
				var card_wrapper = Control.new()
				card_wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE # Ignoruj myszkę
				card_wrapper.custom_minimum_size = Vector2(200, 300) 
				
				var card_inst = SCENA_KARTY.instantiate()
				card_wrapper.add_child(card_inst)
				card_inst.setup_card(card_id)
				
				card_inst.scale_normal = Vector2(0.5, 0.5)
				card_inst.scale_hover = Vector2(0.5, 0.5)
				card_inst.scale = Vector2(0.5, 0.5) 
				card_inst.set_start_position(Vector2(80, 120))
				
				# WYŁĄCZAMY FIZYKĘ KARTY (aby Area2D wewnątrz karty nie blokowało myszki na węźle mapy!)
				_wylacz_kolizje_dla_myszki(card_inst)
				
				rewards_icon_container.add_child(card_wrapper)
				
		preview_panel.visible = true

func _on_node_unhovered():
	preview_panel.visible = false

func assign_room_data():
	map_enemies.clear()
	map_rewards.clear()
	for grid_pos in map_nodes.keys():
		# Losowanie Wrogów
		if game_manager and game_manager.has_method("get_random_enemy_encounter"):
			map_enemies[grid_pos] = game_manager.get_random_enemy_encounter()
		else:
			map_enemies[grid_pos] = [0] 
			
		# Losowanie Nagród (Kart)
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
	var x_pixel = 200 + (grid_pos.y * 100)
	var y_pixel = 700 - ((grid_pos.x - 1) * 100)
	return Vector2(x_pixel, y_pixel)

func draw_map_visuals():
	for edge in map_edges:
		var line = Line2D.new()
		line.add_point(grid_to_pixel(edge["from"]))
		line.add_point(grid_to_pixel(edge["to"]))
		line.width = 4
		line.default_color = Color.DARK_GRAY
		line.set_meta("from", edge["from"])
		line.set_meta("to", edge["to"])
		add_child(line)

	for grid_pos in map_nodes.keys():
		var room_type = map_nodes[grid_pos]
		var btn = Button.new()
		btn.position = grid_to_pixel(grid_pos) - Vector2(25, 25) 
		btn.custom_minimum_size = Vector2(50, 50)
		btn.text = str(room_type)
		
		var color = Color.WHITE
		match room_type:
			1: color = Color("A8E6CF") 
			2: color = Color("FFD3B6") 
			3: color = Color("FF8A8A") 
			4: color = Color("C3B1E1") 
			5: color = Color("FDFD96") 
		btn.modulate = color
		
		# Hover signals
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
		current_node = grid_pos
		update_path_visuals()
		
		var room_enemies = []
		if map_enemies.has(grid_pos): room_enemies = map_enemies[grid_pos]
			
		# POBIERAMY NAGRODY:
		var room_rewards = []
		if map_rewards.has(grid_pos): room_rewards = map_rewards[grid_pos]
			
		# PRZEKAZUJEMY NAGRODY:
		trigger_room_action(room_type, room_enemies, room_rewards)

# Dodaj trzeci argument room_rewards:
func trigger_room_action(room_type: int, room_enemies: Array, room_rewards: Array):
	if game_manager and combat_node and map_node:
		map_node.hide()   
		combat_node.show()  
		# Jeśli masz gotową logikę obsługi wygranej, powinieneś w GameManagerze przypisać to do jakiejś zmiennej np. pending_rewards
		game_manager.start_combat(room_enemies)

func is_move_valid(target_pos: Vector2) -> bool:
	if current_node == Vector2.ZERO:
		return target_pos == Vector2(1, 3)
		
	for edge in map_edges:
		if edge["from"] == current_node and edge["to"] == target_pos:
			return true
	return false

func update_path_visuals():
	for child in get_children():
		if child is Button:
			var node_pos = child.get_meta("grid_pos")
			if is_move_valid(node_pos) or node_pos == current_node:
				child.modulate.a = 1.0 
				child.disabled = false
			else:
				child.modulate.a = 0.3 
				if node_pos.x <= current_node.x:
					child.disabled = true



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
			scroll.scroll_vertical += int(delta.y)
		last_mouse_pos = event.global_position


# Pętla wyłączająca fizyczne klikanie nagród
func _wylacz_kolizje_dla_myszki(wezel: Node):
	if wezel is CollisionObject2D:
		wezel.input_pickable = false
	for dziecko in wezel.get_children():
		_wylacz_kolizje_dla_myszki(dziecko)
