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
	
	# Animacja wlotu do discardu (opcjonalna, szybka)
	var tween = create_tween()
	tween.tween_property(card, "position", Vector2.ZERO, 0.2)
	tween.tween_property(card, "scale", Vector2(0.1, 0.1), 0.2)
	tween.tween_callback(card.queue_free) # Po animacji -> USUŃ Z PAMIĘCI
	
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
