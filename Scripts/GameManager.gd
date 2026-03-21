extends Node

# --- WĘZŁY DO PRZECIĄGNIĘCIA W INSPEKTORZE (DO POWROTU NA MAPĘ) ---
@export var walka_node: Node     # Cały duży węzeł WALKA
@export var mapa_node: Node      # Cały duży węzeł MAPA

# Referencje do innych systemów
@export var deck: Node2D
@export var hand: Node2D
@export var discard: Node2D
@export var end_turn_button: Button
@export var shuffle_button: Button 
@export var mana_manager: Node2D
@export var player: Node2D
@export var card_manager: Node2D

@export var enemies: Array[Node] 
@export var enemy_scene: PackedScene 
@export var spawn_start_position: Vector2 = Vector2(1300, 500) 
@export var spawn_spacing: float = 300.0 

enum State { PLAYER_START, PLAYER_ACTION, ENEMY_TURN, BATTLE_ENDED }
var current_state = State.PLAYER_START

const HAND_LIMIT = 5
const CARDS_PER_TURN = 3
const CARDS_START = 4 
const MANA_MAX = 5
const SHUFFLE_COST = 2 

var is_first_turn: bool = true 
var mana = 6

func _ready():
	# Podpinamy tylko przyciski, nie zaczynamy walki!
	if end_turn_button:
		end_turn_button.pressed.connect(_on_end_turn_button_pressed)
		
	if shuffle_button:
		shuffle_button.pressed.connect(_on_shuffle_button_pressed)

# Funkcja odpalana przez Mapę
func start_combat(horde_id: int = 0):
	print("\n--- INICJALIZACJA NOWEJ WALKI ---")
	
	# === 1. WIELKIE SPRZĄTANIE KART ===
	# Bierzemy wszystkie karty, które zostały graczowi na ręce po wygranej...
	var leftover_cards = hand.get_all_cards().duplicate()
	for card in leftover_cards:
		card.set_selected(false)
		hand.remove_card(card)
		discard.add_to_discard(card) # ...i wrzucamy je do odrzuconych
		
	# Czekamy ułamek sekundy, aby animacja odrzucania kart zdążyła się wykonać
	await get_tree().create_timer(0.25).timeout
	
	# Teraz nasz kosz zawiera wszystkie zagrane karty ORAZ te, które zostały na ręce.
	# Zmuszamy talię, by wciągnęła cały kosz i go przetasowała.
	if discard.discard_data.size() > 0:
		print("Tasuję odrzucone karty z powrotem do talii...")
		await deck.reshuffle_from_discard()
	
	# === 2. RESET STANU GRY I GRACZA ===
	is_first_turn = true
	mana = MANA_MAX
	current_state = State.PLAYER_START
	player.modulate = Color(1, 1, 1)
	
	# Resetujemy pancerz gracza korzystając z funkcji, którą dodaliśmy w Krok 1
	if player.has_method("reset_combat_stats"):
		player.reset_combat_stats()
	else:
		# Awaryjnie (jeśli zapomnisz dodać funkcję do Player.gd)
		if "armor" in player: player.armor = 0
		if "block" in player: player.block = 0
	
	# === 3. START NOWEGO STARCIA ===
	spawn_horde(horde_id)
	
	await get_tree().create_timer(0.5).timeout
	start_player_turn()

func win_battle():
	print("Walka wygrana! Wracam na mapę.")
	current_state = State.BATTLE_ENDED # <--- TO BLOKUJE DALSZE TURY
	
	if walka_node and mapa_node:
		walka_node.hide() 
		mapa_node.show()  
		
func lose_battle():
	print("Walka przegrana!")
	current_state = State.BATTLE_ENDED # <--- TO BLOKUJE DALSZE TURY
	# Tu w przyszłości odpalisz ekran Game Over

