extends Character

@export var player: Node2D
@export var status_text: RichTextLabel
@export var status_art: Sprite2D

const CardDatabase = preload("res://Scripts/CardDatabase.gd")
var deck_data = [1, 2]
var effect_next
var effect

func action():
	if deck_data.is_empty():
		print("Przeciwnik nie ma już kart w talii!")
		return
		
	deck_data.shuffle() 
	var card_id = deck_data[0]

	var card_data = CardDatabase.CARDS[card_id] # Pamiętaj o dobrej ścieżce/nazwie Singletona Bazy
	var card_name = card_data[0]
	var put_type = card_data[5]
	effect_next = card_data[6]
	
	if(effect == null):
		effect = effect_next
		set_status()
		pass
	
	print("Przeciwnik zagrywa kartę: ", card_name)

	var virtual_card = {
		"effect": effect
	}

	if put_type == 0:
		print("Przeciwnik atakuje Gracza!")
		player.take(virtual_card)
		
	elif put_type == 1:
		print("Przeciwnik używa karty na sobie!")
		self.take(virtual_card)
	set_status()
	
func set_status():
	status_text.text = "[font_size=155]" + str(effect_next[1])
	status_art.texture = load("res://Art/Stats/Status" + str(effect_next[0]) + ".png")

func die():
	print("Przeciwnik pokonany!")
	visible = false
	$Area2D.set_deferred("monitorable", false)
	$Area2D.set_deferred("monitoring", false)
	
	if hit_sound and hit_sound.playing:
		await hit_sound.finished
		
	queue_free()
