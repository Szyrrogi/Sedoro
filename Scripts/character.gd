extends Node2D
class_name Character

@export var max_health: int = 30
var current_health: int
var current_armor: int
var regeneration_stacks: int = 0
var thorns_stacks: int = 0
var weakness_stacks: int = 0
var draw_reduction_stacks: int = 0 

# --- EFEKTY WIZUALNE ---
@export var armor_sprite: Sprite2D
@export var normal_health_color: Color = Color.RED
@export var armor_health_color: Color = Color.DARK_GRAY
# -----------------------

@export var weakness_label: RichTextLabel
@export var thorns_label: RichTextLabel
@export var health_bar: TextureProgressBar
@onready var hit_sound: AudioStreamPlayer2D = $HitSound
@export var armor_label: RichTextLabel 
@export var regen_label: RichTextLabel

# --- USTAWIENIA LICZB PŁYWAJĄCYCH ---
# Punkt startowy animacji – ustaw go w edytorze jako Node2D/Marker2D nad postacią,
# albo pozostaw puste: wtedy liczby pojawią się w centrum węzła (pozycja 0,0).
@export var damage_number_origin: Node2D

# Ile pikseli liczba spada w dół podczas animacji
const FLOAT_DISTANCE: float = 120.0
# Czas trwania animacji w sekundach (2x szybciej niż poprzednio)
const FLOAT_DURATION: float = 0.6
# ------------------------------------

func _ready():
	current_health = max_health
	
	if health_bar:
		health_bar.min_value = 0
		health_bar.max_value = max_health
		health_bar.value = max_health  # ustaw na max od razu, nie przez zmienną
		print(self.name, " health_bar: min=", health_bar.min_value, " max=", health_bar.max_value, " value=", health_bar.value)
		
	set_armor()
		
func start_tunr():
	print("")

	if weakness_stacks > 0:
		weakness_stacks -= 1
		set_weakness()
		
	if regeneration_stacks > 0:
		print("Regeneracja leczy o: ", regeneration_stacks)
		heal(regeneration_stacks)
		regeneration_stacks -= 1
		set_regeneration()
	
	if thorns_stacks > 0:
		thorns_stacks -= 1
		set_thorns()
	
func set_armor():
	print(self.name, " set_armor() current_armor=", current_armor, " health_bar=", health_bar)
	
	# Zmiana koloru Tint w zależności od pancerza
	if health_bar:
		if current_armor > 0:
			health_bar.tint_progress = Color("f2e8f4")
		else:
			health_bar.tint_progress = Color(17.765, 0.0, 0.0)
			
	# Kontrola widoczności sprite'a pancerza
	if armor_sprite:
		armor_sprite.visible = current_armor > 0

	# Aktualizacja tekstu labela pancerza
	if armor_label:
		if current_armor == 0:
			armor_label.text = ""
		else:
			armor_label.text = "[font_size=40][color=black]" + str(current_armor)
		
func set_regeneration():
	if not regen_label: 
		return
	if regeneration_stacks <= 0:
		regen_label.text = ""
	else:
		regen_label.text = "[font_size=100][color=green]" + str(regeneration_stacks)

func add_armor(amount: int = 10):
	current_armor += amount
	set_armor()
	
func add_regeneration(amount: int):
	regeneration_stacks += amount
	set_regeneration() 
	
func set_thorns():
	if not thorns_label: return
	if thorns_stacks <= 0:
		thorns_label.text = ""
	else:
		thorns_label.text = "[font_size=100][color=yellow]" + str(thorns_stacks)

func add_thorns(amount: int):
	thorns_stacks += amount
	set_thorns()

