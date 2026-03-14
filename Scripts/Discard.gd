extends Node2D

var discard_data: Array = [] # Tu trzymamy same ID (liczby)

func _ready():
	update_visuals()

# Funkcja przyjmuje fizyczną kartę, kradnie jej duszę (ID) i niszczy ciało
func add_to_discard(card: Node2D):
	if "id" in card:
		discard_data.append(card.id)
	else:
		push_error("Karta bez ID! Dodaję 0.")
		discard_data.append(0)
	
	# --- ZMIANA: Przejęcie karty z ręki do węzła Discard ---
	var start_global_pos = card.global_position
	var parent = card.get_parent()
	if parent:
		parent.remove_child(card) # Odpinamy z ręki, więc zniknie z get_children() w Hand
	
	add_child(card) # Podpinamy pod Discard
	card.global_position = start_global_pos # Przywracamy pozycję ekranową, żeby karta nie przeskoczyła
	# -------------------------------------------------------
	
	# Animacja wlotu do discardu
	var tween = create_tween()
	# Teraz Vector2.ZERO oznacza środek stosu Discard, a nie środek ręki
	tween.tween_property(card, "position", Vector2.ZERO, 0.2) 
	tween.tween_property(card, "scale", Vector2(0.1, 0.1), 0.2)
	tween.tween_callback(card.queue_free) 
	
	update_visuals()

# Funkcja dla Decku: "Daj mi wszystko co masz i zapomnij"
func take_all_cards() -> Array:
	var cards_to_return = discard_data.duplicate()
	discard_data.clear()
	update_visuals()
	return cards_to_return

func update_visuals():
	# Jeśli masz tu Sprite2D jako dziecko, to nim sterujemy
	# Zakładam, że Sprite to np. $Sprite2D
	if has_node("Sprite2D"):
		$Sprite2D.visible = !discard_data.is_empty()
		
		# Opcjonalnie: Zmień teksturę w zależności od ilości kart
		# if discard_data.size() > 10: ...
