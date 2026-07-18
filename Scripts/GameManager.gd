extends Node

@export var reward_panel: Control
@export var reward_container: Container
@export var card_scene_for_rewards: PackedScene
var pending_rewards: Array = []

# Złoto gracza
var gold: int = 0
var pending_gold: int = 0

# Czy aktualnie trwa walka z bossem końca mapy
var fighting_boss: bool = false

@export var use_random_encounters: bool = true

# --- NODES TO ASSIGN IN INSPECTOR ---
@export var combat_node: Node
@export var map_node: Node
@export var shop_node: Control
@export var save_button: Button

@export var deck: Node2D
@export var hand: Node2D
@export var discard: Node2D
@export var end_turn_button: Button
@export var mana_manager: Node2D
@export var player: Node2D
@export var card_manager: Node2D
@export var passive_manager: Node

@export var enemies: Array[Node] 
@export var enemy_scene: PackedScene 
@export var spawn_start_position: Vector2 = Vector2(1300, 400) 
@export var spawn_spacing: float = 300.0 

@export var custom_enemy_count: int = 0
@export var default_enemy_id: int = 1

# Referencja do MapGenerator
@export var map_generator: Node

# ====================================================
# NOWE ZMIENNE UI DLA SYSTEMU DOBIERANIA I FAZ
# ====================================================
@export var draw_button: Button
@export var phase_label: Label
@export var roll_info_label: Label
@export var fail_label: Label

var draw_fail_chance: int = 0
var current_phase_name: String = "Dobieranie"
# ====================================================

enum State { PLAYER_START, PLAYER_ACTION, ENEMY_TURN, BATTLE_ENDED }
var current_state = State.PLAYER_START

const HAND_LIMIT = 10
const CARDS_PER_TURN = 7 # Zostawiam dla kompatybilności, ale dobieranie teraz jest manualne
const MANA_MAX = 20

var mana = 0

func _ready():
	if end_turn_button:
		end_turn_button.pressed.connect(_on_end_turn_button_pressed)
	if draw_button:
		draw_button.pressed.connect(_on_draw_button_pressed)

func start_combat(horde_data: Array = [], rewards: Array = [], room_type: int = 1, is_boss: bool = false, skip_spawn: bool = false):
	print("\n--- INICJACJA WALKI --- Typ pokoju: ", room_type, " | Boss: ", is_boss)
	print("Otrzymane nagrody z mapy: ", rewards)
	
	if save_button:
		save_button.hide()
		
	fighting_boss = is_boss
	pending_rewards = rewards

	# === 1. CZYSZCZENIE KART ===
	var leftover_cards = hand.get_all_cards().duplicate()
	for card in leftover_cards:
		card.set_selected(false)
		hand.remove_card(card)
		discard.add_to_discard(card)
		
	await get_tree().create_timer(0.25).timeout
	
	if discard.discard_data.size() > 0:
		await deck.reshuffle_from_discard()
	
	# === 2. RESET STANU ===
	mana = 0
	current_state = State.PLAYER_START
	player.modulate = Color(1, 1, 1)
	
	if player.has_method("reset_combat_stats"):
		player.reset_combat_stats()

	if passive_manager and passive_manager.has_method("clear_all_passives"):
		passive_manager.clear_all_passives()
	
	# === 3. SPAWN PRZECIWNIKÓW ===
	if not skip_spawn:
		spawn_horde(horde_data)
	
	await get_tree().create_timer(0.5).timeout
	start_player_turn()

func open_shop():
	print("Otwieranie sklepu...")
	if not shop_node:
		push_error("GameManager: shop_node NIE JEST PRZYPISANY w Inspektorze!")
		return
	if not shop_node.has_method("open_shop"):
		push_error("GameManager: shop_node nie ma metody open_shop – sprawdź czy ShopScreen.gd jest dołączony!")
		return
	combat_node.hide()
	map_node.hide()
	shop_node.show()
	shop_node.open_shop()
	if save_button:
		save_button.hide()

func win_battle():
	print("Walka wygrana!")
	current_state = State.BATTLE_ENDED

	if pending_gold > 0:
		gold += pending_gold
		print("Gracz otrzymuje ", pending_gold, " złota! Łącznie: ", gold)
		pending_gold = 0

	if fighting_boss:
		fighting_boss = false
		await _handle_boss_victory()
		return

	if pending_rewards.size() > 0:
		show_reward_screen()
	else:
		return_to_map()

