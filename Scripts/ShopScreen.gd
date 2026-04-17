## ShopScreen.gd
## Dołącz do noda ShopScreen w hierarchii.
##
## Oczekiwana hierarchia sceny:
##
##  ShopScreen (Control, pełny ekran, ten skrypt)
##  ├── Background (ColorRect)
##  ├── TitleLabel (Label, "SKLEP")
##  │
##  ├── LeftPanel (VBoxContainer)           ← lewy panel: leczenie
##  │   ├── HealIcon (TextureRect)          (opcjonalne)
##  │   ├── HealLabel (Label, "Lecz się")
##  │   ├── HealCostLabel (Label, "10 złota")
##  │   └── HealButton (Button, "Kup")
##  │
##  ├── CenterPanel (VBoxContainer)         ← karty do kupienia
##  │   └── CardContainer (HBoxContainer)   ← tu trafiają karty
##  │
##  ├── RightPanel (VBoxContainer)          ← prawy panel: usuwanie karty
##  │   ├── RemoveLabel (Label, "Usuń kartę")
##  │   ├── RemoveCostLabel (Label, "50 złota")
##  │   └── RemoveButton (Button, "Wybierz kartę")
##  │
##  └── LeaveButton (Button, "Opuść sklep")
##
## W Inspektorze przypisz wszystkie poniższe @export.

extends Control

# --- Przypisz w Inspektorze ---
@export var game_manager: Node          # GameManager
@export var card_scene: PackedScene     # res://Object/Card.tscn
@export var card_container: Container   # CenterPanel/CardContainer (HBoxContainer)

@export var heal_button: Button
@export var heal_cost_label: Label      # pokazuje koszt leczenia
@export var remove_button: Button
@export var remove_cost_label: Label    # pokazuje koszt usunięcia
@export var leave_button: Button

# Podgląd talii (opcjonalne – przeciągnij DeckViewer)
@export var deck_viewer: Control        # DeckViewer node

# --- Konfiguracja ---
const SHOP_CARD_COUNT  = 4
const HEAL_COST        = 10
const HEAL_AMOUNT      = 20
const REMOVE_COST      = 50

# Karty do kupienia w bieżącym sklepie: Array of {card_id, price, node}
var shop_cards: Array = []

# Tryb usuwania karty z talii
var remove_mode: bool = false
var remove_card_nodes: Array = []  # karty talii pokazane do usunięcia

func _ready():
	visible = false
	if heal_button:   heal_button.pressed.connect(_on_heal_pressed)
	if remove_button: remove_button.pressed.connect(_on_remove_pressed)
	if leave_button:  leave_button.pressed.connect(_on_leave_pressed)

# ==========================================
# OTWIERANIE SKLEPU
# ==========================================

func open_shop():
	_clear_cards()
	remove_mode = false
	_generate_shop_cards()
	_refresh_buttons()
	visible = true

func _generate_shop_cards():
	if not card_container or not card_scene:
		push_error("ShopScreen: brak card_container lub card_scene!")
		return

	# Pula kart do sklepu – bierzemy losowe ID z CardDatabase
	# Zakładamy jakości 1-3; koszt = losowa_baza(80-120) * jakość
	var possible_ids = _get_shop_pool()
	possible_ids.shuffle()

	shop_cards.clear()

	for i in range(min(SHOP_CARD_COUNT, possible_ids.size())):
		var card_id  = possible_ids[i]
		var quality  = _get_card_quality(card_id)   # 1, 2 lub 3
		var base     = randi_range(80, 120)
		var price    = base * quality

		var wrapper = Control.new()
		wrapper.custom_minimum_size = Vector2(220, 340)

		var card_inst = card_scene.instantiate()
		wrapper.add_child(card_inst)
		if card_inst.has_method("setup_card"):
			card_inst.setup_card(card_id)

		card_inst.scale_normal = Vector2(0.55, 0.55)
		card_inst.scale_hover  = Vector2(0.6,  0.6)
		card_inst.scale        = Vector2(0.55, 0.55)
		if card_inst.has_method("set_start_position"):
			card_inst.set_start_position(Vector2(110, 150))
		_disable_mouse(card_inst)

		# Etykieta ceny pod kartą
		var price_label = Label.new()
		price_label.text = "💰 " + str(price)
		price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		price_label.add_theme_font_size_override("font_size", 24)
		price_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		price_label.offset_top = -40
		wrapper.add_child(price_label)

		# Przycisk kupna (przezroczysty, przykrywa kartę)
		var btn = Button.new()
		btn.set_anchors_preset(Control.PRESET_FULL_RECT)
		btn.flat = true
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.z_index = 10
		var idx = i
		btn.pressed.connect(func(): _on_buy_card(idx))
		wrapper.add_child(btn)

		card_container.add_child(wrapper)
		shop_cards.append({
			"card_id":    card_id,
			"price":      price,
			"wrapper":    wrapper,
			"price_label": price_label,
			"buy_button": btn,
			"sold":       false
		})

