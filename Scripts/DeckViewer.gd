extends Control

@export var card_scene: PackedScene        # Przypisz res://Object/Card.tscn
@export var card_grid: GridContainer       # GridContainer z columns = 8
@export var preview_container: Control     # Panel po prawej – miejsce na podgląd
@export var close_button: Button

@export var map_node: Node
@export var combat_node: Node

const SLOT_COUNT   = 32          # 8 kolumn × 4 wiersze
const SLOT_SIZE    = Vector2(135, 175)
const CARD_SCALE   = Vector2(0.0113, 0.0113)

var _hidden_node: Node = null
var _preview_card: Node = null   # aktualnie wyświetlana karta w podglądzie

# ─────────────────────────────────────────
func _ready():
	visible = false
	if close_button:
		close_button.pressed.connect(hide_viewer)

# ─────────────────────────────────────────
func show_deck(deck_data: Array, discard_data: Array = []):
	if not card_grid or not card_scene:
		push_error("DeckViewer: brak card_grid lub card_scene!")
		return

	# Zapamiętaj i ukryj aktywny widok
	_hidden_node = null
	if map_node and map_node.visible:
		_hidden_node = map_node
	elif combat_node and combat_node.visible:
		_hidden_node = combat_node
	if _hidden_node:
		_hidden_node.hide()

	_clear_grid()
	_clear_preview()

	var all_cards = deck_data.duplicate()
	if discard_data.size() > 0:
		all_cards.append_array(discard_data)

	# Wypełnij 32 sloty (puste lub z kartą)
	for i in range(SLOT_COUNT):
		var slot = _make_slot()

		if i < all_cards.size():
			var card_id  = all_cards[i]
			var card_inst = card_scene.instantiate()
			slot.add_child(card_inst)

			if card_inst.has_method("setup_card"):
				card_inst.setup_card(card_id)
			var Wektor2 = Vector2(0.36, 0.36)
			card_inst.scale_normal = Wektor2
			card_inst.scale_hover  = Wektor2
			card_inst.scale        = Wektor2
			if card_inst.frame:
				card_inst.frame.scale = Wektor2
			if card_inst.has_method("set_start_position"):
				card_inst.set_start_position(Vector2(116, -40))

			# Wyłącz interakcję samej karty – obsługujemy hover przez slot
			_disable_mouse(card_inst)

			# Hover przez slot
			slot.mouse_entered.connect(_on_slot_hover.bind(card_id))
			slot.mouse_exited.connect(_on_slot_exit)

		card_grid.add_child(slot)

	visible = true

# ─────────────────────────────────────────
func hide_viewer():
	visible = false
	_clear_grid()
	_clear_preview()
	if _hidden_node and is_instance_valid(_hidden_node):
		_hidden_node.show()
	_hidden_node = null

# ─────────────────────────────────────────
# Hover – pokaż kartę w panelu podglądu
func _on_slot_hover(card_id: int):
	_clear_preview()
	if not preview_container or not card_scene:
		return

	var card_inst = card_scene.instantiate()
	preview_container.add_child(card_inst)

	if card_inst.has_method("setup_card"):
		card_inst.setup_card(card_id)

	# Karta w podglądzie w pełnym rozmiarze, wyśrodkowana
	var preview_scale = Vector2(0.75, 0.75)
	card_inst.scale_normal = preview_scale
	card_inst.scale_hover  = preview_scale
	card_inst.scale        = preview_scale
	if card_inst.frame:
		card_inst.frame.scale = preview_scale
	if card_inst.has_method("set_start_position"):
		card_inst.set_start_position(preview_container.size / 2)

	_disable_mouse(card_inst)
	_preview_card = card_inst

func _on_slot_exit():
	# Możesz zostawić ostatnią kartę widoczną (wygodniejsze)
	# lub wyczyścić: _clear_preview()
	pass

# ─────────────────────────────────────────
# Pomocnicze
func _make_slot() -> Control:
	var slot = Control.new()
	slot.custom_minimum_size = SLOT_SIZE
	slot.mouse_filter = Control.MOUSE_FILTER_STOP
	return slot

func _clear_grid():
	for child in card_grid.get_children():
		child.queue_free()

func _clear_preview():
	if is_instance_valid(_preview_card):
		_preview_card.queue_free()
	_preview_card = null
	if preview_container:
		for child in preview_container.get_children():
			child.queue_free()

func _disable_mouse(node: Node):
	if node is CollisionObject2D:
		node.input_pickable = false
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_disable_mouse(child)