func _handle_boss_victory():
	print("\n=== BOSS POKONANY! Zapisuję przejście... ===")

	var full_deck: Array = []
	if deck:
		for card_id in deck.deck_data:
			full_deck.append(int(card_id))
	if discard:
		for card_id in discard.discard_data:
			full_deck.append(int(card_id))
	if hand:
		for card_node in hand.get_all_cards():
			if "card_data_id" in card_node:
				full_deck.append(int(card_node.card_data_id))
			elif "card_id" in card_node:
				full_deck.append(int(card_node.card_id))
			elif card_node.has_method("get_card_id"):
				full_deck.append(int(card_node.get_card_id()))

	RunManager.save_run(full_deck)
	_reset_player_for_new_run()
	RunManager.advance_iteration()
	_regenerate_map()

func _reset_player_for_new_run():
	print("Resetuję gracza do nowego przejścia...")

	if player:
		player.current_health = player.max_health
		player.current_armor = 0
		if player.health_bar:
			player.health_bar.max_value = player.max_health
			player.health_bar.value = player.max_health
		if player.white_health_bar:
			player.white_health_bar.value = player.max_health
		if player.has_method("reset_combat_stats"):
			player.reset_combat_stats()

	gold = 0

	if hand:
		for card_node in hand.get_all_cards().duplicate():
			hand.remove_card(card_node)
			card_node.queue_free()

	if discard:
		discard.discard_data.clear()
		for card_node in discard.get_children():
			card_node.queue_free()

	var new_starting_deck = RunManager.get_starting_deck()
	if deck:
		deck.deck_data = new_starting_deck.duplicate()
		deck.deck_data.shuffle()
		deck.update_visuals()

func _regenerate_map():
	if not map_generator: return
	if map_generator.has_method("regenerate_map"):
		map_generator.regenerate_map()

func show_reward_screen():
	if not reward_panel or not reward_container or not card_scene_for_rewards:
		return_to_map()
		return
		
	if reward_container is BoxContainer:
		reward_container.alignment = BoxContainer.ALIGNMENT_CENTER
		
	for child in reward_container.get_children():
		child.queue_free()
		
	for child in reward_panel.get_children():
		if child is Label and child.name == "RewardTitle":
			child.queue_free()
			
	reward_panel.show()
	
	var title_label = Label.new()
	title_label.name = "RewardTitle"
	title_label.text = "CHOOSE ONE CARD:"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title_label.offset_top = 100 
	title_label.offset_left = 200
	title_label.offset_right = 200
	title_label.add_theme_font_size_override("font_size", 64) 
	reward_panel.add_child(title_label)

	for card_id in pending_rewards:
		var wrapper = Control.new()
		wrapper.custom_minimum_size = Vector2(250, 350) 
		
		var card_inst = card_scene_for_rewards.instantiate()
		wrapper.add_child(card_inst)
		
		card_inst.setup_card(card_id)
		card_inst.z_index = 100 
		
		if card_inst.has_method("set_start_position"):
			card_inst.set_start_position(Vector2(125, 175))
		else:
			card_inst.position = Vector2(100, 175)
			
		card_inst.scale = Vector2(1.0, 1.0)
		card_inst.scale_normal = Vector2(1.0, 1.0)
		card_inst.scale_hover = Vector2(1.1, 1.1)
		
		_wylacz_kolizje_dla_myszki(card_inst)
		
		var btn = Button.new()
		btn.set_anchors_preset(Control.PRESET_FULL_RECT)
		btn.flat = true
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.z_index = 101
		btn.pressed.connect(func(): _on_reward_card_chosen(card_id))
		wrapper.add_child(btn)
		
		reward_container.add_child(wrapper)

func _wylacz_kolizje_dla_myszki(wezel: Node):
	if wezel is CollisionObject2D:
		wezel.input_pickable = false
	for dziecko in wezel.get_children():
		_wylacz_kolizje_dla_myszki(dziecko)

func _on_reward_card_chosen(card_id: int):
	if deck and deck.has_method("add_card_to_deck"):
		deck.add_card_to_deck(card_id)
		
	pending_rewards.clear()
	return_to_map()