func spawn_horde(horde_id: int):
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	enemies.clear() 
	
	const EnemyDatabase = preload("res://Scripts/EnemyDatabase.gd")
	if not EnemyDatabase.HORD.has(horde_id):
		push_error("Brak hordy o ID: " + str(horde_id))
		return
		
	var horde = EnemyDatabase.HORD[horde_id]
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
	
	if shuffle_button:
		var discard_count = discard.discard_data.size()
		shuffle_button.visible = discard_count > 0 
		shuffle_button.disabled = mana < SHUFFLE_COST or current_state != State.PLAYER_ACTION

func _on_shuffle_button_pressed():
	if current_state == State.PLAYER_ACTION and mana >= SHUFFLE_COST:
		mana -= SHUFFLE_COST
		print("Ręczne przenoszenie odrzuconych kart do talii...")
		
		await deck.reshuffle_from_discard()
		var new_cards = deck.draw_cards(1)
		
		if new_cards.size() > 0:
			var new_card = new_cards[0]
			hand.add_card(new_card)
			
		print("Karty przetasowane i dobrano 1 kartę! Pozostała mana: ", mana)

func _on_end_turn_button_pressed():
	if current_state == State.PLAYER_ACTION:
		end_player_turn()

func start_player_turn():
	current_state = State.PLAYER_START
	print("\n--- POCZĄTEK TURY GRACZA ---")
	mana = MANA_MAX
	card_manager.redraws_used = 0
	
	if player.has_method("start_tunr"):
		player.start_tunr() 
	
	player.modulate = Color(1.5, 1.5, 1.5)
	
	var current_hand_size = hand.get_child_count()
	var cards_to_draw = CARDS_START if is_first_turn else CARDS_PER_TURN
	var space_in_hand = HAND_LIMIT - current_hand_size
	
	var final_draw_count = min(cards_to_draw, space_in_hand)
	
	if final_draw_count > 0:
		print("Dobieram: ", final_draw_count, " kart.")
		var new_cards = await deck.draw_cards(final_draw_count)
		for card in new_cards:
			hand.add_card(card)
			await get_tree().create_timer(0.2).timeout
	else:
		print("Nic nie dobierasz! (Ręka pełna lub redukcja dobierania)")
	
	is_first_turn = false 
	current_state = State.PLAYER_ACTION

func end_player_turn():
	if current_state != State.PLAYER_ACTION:
		return
	
	print("Koniec tury gracza. Czas na sprzątanie...")
	
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
	print("Tura przeciwnika...")
	
	player.modulate = Color(1, 1, 1)
	
	for enemy in enemies:
		if is_instance_valid(enemy): 
			enemy.modulate = Color(1.5, 1.5, 1.5)
			enemy.action()
			
			await get_tree().create_timer(1).timeout
			
			# --- ZMIANA: Zabezpieczenie po odczekaniu czasu ---
			# Sprawdzamy, czy po tej 1 sekundzie wróg nadal istnieje
			if is_instance_valid(enemy):
				enemy.modulate = Color(1, 1, 1)
				
			# Jeśli wróg zabił się o nas i wygraliśmy walkę, natychmiast przerywamy pętlę!
			if current_state == State.BATTLE_ENDED:
				break
		
	await get_tree().create_timer(1).timeout
	
	# ZMIANA TUTAJ: Sprawdzamy czy walka się nie skończyła w międzyczasie (np. od trucizny)
	if current_state != State.BATTLE_ENDED:
		print("Przeciwnik zakończył ruch.")
		start_player_turn()
	else:
		print("Walka zakończona w trakcie tury przeciwnika. Zatrzymuję pętlę.")
	
func set_button_active(is_active: bool):
	if end_turn_button:
		end_turn_button.disabled = !is_active
		if is_active:
			end_turn_button.text = "ZAKOŃCZ TURĘ"
		else:
			end_turn_button.text = "CZEKAJ..."

func _input(event):
	if event.is_action_pressed("ui_accept"):
		end_player_turn()
