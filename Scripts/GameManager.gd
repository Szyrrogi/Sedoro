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
const MAX_MANA = 8

var mana = 5

func _ready():
	# Czekamy chwilę na start gry, żeby wszystko się załadowało
	if end_turn_button:
		end_turn_button.pressed.connect(_on_end_turn_button_pressed)
	await get_tree().create_timer(0.5).timeout
	start_player_turn()
	
func _process(delta):
	mana_text.text = mana + "/" + MAX_MANA
	
	
func _on_end_turn_button_pressed():
	# Dla bezpieczeństwa sprawdzamy czy to na pewno faza akcji
	if current_state == State.PLAYER_ACTION:
		end_player_turn()

func start_player_turn():
	current_state = State.PLAYER_START
	print("\n--- POCZĄTEK TURY GRACZA ---")
	
	# --- LOGIKA DOBIERANIA ---
	var current_hand_size = hand.get_child_count()
	
	# Ile chcemy dobrać? (Domyślnie 3)
	var cards_to_draw = CARDS_PER_TURN
	
	# Sprawdzamy limit ręki (5)
	var space_in_hand = HAND_LIMIT - current_hand_size
	
	# Jeśli mamy mało miejsca, dobieramy tylko tyle ile wejdzie
	# Jeśli np. mamy 4 karty, space=1. Chcemy dobrać 3. min(3, 1) = 1.
	# Jeśli mamy 0 kart, space=5. min(3, 5) = 3.
	var final_draw_count = min(cards_to_draw, space_in_hand)
	
	if final_draw_count > 0:
		print("Dobieram: ", final_draw_count, " kart.")
		
		# --- TU BYŁ BŁĄD ---
		# Było: var new_cards = deck.draw_cards(final_draw_count)
		
		# MA BYĆ (dodaj 'await'):
		var new_cards = await deck.draw_cards(final_draw_count)
		
		# Teraz kod grzecznie poczeka, aż karty przylecą z Discardu (jeśli było tasowanie)
		# i dopiero wtedy wykona to co poniżej:
		
		for card in new_cards:
			hand.add_card(card)
			await get_tree().create_timer(0.2).timeout
	else:
		print("Ręka pełna, nie dobieram.")
	
	current_state = State.PLAYER_ACTION
	print("Faza akcji: Wybierz do 3 kart.")

# Tę funkcję musisz podpiąć pod jakiś guzik w UI "End Turn"
# albo wywołać spacją w _input
func end_player_turn():
	if current_state != State.PLAYER_ACTION:
		return
		
	print("Koniec tury gracza. Rozpatrywanie...")
	
	# --- LOGIKA ODRZUCANIA ---
	# Kopiujemy listę kart, bo będziemy modyfikować dzieci Handa
	var cards_in_hand = hand.get_all_cards().duplicate()
	
	for card in cards_in_hand:
		if card.is_selected:
			# Wybrane karty zostają na ręce (według Twojego opisu)
			# Opcjonalnie: Resetujemy ich zaznaczenie na nową turę?
			# card.set_selected(false) 
			pass
		else:
			# Niewybrane lecą na śmietnik
			discard.add_to_discard(card)
			
	# Przejście do tury wroga
	start_enemy_turn()

func start_enemy_turn():
	current_state = State.ENEMY_TURN
	print("Tura przeciwnika...")
	
	# Symulacja myślenia wroga
	await get_tree().create_timer(1.5).timeout
	
	print("Przeciwnik zakończył ruch.")
	# Powrót do gracza
	start_player_turn()
	
func set_button_active(is_active: bool):
	if end_turn_button:
		end_turn_button.disabled = !is_active
		# Opcjonalnie zmień tekst
		if is_active:
			end_turn_button.text = "ZAKOŃCZ TURĘ"
		else:
			end_turn_button.text = "CZEKAJ..."

# Tymczasowe sterowanie spacją do testów
func _input(event):
	if event.is_action_pressed("ui_accept"): # Spacja
		end_player_turn()
