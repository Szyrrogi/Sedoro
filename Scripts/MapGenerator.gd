extends Control

# --- WĘZŁY DO PRZECIĄGNIĘCIA W INSPEKTORZE ---
@export var game_manager: Node   # Skrypt GameManager
@export var walka_node: Node     # Cały duży węzeł WALKA
@export var mapa_node: Node      # Cały duży węzeł MAPA

const MIN_POS = 0
const MAX_POS = 6

var map_nodes = {} # Słownik: klucz to Vector2(poziom, pozycja), wartość to typ pokoju
var map_edges = [] # Tablica słowników: {"from": Vector2, "to": Vector2}
var current_node = Vector2.ZERO # (0,0) oznacza, że jeszcze nie zaczęliśmy

var is_dragging_map = false
var last_mouse_pos = Vector2.ZERO
var has_dragged_significantly = false # <--- DODAJ TĘ LINIJKĘ

func _ready():
	randomize()
	generate_map()
	draw_map_visuals()
	
	# Automatycznie przewijamy na sam dół (do poziomu 1) przy starcie
	await get_tree().process_frame
	var scroll = get_parent()
	if scroll is ScrollContainer:
		scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)

# ==========================================
# 1. LOGIKA GENEROWANIA 
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
		
		# prosto
		if randf() < 0.80:
			map_nodes[Vector2(curr_lvl, pos)] = get_room_type()
			add_edge(Vector2(prev_lvl, pos), Vector2(curr_lvl, pos))
			created_connection = true
			
		# lewo
		if pos > MIN_POS and randf() < 0.60:
			map_nodes[Vector2(curr_lvl, pos - 1)] = get_room_type()
			add_edge(Vector2(prev_lvl, pos), Vector2(curr_lvl, pos - 1))
			created_connection = true
			
		# prawo
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
# 2. WIZUALIZACJA I RYSOWANIE
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
		
		btn.pressed.connect(_on_node_clicked.bind(grid_pos, room_type))
		btn.set_meta("grid_pos", grid_pos)
		
		# Żeby przyciski nie blokowały przeciągania mapy, dodajemy:
		btn.mouse_filter = Control.MOUSE_FILTER_PASS 
		add_child(btn)
		
	update_path_visuals()

# ==========================================
# 3. INTERAKCJA I PORUSZANIE SIĘ
# ==========================================

func _on_node_clicked(grid_pos: Vector2, room_type: int):
	# ZMIANA TUTAJ: Sprawdzamy nową zmienną
	if has_dragged_significantly:
		print("Kliknięcie zignorowane - gracz przesuwał mapę.")
		return
		
	if is_move_valid(grid_pos):
		current_node = grid_pos
		print("Przeszedłeś na poziom: ", grid_pos.x, " pokój typu: ", room_type)
		update_path_visuals()
		trigger_room_action(room_type)
	else:
		print("Nie możesz tam pójść! Wybierz połączony punkt wyżej.")

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

func trigger_room_action(room_type: int):
	print("Mapa: Bezpośrednio odpalam walkę typu: ", room_type)
	if game_manager and walka_node and mapa_node:
		mapa_node.hide()   # Ukrywamy mapę
		walka_node.show()  # Pokazujemy arenę walki
		game_manager.start_combat(1) # Odpalamy funkcję w GameManagerze
	else:
		push_error("BŁĄD: Nie przeciągnąłeś węzłów do MapGeneratora w Inspektorze!")

# Opcjonalne: Przeciąganie mapy myszką
func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging_map = true
				last_mouse_pos = event.global_position
				has_dragged_significantly = false # Resetujemy przy nowym kliknięciu
			else:
				is_dragging_map = false
				
	elif event is InputEventMouseMotion and is_dragging_map:
		var delta = last_mouse_pos - event.global_position
		
		# Jeśli przesunęliśmy myszkę o więcej niż 5 pikseli, to na pewno przeciągamy mapę, a nie klikamy
		if delta.length() > 5:
			has_dragged_significantly = true
			
		var scroll = get_parent()
		if scroll is ScrollContainer:
			scroll.scroll_vertical += int(delta.y)
		last_mouse_pos = event.global_position
