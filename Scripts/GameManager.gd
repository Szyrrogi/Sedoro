extends Node

@export var use_random_encounters: bool = true

# --- NODES TO ASSIGN IN INSPECTOR ---
@export var combat_node: Node
@export var map_node: Node

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
@export var spawn_start_position: Vector2 = Vector2(1300, 500) 
@export var spawn_spacing: float = 300.0 

@export var custom_enemy_count: int = 0
@export var default_enemy_id: int = 1

enum State { PLAYER_START, PLAYER_ACTION, ENEMY_TURN, BATTLE_ENDED }
var current_state = State.PLAYER_START

const HAND_LIMIT = 10       # Maksymalna liczba kart w ręce
const CARDS_PER_TURN = 7    # Kart dobieranych na początku tury
const MANA_MAX = 6

var mana = 0  # Tura zaczyna się z 0 many

func _ready():
	if end_turn_button:
		end_turn_button.pressed.connect(_on_end_turn_button_pressed)

func start_combat(horde_data: Array = []):
	print("\n--- INITIALIZING NEW COMBAT ---")
	
	# === 1. CARD CLEANUP ===
	var leftover_cards = hand.get_all_cards().duplicate()
	for card in leftover_cards:
		card.set_selected(false)
		hand.remove_card(card)
		discard.add_to_discard(card)
		
	await get_tree().create_timer(0.25).timeout
	
	if discard.discard_data.size() > 0:
		await deck.reshuffle_from_discard()
	
	# === 2. RESET STATE ===
	mana = 0
	current_state = State.PLAYER_START
	player.modulate = Color(1, 1, 1)
	
	if player.has_method("reset_combat_stats"):
		player.reset_combat_stats()
	else:
		if "armor" in player: player.armor = 0
		if "block" in player: player.block = 0

	if passive_manager and passive_manager.has_method("clear_all_passives"):
		passive_manager.clear_all_passives()
	
	# === 3. START NEW ENCOUNTER ===
	spawn_horde(horde_data)
	
	await get_tree().create_timer(0.5).timeout
	start_player_turn()

func win_battle():
	print("Combat won! Returning to map.")
	current_state = State.BATTLE_ENDED 
	
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
	
	# Tura zawsze zaczyna się od 0 many
	mana = 0
	card_manager.redraws_used = 0
	
	if player and "cards_drawn_this_turn" in player:
		player.cards_drawn_this_turn = 0

	if passive_manager and passive_manager.has_method("trigger_all_passives"):
		passive_manager.trigger_all_passives()

	if player.has_method("start_turn"):
		player.start_turn()
	
	player.modulate = Color(1.5, 1.5, 1.5)
	
	# Liczymy ile miejsca zostało w ręce (maks 10)
	var current_hand_size = hand.get_child_count()
	var cards_to_draw = CARDS_PER_TURN

	# Uwzględnij draw_reduction (np. Twarda Głowa)
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
	
	# Na końcu tury WSZYSTKIE karty z ręki idą do odrzuconych
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

func get_random_enemy_encounter() -> Array:
	var possible_encounters = [
		[0, 0, 0], [1, 1, 1], [2, 2, 2], [3, 3, 3], [4, 4, 4],
		[5, 5, 5], [6, 6, 6], [7, 7, 7], [8, 8, 8], [9, 9, 9],
	]
	var chosen = possible_encounters.pick_random()
	chosen.shuffle()
	return chosen
