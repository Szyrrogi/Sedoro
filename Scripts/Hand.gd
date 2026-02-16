extends Node2D

const CARD_WIDTH = 330.0
const HAND_CURVE = 0.0 # Jeśli chcesz łuk, zmień np na 0.1

func add_card(card: Node2D):
	add_child(card)
	# Ustawiamy kartę w pozycji 0,0 ręki, żeby animowała się z Decku
	# (Ale logicznie jest już dzieckiem ręki)
	recalculate_positions()

func remove_card(card: Node2D):
	if card.get_parent() == self:
		remove_child(card)
	recalculate_positions()

func get_all_cards() -> Array:
	return get_children()

func recalculate_positions():
	var cards = get_children()
	var card_count = cards.size()
	
	if card_count == 0:
		return
		
	# Obliczamy szerokość całej ręki
	var total_width = (card_count - 1) * CARD_WIDTH
	var start_x = -total_width / 2.0
	
	for i in range(card_count):
		var card = cards[i]
		
		# Obliczamy nową pozycję X
		var new_x = start_x + (i * CARD_WIDTH)
		
		# Ustawiamy target_position w skrypcie Karty (Card.gd)
		# Zakładamy, że Hand jest wyśrodkowany na ekranie w poziomie
		card.target_position = Vector2(new_x, 0) 
		
		# Opcjonalnie: Rotacja
		# card.rotation = (i - (card_count - 1) / 2.0) * 0.1
