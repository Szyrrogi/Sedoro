extends Node2D

# Zakładam, że w tym pliku CardDatabase.gd masz 'const CARDS = ...'
const CardDatabase = preload("res://Scripts/CardDatabase.gd")

@export var cost_label: RichTextLabel 
@export var name_label: RichTextLabel
@export var description_label: RichTextLabel
@export var description2_label: RichTextLabel
@export var art_label: Sprite2D
@export var separation_label: Sprite2D

var card_name: String
var energy_cost: int
var main_effect: String
var secondary_effect: String
var art_name: String

func set_up(_id : int):
	if not CardDatabase.CARDS.has(_id):
		push_error("Halo baza? Tu Node. Nie mamy takiej karty: " + str(_id))
		return

	var data = CardDatabase.CARDS[_id]
	
	
	# Rozpakowanie - to masz dobrze
	card_name = data[0]
	energy_cost = data[1]
	art_name = data[2]
	main_effect = data[3] 
	if(data[4].size() > 0):
		secondary_effect = data[4][1]
		separation_label.visible = true
		separation_label.texture = load("res://Art/Card/division" +  str(data[4][0]) + ".png")
	else:
		secondary_effect = ""
		separation_label.visible = false

	cost_label.text = "[font_size=155][color=white]" + str(energy_cost) 
	name_label.text = "[font_size=55][color=black]" + card_name
	description_label.text = "[font_size=55][color=black]" + main_effect
	description2_label.text = "[font_size=55][color=black]" + secondary_effect
	var path_to_image = "res://Art/Card/Art" + art_name + ".png"
	# Magiczna funkcja load() zamienia napis na obrazek
	art_label.texture = load(path_to_image)
