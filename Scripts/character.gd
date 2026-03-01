extends Node2D
class_name Character

@export var max_health: int = 30
var current_health: int
var current_armor: int

@export var health_bar: TextureProgressBar
@onready var hit_sound: AudioStreamPlayer2D = $HitSound
@export var armor_label: RichTextLabel 

func _ready():
	current_health = max_health
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
	set_armor()
		
func start_tunr():
	print("")
	#set_armor()
	
func set_armor():
	print("wdo")
	if current_armor == 0:
		armor_label.text=""
	else:
		armor_label.text = "[font_size=100][color=white]" + str(current_armor)

func add_armor(amount: int = 10):
	print("ddd")
	current_armor += amount
	set_armor()

func take(card):
	print(card.effect)
	
	if card.effect[0] == 0:
		take_damage(card.effect[1])
		
	elif card.effect[0] == 1:
		add_armor(card.effect[1])
		
	elif card.effect[0] == 2: # NOWY EFEKT: Dobieranie kart
		# Sprawdzamy czy postać otrzymująca efekt to Gracz
		# Zwróć uwagę, czy Twój węzeł Gracza na scenie na pewno nazywa się "Player"
		if self.name == "Player" or self.is_in_group("Player"): 
			print("Gracz dobiera ", card.effect[1], " kart!")
			draw_cards_for_player(card.effect[1])
		else:
			print("Przeciwnik używa karty dobierania, ale nie robi to na nim wrażenia.")
			
	elif card.effect[0] == 3:
		heal(card.effect[1])

# Funkcja pomocnicza odnajdująca menadżera i dodająca karty do ręki
func draw_cards_for_player(amount: int):
	# Szukamy GameManager w drzewie sceny
	var game_manager = get_tree().root.find_child("GameManager", true, false)
	
	if game_manager and game_manager.deck and game_manager.hand:
		var drawn_cards = await game_manager.deck.draw_cards(amount)
		for c in drawn_cards:
			game_manager.hand.add_card(c)

func heal(amount: int):
	current_health = min(amount+current_health,max_health)
	health_bar.value = current_health

func take_damage(amount: int = 10):
	if(current_armor >= amount):
		current_armor -= amount
	else:
		amount -= current_armor
		current_armor = 0
		current_health -= amount
	set_armor()
	
	if hit_sound:
		hit_sound.play()
		
	if health_bar:
		health_bar.value = current_health
		
	if current_health <= 0:
		die()

func die():
	queue_free()
