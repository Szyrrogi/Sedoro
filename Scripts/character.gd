extends Node2D
class_name Character

@export var max_health: int = 30
var current_health: int
var current_armor: int
var regeneration_stacks: int = 0
var thorns_stacks: int = 0
@export var thorns_label: RichTextLabel
@export var health_bar: TextureProgressBar
@onready var hit_sound: AudioStreamPlayer2D = $HitSound
@export var armor_label: RichTextLabel 
@export var regen_label: RichTextLabel

func _ready():
	current_health = max_health
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
	set_armor()
		
func start_tunr():
	print("")
	#set_armor()
	
	# --- LOGIKA REGENERACJI ---
	if regeneration_stacks > 0:
		print("Regeneracja leczy o: ", regeneration_stacks)
		heal(regeneration_stacks)
		regeneration_stacks -= 1
		set_regeneration() 
	# --------------------------
	
	if thorns_stacks > 0:
		thorns_stacks -= 1
		set_thorns()
	
func set_armor():
	print("wdo")
	if current_armor == 0:
		armor_label.text=""
	else:
		armor_label.text = "[font_size=100][color=white]" + str(current_armor)
		
func set_regeneration():
	if not regen_label: 
		return
		
	if regeneration_stacks <= 0:
		regen_label.text = ""
	else:
		# Używamy zielonego koloru dla odróżnienia od pancerza
		regen_label.text = "[font_size=100][color=green]" + str(regeneration_stacks)

func add_armor(amount: int = 10):
	print("ddd")
	current_armor += amount
	set_armor()
	
func add_regeneration(amount: int):
	regeneration_stacks += amount
	print(self.name, " zyskuje Regenerację! Aktualne ładunki: ", regeneration_stacks)
	set_regeneration() 
	
func set_thorns():
	if not thorns_label: return
	
	if thorns_stacks <= 0:
		thorns_label.text = ""
	else:
		# Kolor żółty dla ostrzeżenia / kolców
		thorns_label.text = "[font_size=100][color=yellow]" + str(thorns_stacks)

func add_thorns(amount: int):
	thorns_stacks += amount
	print(self.name, " zyskuje Ciernie! Aktualne ładunki: ", thorns_stacks)
	set_thorns()

func take(card):
	print(card.effect)
	
	if card.effect[0] == 0:
		# Używamy get(), żeby bezpiecznie pobrać właściwość bez błędu, jeśli nie istnieje
		var is_from_thorns = card.get("is_thorns") == true 
		take_damage(card.effect[1], is_from_thorns) # Przekazujemy flagę do take_damage
		
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
		
	elif card.effect[0] == 4: 
		add_regeneration(card.effect[1])
		
	elif card.effect[0] == 5:
		add_thorns(card.effect[1])

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

func take_damage(amount: int = 10, is_from_thorns: bool = false):
	var incoming_damage = amount # Zapisujemy fakt, że ktoś próbował nas zaatakować
	
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
		
	# --- ODPALANIE CIERNI ---
	# Jeśli zostaliśmy zaatakowani, mamy Ciernie i atak nie pochodzi z innych Cierni
	if incoming_damage > 0 and thorns_stacks > 0 and not is_from_thorns:
		trigger_thorns()
		
	if current_health <= 0:
		die()

func trigger_thorns():
	print(self.name, " odpala Ciernie! Zadaje ", thorns_stacks, " obrażeń.")
	
	# Tworzymy wirtualną kartę uderzenia, identycznie jak robisz to w CardManager.gd
	var damage_card = {
		"effect": [0, thorns_stacks],
		"is_thorns": true # Ta flaga zabezpiecza przed nieskończonym odbijaniem!
	}
	
	if self.name == "Player" or self.is_in_group("Player"):
		# Ciernie Gracza trafiają w losowego przeciwnika
		var game_manager = get_tree().root.find_child("GameManager", true, false)
		if game_manager and game_manager.enemies.size() > 0:
			var random_enemy = game_manager.enemies.pick_random()
			random_enemy.take(damage_card)
	else:
		# Ciernie Przeciwnika trafiają w gracza
		var game_manager = get_tree().root.find_child("GameManager", true, false)
		if game_manager and game_manager.player:
			game_manager.player.take(damage_card)

func die():
	queue_free()
