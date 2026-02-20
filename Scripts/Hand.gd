extends Node2D

const CARD_WIDTH = 330.0
const HAND_CURVE = 0.0 

# --- NOWE ZMIENNE SYSTEMU DOBIERANIA ---
const MAX_HAND = 5
const DRAW_AMOUNT = 3
const DRAW_START = 4

func add_card(card: Node2D):
	add_child(card)
	recalculate_positions()

func remove_card(card: Node2D):
	if card.get_parent() == self:
		remove_child(card)
	recalculate_positions()

func get_all_cards() -> Array:
	return get_children()

# Zwraca tylko te karty, które gracz sobie zaznaczył
func get_selected_cards() -> Array:
	var selected = []
	for card in get_children():
		if card.is_selected:
			selected.append(card)
	return selected

# Liczy, ile kart faktycznie możemy dobrać, pilnując limitu MAX_HAND
func get_draw_count(is_start_of_game: bool = false) -> int:
	var current_cards = get_children().size()
	var space_left = MAX_HAND - current_cards
	
	if space_left <= 0:
		return 0 # Ręka pełna, nic nie dobieramy
		
	var desired_draw = DRAW_START if is_start_of_game else DRAW_AMOUNT
	
	# Zwraca mniejszą wartość: albo to co chcemy dobrać, albo tyle, na ile jest miejsce
	return min(desired_draw, space_left)

func recalculate_positions():
	var cards = get_children()
	var card_count = cards.size()
	
	if card_count == 0:
		return
		
	var total_width = (card_count - 1) * CARD_WIDTH
	var start_x = -total_width / 2.0
	
	for i in range(card_count):
		var card = cards[i]
		var new_x = start_x + (i * CARD_WIDTH)
		card.target_position = Vector2(new_x, 0)
