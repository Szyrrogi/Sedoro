extends Node2D
class_name Character

@export var max_health: int = 30
var current_health: int
var current_armor: int
var regeneration_stacks: int = 0
var thorns_stacks: int = 0
var weakness_stacks: int = 0
var draw_reduction_stacks: int = 0 
@export var weakness_label: RichTextLabel
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

	if weakness_stacks > 0:
		weakness_stacks -= 1
		set_weakness()
		
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
	# Determine if 'card' is a Dictionary (with an 'effect' key) or a raw Array
	var effect_data
	var is_thorns = false
	
	if card is Array:
		effect_data = card
	else:
		effect_data = card.effect
		is_thorns = card.get("is_thorns") == true

	print(effect_data)
	
	# Now use 'effect_data' instead of 'card.effect'
	if effect_data[0] == 0:
		take_damage(effect_data[1], is_thorns) 
		
	elif effect_data[0] == 1:
		add_armor(effect_data[1])
		
	elif effect_data[0] == 2:
		if self.name == "Player" or self.is_in_group("Player"): 
			draw_cards_for_player(effect_data[1])
			
	elif effect_data[0] == 3:
		heal(effect_data[1])
		
	elif effect_data[0] == 4: 
		add_regeneration(effect_data[1])
		
	elif effect_data[0] == 5:
		add_thorns(effect_data[1])
		
	elif effect_data[0] == 6:
		for i in range(1, effect_data.size()):
			take(effect_data[i])
			
	elif effect_data[0] == 7: # Otrzymujesz ciernie równe pancerzowi
		add_thorns(current_armor)
		
	elif effect_data[0] == 8: # Zadaj tyle obrażeń, ile masz armora
		var game_manager = get_tree().root.find_child("GameManager", true, false)
		if game_manager and game_manager.player:
			take_damage(game_manager.player.current_armor)
			
	elif effect_data[0] == 9: # Tracisz połowę życia, podwajasz armor
		var hp_loss = int(current_health / 2)
		current_health -= hp_loss
		if health_bar: health_bar.value = current_health
		add_armor(current_armor)
		
	elif effect_data[0] == 10: # Utrata całego pancerza i zadanie takich obrażeń (Dla ataku AoE)
		var game_manager = get_tree().root.find_child("GameManager", true, false)
		if game_manager and game_manager.player:
			var dmg = game_manager.player.current_armor
			take_damage(dmg)
			# Ponieważ ten atak trafia wielu wrogów, pancerz gracza zerujemy w CardManagerze
			
	elif effect_data[0] == 11: # Dobierasz 1 mniej karte, 3 armora
		var game_manager = get_tree().root.find_child("GameManager", true, false)
		if game_manager and game_manager.player:
			game_manager.player.draw_reduction_stacks += 1
			game_manager.player.add_armor(3)
			
	elif effect_data[0] == 12: # Kombinacja: jeśli min 1 cierni, 1 pancerz, 1 regen, uderz za X
		var game_manager = get_tree().root.find_child("GameManager", true, false)
		if game_manager and game_manager.player:
			var p = game_manager.player
			if p.thorns_stacks >= 1 and p.current_armor >= 1 and p.regeneration_stacks >= 1:
				take_damage(effect_data[1])
				
	elif effect_data[0] == 13: # Warunkowy zwrot many: Uderz za X. Jeśli armor >= Y, oddaj Z many.
		take_damage(effect_data[1])
		var game_manager = get_tree().root.find_child("GameManager", true, false)
		if game_manager and game_manager.player:
			if game_manager.player.current_armor >= effect_data[2]:
				game_manager.mana += effect_data[3]
				game_manager.mana_manager.set_mana(game_manager.mana)
				
	elif effect_data[0] == 14: # Nadanie armora GRACZOWI podczas ataku na przeciwnika
		var game_manager = get_tree().root.find_child("GameManager", true, false)
		if game_manager and game_manager.player:
			game_manager.player.add_armor(effect_data[1])
			
	elif effect_data[0] == 15: # Nałóż osłabienie
		add_weakness(effect_data[1])

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
		
func set_weakness():
	if not weakness_label: return
	if weakness_stacks <= 0:
		weakness_label.text = ""
	else:
		weakness_label.text = "[font_size=100][color=purple]" + str(weakness_stacks)

func add_weakness(amount: int):
	weakness_stacks += amount
	print(self.name, " zyskuje Osłabienie! Aktualne ładunki: ", weakness_stacks)
	set_weakness()

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
