extends Node2D

@export var card_scene: PackedScene 
@export var discard_ref: Node2D # PRZYPISZ TU DISCARD W INSPEKTORZE!

var deck_data = [22,23,24,25,26,5,7] # Przykładowe dane startowe
var card_database_reference = preload("res://Scripts/CardDatabase.gd")


func _ready():
	randomize()
	deck_data.shuffle()
	update_visuals()
	card_database_reference = preload("res://Scripts/CardDatabase.gd")

func draw_cards(amount: int) -> Array:
	var drawn_cards = []
	
	for i in range(amount):
		# Jeśli talia pusta — automatycznie tasujemy odrzucone (jak w Slay the Spire)
		if deck_data.is_empty():
			if discard_ref and discard_ref.discard_data.size() > 0:
				print("Talia pusta! Automatyczne tasowanie odrzuconych kart...")
				await reshuffle_from_discard()
			else:
				print("Talia pusta i brak kart w odrzuconych. Nie można dobrać więcej.")
				break
		
		# Dobieranie właściwe
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
	var visuals_count = min(count, 5)
	
	for i in range(visuals_count):
		var fake_card = Sprite2D.new()
		fake_card.texture = load("res://icon.svg") # Zmień na swoją ikonę karty!
		fake_card.scale = Vector2(0.2, 0.2)
		
		get_tree().root.add_child(fake_card)
		fake_card.global_position = discard_ref.global_position
		
		var tween = create_tween()
		var duration = randf_range(0.3, 0.6)
		tween.tween_property(fake_card, "global_position", global_position, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tween.tween_callback(fake_card.queue_free)
		
		await get_tree().create_timer(0.1).timeout
	
	await get_tree().create_timer(0.5).timeout

func create_card_instance(card_id) -> Node2D:
	var card = card_scene.instantiate()
	card.position = global_position
	if card.has_method("setup_card"):
		card.setup_card(card_id)
	return card

func update_visuals():
	visible = !deck_data.is_empty()
	
func add_card_to_deck(card_id: int):
	deck_data.append(card_id)
	print("Pomyślnie dodano kartę o ID: ", card_id, " do talii!")
