extends Node2D

const CARD_WIDTH = 200
const HAND_Y_POSITION = 880

var player_hand = []
var center_screen_x
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	center_screen_x = get_viewport().size.x /2
	
	
	
		
func add_card_to_hand(card):
	if card not in player_hand:
		player_hand.insert(0, card)
		update_hand_position()
	else:
		animate_card_to_position(card, card.starting_position)
	
	
func update_hand_position():
	for i in range(player_hand.size()):
		var new_position = Vector2(calculate_card_position(i), HAND_Y_POSITION)
		print(new_position)
		var card = player_hand[i]
		card.starting_position = new_position
		animate_card_to_position(card, new_position)
		
func calculate_card_position(index):
	var total_width = (player_hand.size() - 1) * CARD_WIDTH
	var x_offset = center_screen_x + index * CARD_WIDTH - total_width / 2
	return x_offset
		#
func animate_card_to_position(card, new_position):
	var tween = get_tree().create_tween()
	tween.tween_property(card, "position", new_position, 0.1)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func remove_card_fraom_hand(card):
	if card in player_hand:
		player_hand.erase(card)
		update_hand_position()