func return_to_map():
	if reward_panel:
		reward_panel.hide()
	if shop_node:
		shop_node.hide()
	if combat_node and map_node:
		combat_node.hide() 
		map_node.show()
	if save_button:
		save_button.show()
		
func lose_battle():
	print("Combat lost!")
	current_state = State.BATTLE_ENDED 
	if FileAccess.file_exists(MID_RUN_SAVE_PATH):
		DirAccess.remove_absolute(MID_RUN_SAVE_PATH)

func spawn_horde(horde: Array):
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	enemies.clear() 
	
	if horde.is_empty():
		horde = [0]

	var enemy_count = horde.size()
	var total_width = (enemy_count - 1) * spawn_spacing
	var start_x = spawn_start_position.x - (total_width / 2.0)
	
	for i in range(enemy_count):
		var enemy_id = horde[i]
		var enemy_inst = enemy_scene.instantiate()
		add_child(enemy_inst)
		enemy_inst.player = player
		enemy_inst.game_manager = self
		enemy_inst.modulate = Color(1, 1, 1)
		enemy_inst.setup(enemy_id)
		enemy_inst.global_position = Vector2(start_x + (i * spawn_spacing), spawn_start_position.y)
		enemies.append(enemy_inst)

func spawn_hero_boss():
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	enemies.clear()

	var boss_inst = enemy_scene.instantiate()
	add_child(boss_inst)
	boss_inst.player = player
	boss_inst.game_manager = self
	boss_inst.modulate = Color(1, 1, 1)
	boss_inst.setup_as_hero_boss(RunManager.get_boss_deck())
	boss_inst.global_position = spawn_start_position
	enemies.append(boss_inst)
		
func _process(delta: float) -> void:
	mana_manager.set_mana(mana)

func _on_end_turn_button_pressed():
	if current_state == State.PLAYER_ACTION:
		end_player_turn()

# ====================================================
# NOWY SYSTEM TURY GRACZA (START)
# ====================================================
func start_player_turn():
	current_state = State.PLAYER_START
	print("\n--- PLAYER TURN START ---")
	
	mana = 0
	card_manager.redraws_used = 0
	
	# Reset nowego systemu
	draw_fail_chance = 0
	set_phase("Dobieranie")
	
	if fail_label:
		fail_label.hide()
	if roll_info_label:
		roll_info_label.text = "Szansa na porażkę: 0%"
	if draw_button:
		draw_button.disabled = false
	
	if player and "cards_drawn_this_turn" in player:
		player.cards_drawn_this_turn = 0

	if passive_manager and passive_manager.has_method("trigger_all_passives"):
		passive_manager.trigger_all_passives()

	if player.has_method("start_turn"):
		player.start_turn()
	
	player.modulate = Color(1.5, 1.5, 1.5)
	
	current_state = State.PLAYER_ACTION

func _on_draw_button_pressed():
	if current_state != State.PLAYER_ACTION:
		return
		
	if hand.get_child_count() >= HAND_LIMIT:
		print("Pełna ręka!")
		return

	set_phase("Dobieranie")

	var roll = randi_range(1, 100)
	var fail_threshold = draw_fail_chance
	
	if roll <= fail_threshold and fail_threshold > 0:
		# --- PORAŻKA ---
		if roll_info_label:
			roll_info_label.text = "Wylosowano: %d. Porażka od: %d" % [roll, fail_threshold]
		if fail_label:
			fail_label.show()
			
		print("Porażka przy dobieraniu! Tura natychmiastowo zakończona.")
		if draw_button:
			draw_button.disabled = true
			
		end_player_turn() 
	else:
		# --- SUKCES ---
		# Awaitujemy nową kartę z talii
		var new_cards = await deck.draw_cards(1)
		for card in new_cards:
			hand.add_card(card)
			if player and "cards_drawn_this_turn" in player:
				player.cards_drawn_this_turn += 1
				
		draw_fail_chance = min(draw_fail_chance + 5, 30)
		
		if roll_info_label:
			roll_info_label.text = "Wylosowano: %d. Porażka od: %d\nKolejna szansa porażki: %d%%" % [roll, fail_threshold, draw_fail_chance]

