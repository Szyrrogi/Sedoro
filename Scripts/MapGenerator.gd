extends Control

# --- NODES TO ASSIGN IN INSPECTOR ---
@export var game_manager: Node   # GameManager script (handles combat)
@export var combat_node: Node    # Main COMBAT node
@export var map_node: Node       # Main MAP node

# === ENEMY PREVIEW VARIABLES ===
@export var enemy_icons: Array[Texture2D] # Drag images here! Index 0 = enemy ID 0, etc.

var map_enemies = {} 
var tooltip_panel: PanelContainer 
var tooltip_label: Label 
var tooltip_icons_container: HBoxContainer # Container for horizontally aligned icons
# ============================================

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
	_create_tooltip_ui() # Create hidden tooltip window
	
	generate_map()
	assign_enemies_to_rooms() # Roll enemies for the entire map
	draw_map_visuals()
	
	# Automatically scroll to the bottom (level 1) on start
	await get_tree().process_frame
	var scroll = get_parent()
	if scroll is ScrollContainer:
		scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)

# ==========================================
# TOOLTIP PREVIEW SYSTEM
# ==========================================

func _create_tooltip_ui():
	# 1. Create a new layer that always draws on top
	var tooltip_layer = CanvasLayer.new()
	tooltip_layer.layer = 128 # Very high value to cover everything
	add_child(tooltip_layer)
	
	tooltip_panel = PanelContainer.new()
	
	var vbox = VBoxContainer.new()
	tooltip_panel.add_child(vbox)
	
	tooltip_label = Label.new()
	tooltip_label.add_theme_font_size_override("font_size", 20) 
	tooltip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(tooltip_label)
	
	tooltip_icons_container = HBoxContainer.new()
	tooltip_icons_container.alignment = BoxContainer.ALIGNMENT_CENTER 
	tooltip_icons_container.add_theme_constant_override("separation", 10) 
	vbox.add_child(tooltip_icons_container)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.9)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 15
	style.content_margin_bottom = 15
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	tooltip_panel.add_theme_stylebox_override("panel", style)
	
	tooltip_panel.visible = false
	tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 2. Add the panel to the highest layer instead of the map directly
	tooltip_layer.add_child(tooltip_panel)

func assign_enemies_to_rooms():
	map_enemies.clear()
	for grid_pos in map_nodes.keys():
		# Check if GameManager has the function we wrote
		if game_manager and game_manager.has_method("get_random_enemy_encounter"):
			map_enemies[grid_pos] = game_manager.get_random_enemy_encounter()
		else:
			# Fallback if GameManager is not updated or linked
			map_enemies[grid_pos] = [0] 

func _process(delta):
	if tooltip_panel and tooltip_panel.visible:
		# In CanvasLayer we use viewport (screen) coordinates directly
		var mouse_position = get_viewport().get_mouse_position()
		tooltip_panel.position = mouse_position + Vector2(15, 15)

func _on_node_hovered(grid_pos: Vector2):
	if map_enemies.has(grid_pos):
		var enemies_list = map_enemies[grid_pos]
		
		tooltip_label.text = "Enemies:"
		
		for child in tooltip_icons_container.get_children():
			child.queue_free()
			
		for enemy_id in enemies_list:
			var icon_rect = TextureRect.new()
			
			if enemy_id < enemy_icons.size() and enemy_icons[enemy_id] != null:
				icon_rect.texture = enemy_icons[enemy_id]
			else:
				push_warning("Missing icon for enemy ID: ", enemy_id)
				
			# Resize icons
			icon_rect.custom_minimum_size = Vector2(75, 75)
			icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			
			tooltip_icons_container.add_child(icon_rect)
			
		tooltip_panel.visible = true

func _on_node_unhovered():
	tooltip_panel.visible = false

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
	if has_dragged_significantly:
		print("Click ignored - user was dragging the map.")
		return
		
	if is_move_valid(grid_pos):
		current_node = grid_pos
		print("Moved to level: ", grid_pos.x, " room type: ", room_type)
		update_path_visuals()
		
		# Get enemy array for this specific room
		var room_enemies = []
		if map_enemies.has(grid_pos):
			room_enemies = map_enemies[grid_pos]
			
		trigger_room_action(room_type, room_enemies)
	else:
		print("You cannot go there! Choose a connected node above.")

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

func trigger_room_action(room_type: int, room_enemies: Array):
	print("Map: Triggering room type: ", room_type)
	if game_manager and combat_node and map_node:
		# Hide map, show arena, pass array to combat system
		map_node.hide()   
		combat_node.show()  
		game_manager.start_combat(room_enemies) 
	else:
		push_error("ERROR: Nodes not assigned in Map Inspector!")

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
