extends Node2D

@onready var input_manager = $"../InputManager"
@onready var hand = $"../Hand"

const MAX_SELECTED_CARDS = 3

# Stan
var dragged_card: Node2D = null
var hovered_card: Node2D = null

func _ready():
	await get_tree().process_frame
	input_manager.connect("card_left_clicked", _on_card_left_clicked)
	input_manager.connect("card_right_clicked", _on_card_right_clicked) # NOWE
	input_manager.connect("left_mouse_button_released", _on_left_release)
	input_manager.connect("background_clicked", _on_background_clicked)

func _process(delta):
	# 1. OBSŁUGA DRAG (Ruszanie kartą)
	if dragged_card:
		# Karta podąża za myszką
		dragged_card.global_position = get_global_mouse_position()
		# Opcjonalnie: Delikatne opóźnienie (lerp) dla płynności:
		# dragged_card.global_position = lerp(dragged_card.global_position, get_global_mouse_position(), 25 * delta)
		return # Jak ciągniemy, to nie sprawdzamy hovera

	# 2. OBSŁUGA HOVER (Powiększanie po najechaniu)
	# Pytamy InputManagera co jest pod myszką
	var result = input_manager.raycast_at_cursor()
	var new_hovered_card = null
	
	if result and result.collider.collision_mask == input_manager.COLLISION_MASK_CARD:
		new_hovered_card = result.collider.get_parent()
	
	# Jeśli zmieniliśmy kartę nad którą jest myszka
	if new_hovered_card != hovered_card:
		if hovered_card:
			hovered_card.set_hovered(false) # Stara maleje
		if new_hovered_card:
			new_hovered_card.set_hovered(true) # Nowa rośnie
		hovered_card = new_hovered_card

# --- LEWY PRZYCISK (DRAG) ---
func _on_card_left_clicked(card):
	if card.get_parent() == hand: # Można ruszać tylko kartami z ręki
		dragged_card = card
		card.is_dragged = true # Wyłączamy fizykę powrotu w karcie
		card.z_index = 100 # Wyciągamy na sam wierzch
		card.set_hovered(false) # Reset skali, żeby nie wariowała przy dragu

func _on_left_release():
	if dragged_card:
		dragged_card.is_dragged = false # Włączamy powrót na miejsce
		dragged_card.z_index = 0 # Wracamy do warstwy
		# Hand przeliczy Z-indexy poprawnie w następnej klatce jeśli trzeba
		dragged_card = null

# --- PRAWY PRZYCISK (SELECTION) ---
func _on_card_right_clicked(card):
	if card.get_parent() == hand:
		toggle_card_selection(card)

# --- LOGIKA ZAZNACZANIA (BEZ ZMIAN) ---
func toggle_card_selection(card):
	if card.is_selected:
		card.set_selected(false)
	else:
		if get_selected_count() < MAX_SELECTED_CARDS:
			card.set_selected(true)
		else:
			print("Limit kart!") # Tu dodaj dźwięk błędu

func get_selected_count() -> int:
	var count = 0
	for c in hand.get_all_cards():
		if c.is_selected: count += 1
	return count

func _on_background_clicked():
	pass # Opcjonalnie odznaczanie wszystkiego
