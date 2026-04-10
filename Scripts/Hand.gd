extends Node2D

const CARD_WIDTH = 330.0
const HAND_CURVE = 0.0 

# --- SYSTEM DOBIERANIA ---
const MAX_HAND = 10
const DRAW_AMOUNT = 7

func add_card(card: Node2D):
	add_child(card)
	recalculate_positions()

func remove_card(card: Node2D):
	if card.get_parent() == self:
		remove_child(card)
	recalculate_positions()

func get_all_cards() -> Array:
	return get_children()

func get_selected_cards() -> Array:
	var selected = []
	for card in get_children():
		if card.is_selected:
			selected.append(card)
	return selected

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