func set_phase(new_phase: String):
	current_phase_name = new_phase
	if phase_label:
		phase_label.text = "Faza: " + current_phase_name
		
	# --- NOWE: Zarządzanie widocznością przycisku dobierania ---
	if draw_button:
		if current_phase_name == "Dobieranie":
			draw_button.show() # Pokazuje przycisk
			draw_button.disabled = false
		else:
			draw_button.hide() # Ukrywa przycisk w innych fazach
# ====================================================

func end_player_turn():
	if current_state != State.PLAYER_ACTION:
		return
	
	print("Player turn ended. Discarding all cards...")
	
	if draw_button:
		draw_button.disabled = true
		
	card_manager.active = 0
	card_manager.set_active()
	
	var cards_in_hand = hand.get_all_cards().duplicate()
	for card in cards_in_hand:
		if card.is_selected:
			card.set_selected(false)
		hand.remove_card(card)
		discard.add_to_discard(card)
		
	start_enemy_turn()

func start_enemy_turn():
	current_state = State.ENEMY_TURN
	print("Enemy turn...")
	
	player.modulate = Color(1, 1, 1)
	
	for enemy in enemies:
		if is_instance_valid(enemy): 
			enemy.modulate = Color(1.5, 1.5, 1.5)
			if enemy.has_method("start_turn"):
				enemy.start_turn()
			enemy.action()
				
			await get_tree().create_timer(1).timeout
				
			if is_instance_valid(enemy):
				enemy.modulate = Color(1, 1, 1)
				
			if current_state == State.BATTLE_ENDED:
				break
		
	await get_tree().create_timer(1).timeout
	
	if current_state != State.BATTLE_ENDED:
		start_player_turn()
	else:
		print("Combat ended during enemy turn.")
		
func set_button_active(is_active: bool):
	if end_turn_button:
		end_turn_button.disabled = !is_active
		end_turn_button.text = "END TURN" if is_active else "WAIT..."

func _input(event):
	if event.is_action_pressed("ui_accept"):
		end_player_turn()
		
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_6:
			kill_all_enemies()

func kill_all_enemies():
	print("CHEAT: Zabijanie wszystkich wrogów!")
	var enemies_to_kill = enemies.duplicate()
	for enemy in enemies_to_kill:
		if is_instance_valid(enemy) and enemy.has_method("die"):
			enemy.die()

func get_random_enemy_encounter(room_type: int) -> Array:
	match room_type:
		1: return EnemyDatabase.HORD_TYPE1[randi() % EnemyDatabase.HORD_TYPE1.size()]
		2: return EnemyDatabase.HORD_TYPE2[randi() % EnemyDatabase.HORD_TYPE2.size()]
		5: return EnemyDatabase.HORD_TYPE3[randi() % EnemyDatabase.HORD_TYPE3.size()]
	return [0]
	
func get_random_card_rewards() -> Array:
	var possible_rewards = [
		[1, 2, 3], [4, 5], [1, 5, 6], [2, 7]
	]
	var chosen_rewards = possible_rewards.pick_random()
	return chosen_rewards

const MID_RUN_SAVE_PATH = "user://mid_run_save.json"

func _vec2_to_str(v: Vector2) -> String:
	return str(v.x) + "," + str(v.y)

func _str_to_vec2(s: String) -> Vector2:
	var parts = s.split(",")
	return Vector2(parts[0].to_float(), parts[1].to_float())