func _get_shop_pool() -> Array:
	# Zwraca listę ID kart dostępnych w sklepie.
	# Możesz rozszerzyć o CardDatabase.SHOP_POOL jeśli masz takę stałą.
	# Na razie losujemy spośród wszystkich kart z CardDatabase.
	const CardDatabase = preload("res://Scripts/CardDatabase.gd")
	var all_ids = CardDatabase.CARDS.keys()
	all_ids.shuffle()
	return all_ids

func _get_card_quality(card_id: int) -> int:
	# Odczytaj jakość z CardDatabase, jeśli pole istnieje (indeks 7 lub "quality").
	# Jeśli nie – zakładamy jakość 1.
	const CardDatabase = preload("res://Scripts/CardDatabase.gd")
	if CardDatabase.CARDS.has(card_id):
		var data = CardDatabase.CARDS[card_id]
		if data.size() > 7:
			return int(data[7])  # zakładamy że jakość jest na indeksie 7
	return 1  # fallback

# ==========================================
# KUPNO KARTY
# ==========================================

func _on_buy_card(idx: int):
	if idx >= shop_cards.size(): return
	var entry = shop_cards[idx]
	if entry["sold"]: return

	var price = entry["price"]
	if game_manager.gold < price:
		_flash_label(entry["price_label"], "Za mało złota!")
		return

	game_manager.gold -= price
	entry["sold"] = true

	# Dodaj kartę do talii
	if game_manager.deck and game_manager.deck.has_method("add_card_to_deck"):
		game_manager.deck.add_card_to_deck(entry["card_id"])

	# Wizualnie: przyciemnij wrapper i ustaw etykietę
	entry["wrapper"].modulate = Color(0.4, 0.4, 0.4, 0.6)
	entry["price_label"].text = "✓ Kupiono"
	entry["buy_button"].disabled = true

	_refresh_buttons()

# ==========================================
# LECZENIE
# ==========================================

func _on_heal_pressed():
	if not game_manager: return
	if game_manager.gold < HEAL_COST:
		return
	if not game_manager.player: return

	var player = game_manager.player
	var max_hp = player.max_health
	if player.current_health >= max_hp:
		return  # już pełne HP

	game_manager.gold -= HEAL_COST
	player.current_health = min(player.current_health + HEAL_AMOUNT, max_hp)

	if player.health_bar:
		player.health_bar.value = player.current_health

	_refresh_buttons()

# ==========================================
# USUWANIE KARTY Z TALII
# ==========================================

func _on_remove_pressed():
	if not game_manager: return
	if game_manager.gold < REMOVE_COST: return

	if remove_mode:
		_exit_remove_mode()
		return

	remove_mode = true
	_show_deck_for_removal()
	_refresh_buttons()

