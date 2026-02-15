extends Node2D
const CARD_SCENE_PATH = "res://Object/Card.tscn"
var player_deck = [1, 0, 0, 1, 0, 1, 0]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print($Area2D.collision_layer)
	#draw_card()
	#draw_card()
	#draw_card()

	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func draw_card():
	var card_dream = player_deck[0]
	player_deck.erase(card_dream)
	
	if player_deck.size() == 0:
		$Area2D/CollisionShape2D.disabled= true
		$Sprite2D.visible = false
		
	print("d")
	var card_scene = preload(CARD_SCENE_PATH)

	var new_card = card_scene.instantiate()
	$"../../CardManager".add_child(new_card)
	new_card.name = "card"
	$"../../Hand".add_card_to_hand(new_card)