func save_mid_run():
	print("Rozpoczynam zapis stanu gry (Mid-Run)...")
	var save_dict = {}

	save_dict["iteration"] = RunManager.current_iteration
	save_dict["gold"] = self.gold
	
	if player:
		save_dict["player_hp"] = player.current_health
		save_dict["player_max_hp"] = player.max_health

	var current_deck = []
	if deck:
		for c in deck.deck_data: current_deck.append(int(c))
	save_dict["deck"] = current_deck
	
	var current_discard = []
	if discard:
		for c in discard.discard_data: current_discard.append(int(c))
	save_dict["discard"] = current_discard

	var map_data = {}
	if map_generator:
		map_data["current_node_x"] = map_generator.current_node.x
		map_data["current_node_y"] = map_generator.current_node.y

		var v_nodes = []
		for vn in map_generator.visited_nodes:
			v_nodes.append({"x": vn.x, "y": vn.y})
		map_data["visited_nodes"] = v_nodes

		var dict_nodes = {}
		for k in map_generator.map_nodes.keys():
			dict_nodes[_vec2_to_str(k)] = map_generator.map_nodes[k]
		map_data["map_nodes"] = dict_nodes

		var edges = []
		for e in map_generator.map_edges:
			edges.append({
				"from_x": e["from"].x, "from_y": e["from"].y,
				"to_x": e["to"].x, "to_y": e["to"].y
			})
		map_data["map_edges"] = edges

		var d_enemies = {}
		for k in map_generator.map_enemies.keys():
			d_enemies[_vec2_to_str(k)] = map_generator.map_enemies[k]
		map_data["map_enemies"] = d_enemies

		var d_rewards = {}
		for k in map_generator.map_rewards.keys():
			d_rewards[_vec2_to_str(k)] = map_generator.map_rewards[k]
		map_data["map_rewards"] = d_rewards

		var d_gold = {}
		for k in map_generator.map_gold.keys():
			d_gold[_vec2_to_str(k)] = map_generator.map_gold[k]
		map_data["map_gold"] = d_gold

	save_dict["map"] = map_data

	var file = FileAccess.open(MID_RUN_SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_dict, "\t"))
		file.close()
		print("✅ Zapis gry zakończony sukcesem!")
	else:
		push_error("❌ Błąd zapisu pliku: " + MID_RUN_SAVE_PATH)


func load_mid_run() -> bool:
	print("Próba wczytania stanu gry...")
	if not FileAccess.file_exists(MID_RUN_SAVE_PATH):
		return false

	var file = FileAccess.open(MID_RUN_SAVE_PATH, FileAccess.READ)
	var json = JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return false
	
	var data = json.get_data()

	if data.has("iteration"):
		RunManager._set_iteration(int(data["iteration"]))

	self.gold = int(data.get("gold", 0))
	if player:
		player.max_health = int(data.get("player_max_hp", 100))
		player.current_health = int(data.get("player_hp", 100))
		if player.health_bar:
			player.health_bar.max_value = player.max_health
			player.health_bar.value = player.current_health

	if deck and data.has("deck"):
		var loaded_deck = data["deck"]
		deck.deck_data.clear()
		for c in loaded_deck: deck.deck_data.append(int(c))
		deck.update_visuals()
		
	if discard and data.has("discard"):
		var loaded_discard = data["discard"]
		discard.discard_data.clear()
		for c in loaded_discard: discard.discard_data.append(int(c))

	if map_generator and data.has("map"):
		var map_data = data["map"]

		for child in map_generator.get_children():
			if child == map_generator.preview_panel or child.get_parent() == map_generator.preview_panel or child is CanvasLayer:
				continue
			child.queue_free()

		map_generator.map_nodes.clear()
		map_generator.map_edges.clear()
		map_generator.visited_nodes.clear()
		map_generator.map_enemies.clear()
		map_generator.map_rewards.clear()
		map_generator.map_gold.clear()

		map_generator.current_node = Vector2(map_data.get("current_node_x", 0), map_data.get("current_node_y", 0))

		for vn in map_data.get("visited_nodes", []):
			map_generator.visited_nodes.append(Vector2(vn["x"], vn["y"]))

		var m_nodes = map_data.get("map_nodes", {})
		for k in m_nodes.keys():
			map_generator.map_nodes[_str_to_vec2(k)] = int(m_nodes[k])

		var m_edges = map_data.get("map_edges", [])
		for e in m_edges:
			map_generator.map_edges.append({
				"from": Vector2(e["from_x"], e["from_y"]),
				"to": Vector2(e["to_x"], e["to_y"])
			})

		var m_enemies = map_data.get("map_enemies", {})
		for k in m_enemies.keys():
			var arr = []
			for id in m_enemies[k]: arr.append(int(id))
			map_generator.map_enemies[_str_to_vec2(k)] = arr

		var m_rewards = map_data.get("map_rewards", {})
		for k in m_rewards.keys():
			var arr = []
			for id in m_rewards[k]: arr.append(int(id))
			map_generator.map_rewards[_str_to_vec2(k)] = arr

		var m_gold = map_data.get("map_gold", {})
		for k in m_gold.keys():
			map_generator.map_gold[_str_to_vec2(k)] = int(m_gold[k])

		map_generator.draw_map_visuals()

	print("✅ Stan gry pomyślnie wczytany!")
	return true
