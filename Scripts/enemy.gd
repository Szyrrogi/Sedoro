extends Character

@export var player: Node2D
@export var status_text: RichTextLabel
@export var status_art: Sprite2D

const CardDatabase = preload("res://Scripts/CardDatabase.gd")
var deck_data = [1, 2]

# Zmienne przechowujące ZAPLANOWANĄ akcję (zamiar przeciwnika)
var planned_card_id = -1
var planned_effect = null
var planned_put_type = -1

func _ready():
	super()
	plan_next_action()

# Funkcja wywoływana, gdy nadchodzi tura przeciwnika
func action():
	# 1. Najpierw WYKONAJ to, co zaplanowałeś w poprzedniej turze
	if planned_card_id != -1:
		execute_planned_action()
	
	# 2. Następnie ZAPLANUJ i POKAŻ graczowi co zrobisz w kolejnej turze
	plan_next_action()

func execute_planned_action():
	var card_data = CardDatabase.CARDS[planned_card_id]
	var card_name = card_data[0]
	
	print("Przeciwnik wykonuje zaplanowaną kartę: ", card_name)

	var virtual_card = {
		"effect": planned_effect
	}

	if planned_put_type == 0:
		print("Przeciwnik atakuje Gracza!")
		player.take(virtual_card)
		
	elif planned_put_type == 1:
		print("Przeciwnik używa karty na sobie!")
		self.take(virtual_card)

func plan_next_action():
	if deck_data.is_empty():
		print("Przeciwnik nie ma już kart w talii!")
		planned_card_id = -1
		status_text.text = ""
		status_art.texture = null
		return
		
	# Losowanie karty
	deck_data.shuffle() 
	planned_card_id = deck_data[0]
	
	# Zapisanie danych karty do zmiennych zaplanowanej akcji
	var card_data = CardDatabase.CARDS[planned_card_id]
	planned_put_type = card_data[5]
	planned_effect = card_data[6]
	
	# Aktualizacja interfejsu (pokazanie intencji)
	update_intent_ui()

func update_intent_ui():
	# Wyświetlenie ikony i wartości ataku/obrony
	status_text.text = "[font_size=155]" + str(planned_effect[1])
	status_art.texture = load("res://Art/Stats/Status" + str(planned_effect[0]) + ".png")

func die():
	print("Przeciwnik pokonany!")
	visible = false
	$Area2D.set_deferred("monitorable", false)
	$Area2D.set_deferred("monitoring", false)
	
	if hit_sound and hit_sound.playing:
		await hit_sound.finished
		
	queue_free()
