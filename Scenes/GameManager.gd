extends Node

# Referencje do innych systemów
@export var deck: Node2D
@export var hand: Node2D
@export var discard: Node2D
@export var end_turn_button: Button
@export var mana_text: RichTextLabel

# Prosta maszyna stanów
enum State { PLAYER_START, PLAYER_ACTION, ENEMY_TURN }
var current_state = State.PLAYER_START

const HAND_LIMIT = 5
const CARDS_PER_TURN = 3
const CARDS_START = 4 # Nowa stała dla pierwszej tury
const MANA_MAX = 4

var is_first_turn: bool = true # Flaga sprawdzająca, czy to początek gry
var mana = 4

func _ready():
	if end_turn_button:
		end_turn_button.pressed.connect(_on_end_turn_button_pressed)
	await get_tree().create_timer(0.5).timeout
	start_player_turn()
	
func _process(delta: float) -> void:
	mana_text.text = "[font_size=75]" + str(mana) + "/" + str(MANA_MAX)

func _on_end_turn_button_pressed():
	if current_state == State.PLAYER_ACTION:
		end_player_turn()

func start_player_turn():
	current_state = State.PLAYER_START
	print("\n--- POCZĄTEK TURY GRACZA ---")
	mana = MANA_MAX
	# --- LOGIKA DOBIERANIA ---
	var current_hand_size = hand.get_child_count()
	
	# Ile chcemy dobrać? 4 na start, potem po 3
	var cards_to_draw = CARDS_START if is_first_turn else CARDS_PER_TURN
	
	# Sprawdzamy limit ręki (5)
	var space_in_hand = HAND_LIMIT - current_hand_size
	
	# Dobieramy tylko tyle, na ile jest miejsce
	var final_draw_count = min(cards_to_draw, space_in_hand)
	
	if final_draw_count > 0:
		print("Dobieram: ", final_draw_count, " kart.")
		
		var new_cards = await deck.draw_cards(final_draw_count)
		
		for card in new_cards:
			hand.add_card(card)
			await get_tree().create_timer(0.2).timeout
	else:
		print("Ręka pełna! Masz 5 kart, więc nic nie dostajesz.")
	
	is_first_turn = false # Pierwsza tura za nami, wyłączamy flagę
	current_state = State.PLAYER_ACTION
	print("Faza akcji: Zrób coś mądrego z tymi kartami.")

func end_player_turn():
	if current_state != State.PLAYER_ACTION:
		return
		
	print("Koniec tury gracza. Czas na sprzątanie...")
	
	# Kopiujemy listę kart
	var cards_in_hand = hand.get_all_cards().duplicate()
	
	for card in cards_in_hand:
		if card.is_selected:
			# ZAZNACZONE lecą na śmietnik!
			card.set_selected(false) # Resetujemy stan wizualny przed wyrzuceniem
			hand.remove_card(card)   # Wyrywamy z ręki
			discard.add_to_discard(card) # Rzucamy na pożarcie do Discardu
		else:
			# Niezaznaczone grzecznie zostają na ręce
			pass
			
	# Przejście do tury wroga
	start_enemy_turn()

func start_enemy_turn():
	current_state = State.ENEMY_TURN
	print("Tura przeciwnika...")
	
	await get_tree().create_timer(1.5).timeout
	
	print("Przeciwnik zakończył ruch.")
	start_player_turn()
	
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