func take(card):
	var effect_data
	var is_thorns = false
	
	if card is Array:
		effect_data = card
	else:
		effect_data = card.effect
		is_thorns = card.get("is_thorns") == true

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
			
	elif effect_data[0] == 7:
		add_thorns(current_armor)
		
	elif effect_data[0] == 8:
		var game_manager = get_tree().root.find_child("GameManager", true, false)
		if game_manager and game_manager.player:
			take_damage(game_manager.player.current_armor)
			
	elif effect_data[0] == 9:
		var hp_loss = int(current_health / 2)
		take_damage(hp_loss)
		add_armor(current_armor)
		
	elif effect_data[0] == 10:
		var game_manager = get_tree().root.find_child("GameManager", true, false)
		if game_manager and game_manager.player:
			var dmg = game_manager.player.current_armor
			take_damage(dmg)
			
	elif effect_data[0] == 11:
		var game_manager = get_tree().root.find_child("GameManager", true, false)
		if game_manager and game_manager.player:
			game_manager.player.draw_reduction_stacks += 1
			game_manager.player.add_armor(3)
			
	elif effect_data[0] == 12:
		var game_manager = get_tree().root.find_child("GameManager", true, false)
		if game_manager and game_manager.player:
			var p = game_manager.player
			if p.thorns_stacks >= 1 and p.current_armor >= 1 and p.regeneration_stacks >= 1:
				take_damage(effect_data[1])
				
	elif effect_data[0] == 13:
		take_damage(effect_data[1])
		var game_manager = get_tree().root.find_child("GameManager", true, false)
		if game_manager and game_manager.player:
			if game_manager.player.current_armor >= effect_data[2]:
				game_manager.mana += effect_data[3]
				game_manager.mana_manager.set_mana(game_manager.mana)
				
	elif effect_data[0] == 14:
		var game_manager = get_tree().root.find_child("GameManager", true, false)
		if game_manager and game_manager.player:
			game_manager.player.add_armor(effect_data[1])
			
	elif effect_data[0] == 15:
		add_weakness(effect_data[1])

func draw_cards_for_player(amount: int):
	var game_manager = get_tree().root.find_child("GameManager", true, false)
	if game_manager and game_manager.deck and game_manager.hand:
		var drawn_cards = await game_manager.deck.draw_cards(amount)
		for c in drawn_cards:
			game_manager.hand.add_card(c)

func heal(amount: int):
	current_health = min(amount + current_health, max_health)
	if health_bar:
		health_bar.value = current_health
	spawn_floating_number("+" + str(amount), Color(0.2, 1.0, 0.3))

func take_damage(amount: int = 10, is_from_thorns: bool = false):
	var incoming_damage = amount
	
	if current_armor >= amount:
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

	# --- PŁYWAJĄCA LICZBA OBRAŻEŃ ---
	if incoming_damage > 0:
		spawn_floating_number(str(incoming_damage), Color(1.0, 1.0, 1.0))
	# --------------------------------
		
	if incoming_damage > 0 and thorns_stacks > 0 and not is_from_thorns:
		trigger_thorns()
		
	if current_health <= 0:
		die()

# ============================================================
# PŁYWAJĄCE LICZBY – serce efektu
# ============================================================
func spawn_floating_number(text: String, color: Color) -> void:
	# Tworzymy Label i dodajemy go DO SCENY (nie do tej postaci),
	# żeby nie dziedziczył jej transformacji (skalowania itp.)
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.85))
	label.add_theme_constant_override("outline_size", 6)
	label.add_theme_font_size_override("font_size", 42)
	
	# Pozycja startowa: nad paskiem HP jeśli istnieje, w przeciwnym razie środek węzła
	var start_pos: Vector2
	if damage_number_origin:
		start_pos = damage_number_origin.global_position
	elif health_bar:
		start_pos = health_bar.global_position
		start_pos.x += 50.0
		start_pos.y -= 10.0
	else:
		start_pos = global_position
	
	# Drobne losowe przesunięcie boczne, żeby kilka liczb naraz nie nachodziło na siebie
	start_pos.x += randf_range(-18.0, 18.0)
	
	# Dodajemy do głównej sceny (root lub bezpośrednio do drzewa)
	get_tree().current_scene.add_child(label)
	label.global_position = start_pos
	
	# Animacja: unoszenie w górę + zanikanie
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "global_position",
		start_pos + Vector2(0.0, FLOAT_DISTANCE),
		FLOAT_DURATION
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, FLOAT_DURATION)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)\
		.set_delay(FLOAT_DURATION * 0.35)   # krótka pauza zanim zacznie znikać
	
	# Sprzątanie po zakończeniu
	tween.chain().tween_callback(label.queue_free)
# ============================================================

func set_weakness():
	if not weakness_label: return
	if weakness_stacks <= 0:
		weakness_label.text = ""
	else:
		weakness_label.text = "[font_size=100][color=purple]" + str(weakness_stacks)

func add_weakness(amount: int):
	weakness_stacks += amount
	set_weakness()

func trigger_thorns():
	var damage_card = {
		"effect": [0, thorns_stacks],
		"is_thorns": true 
	}
	
	if self.name == "Player" or self.is_in_group("Player"):
		var game_manager = get_tree().root.find_child("GameManager", true, false)
		if game_manager and game_manager.enemies.size() > 0:
			var random_enemy = game_manager.enemies.pick_random()
			random_enemy.take(damage_card)
	else:
		var game_manager = get_tree().root.find_child("GameManager", true, false)
		if game_manager and game_manager.player:
			game_manager.player.take(damage_card)

func die():
	queue_free()
