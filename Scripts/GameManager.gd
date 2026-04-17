extends Node


@export var reward_panel: Control
@export var reward_container: Container
@export var card_scene_for_rewards: PackedScene
var pending_rewards: Array = []

# NOWE: złoto gracza
var gold: int = 0
var pending_gold: int = 0   # złoto za bieżącą walkę (ustawiane przez MapGenerator)


@export var use_random_encounters: bool = true

# --- NODES TO ASSIGN IN INSPECTOR ---
@export var combat_node: Node
@export var map_node: Node
@export var shop_node: Control   # Przypisz ShopScreen node w Inspektorze

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
@export var spawn_start_position: Vector2 = Vector2(1300, 600) 
@export var spawn_spacing: float = 300.0 

@export var custom_enemy_count: int = 0
@export var default_enemy_id: int = 1

enum State { PLAYER_START, PLAYER_ACTION, ENEMY_TURN, BATTLE_ENDED }
var current_state = State.PLAYER_START

const HAND_LIMIT = 10
const CARDS_PER_TURN = 7
const MANA_MAX = 20

var mana = 0

func _ready():
	if end_turn_button:
		end_turn_button.pressed.connect(_on_end_turn_button_pressed)

func start_combat(horde_data: Array = [], rewards: Array = [], room_type: int = 1):
	print("\n--- INICJACJA WALKI --- Typ pokoju: ", room_type)
	print("Otrzymane nagrody z mapy: ", rewards)
	
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
	spawn_horde(horde_data)
	
	await get_tree().create_timer(0.5).timeout
	start_player_turn()

func open_shop():
	print("Otwieranie sklepu...")
	if shop_node and shop_node.has_method("open_shop"):
		combat_node.hide()
		map_node.hide()
		shop_node.show()
		shop_node.open_shop()
	else:
		push_error("GameManager: brak przypisanego shop_node lub metody open_shop!")
		return_to_map()

func win_battle():
	print("Walka wygrana! Sprawdzam nagrody...")
	current_state = State.BATTLE_ENDED 
	
	# NOWE: Dodaj złoto za pokonanych wrogów
	if pending_gold > 0:
		gold += pending_gold
		print("Gracz otrzymuje ", pending_gold, " złota! Łącznie: ", gold)
		pending_gold = 0
	
	if pending_rewards.size() > 0:
		print("Znaleziono nagrody: ", pending_rewards, ". Pokazuję ekran.")
		show_reward_screen()
	else:
		print("Brak nagród dla tego pokoju. Powrót na mapę.")
		return_to_map()

func show_reward_screen():
	if not reward_panel or not reward_container or not card_scene_for_rewards:
		push_error("BŁĄD: Brak przypisanych węzłów UI w inspektorze GameManager!")
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
		
func lose_battle():
	print("Combat lost!")
	current_state = State.BATTLE_ENDED 

func spawn_horde(horde: Array):
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	enemies.clear() 
	
	if horde.is_empty():
		push_error("Map passed an empty horde! Using fallback enemy ID 0")
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
		
func _process(delta: float) -> void:
	mana_manager.set_mana(mana)

func _on_end_turn_button_pressed():
	if current_state == State.PLAYER_ACTION:
		end_player_turn()

func start_player_turn():
	current_state = State.PLAYER_START
	print("\n--- PLAYER TURN START ---")
	
	mana = 0
	card_manager.redraws_used = 0
	
	if player and "cards_drawn_this_turn" in player:
		player.cards_drawn_this_turn = 0

	if passive_manager and passive_manager.has_method("trigger_all_passives"):
		passive_manager.trigger_all_passives()

	if player.has_method("start_turn"):
		player.start_turn()
	
	player.modulate = Color(1.5, 1.5, 1.5)
	
	var current_hand_size = hand.get_child_count()
	var cards_to_draw = CARDS_PER_TURN

	var draw_reduction = 0
	if player and "draw_reduction_stacks" in player:
		draw_reduction = player.draw_reduction_stacks
	cards_to_draw = max(0, cards_to_draw - draw_reduction)

	var space_in_hand = HAND_LIMIT - current_hand_size
	var final_draw_count = min(cards_to_draw, space_in_hand)
	
	if final_draw_count > 0:
		var new_cards = await deck.draw_cards(final_draw_count)
		for card in new_cards:
			hand.add_card(card)
			if player and "cards_drawn_this_turn" in player:
				player.cards_drawn_this_turn += 1
			await get_tree().create_timer(0.2).timeout
	else:
		print("No cards drawn!")
	
	current_state = State.PLAYER_ACTION

func end_player_turn():
	if current_state != State.PLAYER_ACTION:
		return
	
	print("Player turn ended. Discarding all cards...")
	
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
