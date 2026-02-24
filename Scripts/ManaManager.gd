extends Node2D

@export var mana_sprite: Sprite2D
@export var mana2_sprite: Sprite2D
# Called when the node enters the scene tree for the first time.
func set_mana(mana: int):
	var path_mana = "res://Art/Icon/Mana/Mana" + str(min(mana,4)) + ".png"
	mana_sprite.texture = load(path_mana)
	path_mana = "res://Art/Icon/Mana/Mana" + str(min(max(mana-4,0),4)) + ".png"
	mana2_sprite.texture = load(path_mana)
