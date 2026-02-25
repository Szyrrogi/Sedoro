extends Character

@export var player: Node2D
const CardDatabase = preload("res://Scripts/CardDatabase.gd")
var deck_data = [1, 2]

func action():
	if deck_data.is_empty():
		print("Przeciwnik nie ma już kart w talii!")
		return
		
	deck_data.shuffle() 
	var card_id = deck_data.pop_front() 

	var card_data = CardDatabase.CARDS[card_id] # Pamiętaj o dobrej ścieżce/nazwie Singletona Bazy
	var card_name = card_data[0]
	var put_type = card_data[5]
	var effect_data = card_data[6]
	
	print("Przeciwnik zagrywa kartę: ", card_name)

	var virtual_card = {
		"effect": effect_data
	}

	if put_type == 0:
		print("Przeciwnik atakuje Gracza!")
		player.take(virtual_card)
		
	elif put_type == 1:
		print("Przeciwnik używa karty na sobie!")
		self.take(virtual_card)

func die():
	print("Przeciwnik pokonany!")
	visible = false
	$Area2D.set_deferred("monitorable", false)
	$Area2D.set_deferred("monitoring", false)
	
	if hit_sound and hit_sound.playing:
		await hit_sound.finished
		
	queue_free()
