extends Node2D

@export var card_scene: PackedScene 
@export var discard_ref: Node2D # PRZYPISZ TU DISCARD W INSPEKTORZE!

var deck_data = [1, 2, 3, 4, 5, 6, 7, 8, 9] # Przykładowe dane startowe

func _ready():
	randomize()
	deck_data.shuffle()
	update_visuals()

func draw_cards(amount: int) -> Array:
	var drawn_cards = []
	
	for i in range(amount):
		# SPRAWDZANIE CZY MAMY KARTY
		if deck_data.is_empty():
			print("Talia pusta! Próba przetasowania...")
			
			# Sprawdź czy Discard ma karty
			if discard_ref.discard_data.is_empty():
				print("Koniec gry! Brak kart w talii i w śmietniku.")
				break # Przerywamy dobieranie
			
			# Jeśli są karty w Discardzie -> Animacja i tasowanie
			# Używamy 'await', żeby kod poczekał na koniec animacji tasowania
			await reshuffle_from_discard()
		
		# Dobieranie właściwe (po ewentualnym przetasowaniu)
		if not deck_data.is_empty():
			var card_id = deck_data.pop_front()
			var new_card = create_card_instance(card_id)
			drawn_cards.append(new_card)
			
	update_visuals()
	return drawn_cards

func reshuffle_from_discard():
	print("Tasowanie odrzuconych kart...")
	
	# 1. Pobierz dane ze śmietnika
	var new_cards = discard_ref.take_all_cards()
	
	# 2. Animacja powrotu kart (wizualny bajer)
	await animate_reshuffle(new_cards.size())
	
	# 3. Dodaj do talii i potasuj
	deck_data.append_array(new_cards)
	deck_data.shuffle()
	
	print("Przetasowano! Nowa ilość kart: ", deck_data.size())
	update_visuals()

func animate_reshuffle(count: int):
	# Tworzymy kilka "fejkowych" kart, które lecą z Discardu do Decku
	var visuals_count = min(count, 5) # Max 5 sprite'ów, żeby nie zabić wydajności
	
	for i in range(visuals_count):
		var fake_card = Sprite2D.new()
		# Ustaw teksturę rewersu karty
		# fake_card.texture = load("res://tyl_karty.png") 
		# Na razie użyjmy placeholder:
		fake_card.texture = load("res://icon.svg") # Zmień na swoją ikonę karty!
		fake_card.scale = Vector2(0.2, 0.2) # Dopasuj skalę
		
		get_tree().root.add_child(fake_card) # Dodajemy do roota, żeby latały nad wszystkim
		fake_card.global_position = discard_ref.global_position
		
		var tween = create_tween()
		# Losowy czas i lekki rozrzut, żeby nie leciały w linii
		var duration = randf_range(0.3, 0.6)
		tween.tween_property(fake_card, "global_position", global_position, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tween.tween_callback(fake_card.queue_free) # Usuń fejk po dolocie
		
		# Czekamy chwilkę między kartami
		await get_tree().create_timer(0.1).timeout
	
	# Czekamy na koniec ostatniej animacji
	await get_tree().create_timer(0.5).timeout

func create_card_instance(card_id) -> Node2D:
	var card = card_scene.instantiate()
	card.position = global_position
	# WAŻNE: Przekazujemy ID do nowej karty
	if card.has_method("setup_card"):
		card.setup_card(card_id)
	return card

func update_visuals():
	# Ukryj/Pokaż talię
	visible = !deck_data.is_empty()
