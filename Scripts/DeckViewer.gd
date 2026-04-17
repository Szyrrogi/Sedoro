extends Control

@export var card_scene: PackedScene   # Przypisz res://Object/Card.tscn
@export var card_grid: Container      # Przypisz CardGrid (HFlowContainer)
@export var close_button: Button      # Przypisz CloseButton

# Przypisz te same węzły co w GameManager / MapGenerator
@export var map_node: Node
@export var combat_node: Node

# Co było widoczne przed otwarciem – skrypt sam zapamięta
var _hidden_node: Node = null

func _ready():
	visible = false
	if close_button:
		close_button.pressed.connect(hide_viewer)

func show_deck(deck_data: Array, discard_data: Array = []):
	if not card_grid or not card_scene:
		push_error("DeckViewer: brak przypisanego card_grid lub card_scene!")
		return

	# Zapamiętaj co teraz widać i schowaj to
	_hidden_node = null
	if map_node and map_node.visible:
		_hidden_node = map_node
	elif combat_node and combat_node.visible:
		_hidden_node = combat_node

	if _hidden_node:
		_hidden_node.hide()

	# Wyczyść stare karty
	for child in card_grid.get_children():
		child.queue_free()

	# Połącz talię + odrzucone
	var all_cards = deck_data.duplicate()
	if discard_data.size() > 0:
		all_cards.append_array(discard_data)

	for card_id in all_cards:
		var wrapper = Control.new()
		wrapper.custom_minimum_size = Vector2(180, 260)
		wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var card_inst = card_scene.instantiate()
		wrapper.add_child(card_inst)

		if card_inst.has_method("setup_card"):
			card_inst.setup_card(card_id)

		card_inst.scale_normal = Vector2(0.45, 0.45)
		card_inst.scale_hover  = Vector2(0.5,  0.5)
		card_inst.scale        = Vector2(0.45, 0.45)

		if card_inst.has_method("set_start_position"):
			card_inst.set_start_position(Vector2(90, 130))

		_disable_mouse(card_inst)
		card_grid.add_child(wrapper)

	visible = true

func hide_viewer():
	visible = false

	# Przywróć to co było widoczne wcześniej
	if _hidden_node and is_instance_valid(_hidden_node):
		_hidden_node.show()
	_hidden_node = null

	# Wyczyść karty
	for child in card_grid.get_children():
		child.queue_free()

func _disable_mouse(node: Node):
	if node is CollisionObject2D:
		node.input_pickable = false
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_disable_mouse(child)