func _show_deck_for_removal():
	# Ukryj karty sklepu
	for entry in shop_cards:
		entry["wrapper"].visible = false

	# Wyczyść stare karty usuwania
	for n in remove_card_nodes:
		n.queue_free()
	remove_card_nodes.clear()

	if not game_manager.deck: return
	var deck_data = game_manager.deck.deck_data.duplicate()

	for card_id in deck_data:
		var wrapper = Control.new()
		wrapper.custom_minimum_size = Vector2(200, 300)

		var card_inst = card_scene.instantiate()
		wrapper.add_child(card_inst)
		if card_inst.has_method("setup_card"):
			card_inst.setup_card(card_id)
		card_inst.scale_normal = Vector2(0.5, 0.5)
		card_inst.scale_hover  = Vector2(0.55, 0.55)
		card_inst.scale        = Vector2(0.5,  0.5)
		if card_inst.has_method("set_start_position"):
			card_inst.set_start_position(Vector2(100, 150))
		_disable_mouse(card_inst)

		var btn = Button.new()
		btn.set_anchors_preset(Control.PRESET_FULL_RECT)
		btn.flat = true
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.z_index = 10
		var cid = card_id
		var wr  = wrapper
		btn.pressed.connect(func(): _confirm_remove(cid, wr))
		wrapper.add_child(btn)

		card_container.add_child(wrapper)
		remove_card_nodes.append(wrapper)

func _confirm_remove(card_id: int, wrapper: Control):
	if not game_manager: return
	if game_manager.gold < REMOVE_COST: return

	game_manager.gold -= REMOVE_COST

	# Usuń z talii
	if game_manager.deck:
		var idx = game_manager.deck.deck_data.find(card_id)
		if idx != -1:
			game_manager.deck.deck_data.remove_at(idx)

	_exit_remove_mode()

func _exit_remove_mode():
	remove_mode = false

	for n in remove_card_nodes:
		n.queue_free()
	remove_card_nodes.clear()

	# Przywróć karty sklepu
	for entry in shop_cards:
		entry["wrapper"].visible = true

	_refresh_buttons()

# ==========================================
# WYJŚCIE ZE SKLEPU
# ==========================================

func _on_leave_pressed():
	if remove_mode:
		_exit_remove_mode()
	_clear_cards()
	visible = false
	if game_manager and game_manager.has_method("return_to_map"):
		game_manager.return_to_map()

# ==========================================
# PODGLĄD TALII
# ==========================================

func open_deck_viewer():
	if not deck_viewer: return
	if not game_manager: return
	var deck_data    = game_manager.deck.deck_data    if game_manager.deck    else []
	var discard_data = game_manager.discard.discard_data if game_manager.discard else []
	if deck_viewer.has_method("show_deck"):
		deck_viewer.show_deck(deck_data, discard_data)

# ==========================================
# POMOCNICZE
# ==========================================

func _refresh_buttons():
	if not game_manager: return

	# Przycisk leczenia
	if heal_button:
		var full_hp = (game_manager.player and
			game_manager.player.current_health >= game_manager.player.max_health)
		heal_button.disabled = (game_manager.gold < HEAL_COST or full_hp)

	if heal_cost_label:
		heal_cost_label.text = "Koszt: " + str(HEAL_COST) + " 💰"

	# Przycisk usuwania
	if remove_button:
		remove_button.disabled = (game_manager.gold < REMOVE_COST)
		remove_button.text = ("Anuluj" if remove_mode else "Wybierz kartę")

	if remove_cost_label:
		remove_cost_label.text = "Koszt: " + str(REMOVE_COST) + " 💰"

func _clear_cards():
	if card_container:
		for child in card_container.get_children():
			child.queue_free()
	shop_cards.clear()

func _flash_label(label: Label, msg: String):
	if not label: return
	var original = label.text
	label.text = msg
	await get_tree().create_timer(1.5).timeout
	if is_instance_valid(label):
		label.text = original

func _disable_mouse(node: Node):
	if node is CollisionObject2D:
		node.input_pickable = false
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_disable_mouse(child)
