extends Node2D
class_name Character

@export var max_health: int = 30
var current_health: int
var current_armor: int
var regeneration_stacks: int = 0
var thorns_stacks: int = 0
var weakness_stacks: int = 0
var draw_reduction_stacks: int = 0
var poison_stacks: int = 0          # NOWE: trucizna
var poison_mode_active: bool = false # NOWE: tryb trujacego ostrza (cała tura)
var doom_turns_left: int = 0        # NOWE: licznik zgonu (karta Szaleństwo)
var cards_drawn_this_turn: int = 0  # NOWE: licznik dobranych kart w tej turze

# --- EFEKTY WIZUALNE ---
@export var armor_sprite: Sprite2D
@export var normal_health_color: Color = Color.RED
@export var armor_health_color: Color = Color.DARK_GRAY
# -----------------------

@export var weakness_label: RichTextLabel
@export var thorns_label: RichTextLabel
@export var health_bar: TextureProgressBar
@export var white_health_bar: TextureProgressBar
var hp_tween: Tween
@onready var hit_sound: AudioStreamPlayer2D = $HitSound
@export var armor_label: RichTextLabel 
@export var regen_label: RichTextLabel
@export var poison_label: RichTextLabel   # NOWE: label dla trucizny

@export var damage_number_origin: Node2D

const FLOAT_DISTANCE: float = 120.0
const FLOAT_DURATION: float = 0.6

func _ready():
	current_health = max_health
	
	if health_bar:
		health_bar.min_value = 0
		health_bar.max_value = max_health
		health_bar.value = max_health
		
	if white_health_bar:
		white_health_bar.min_value = 0
		white_health_bar.max_value = max_health
		white_health_bar.value = max_health
		
	set_armor()

# Wywoływane na początku tury tej postaci
func start_turn():
	cards_drawn_this_turn = 0
	poison_mode_active = false  # reset trybu trującego ostrza

	# 1. Osłabienie tick
	if weakness_stacks > 0:
		weakness_stacks -= 1
		set_weakness()

	# 2. Regeneracja
	if regeneration_stacks > 0:
		heal(regeneration_stacks)
		regeneration_stacks -= 1
		set_regeneration()

	# 3. Ciernie tick (zmniejsz o 1 na koniec tury wroga, tutaj zostawiamy jak było)
	if thorns_stacks > 0:
		thorns_stacks -= 1
		set_thorns()

	# 4. Trucizna tick - NOWE
	if poison_stacks > 0:
		var dmg = poison_stacks
		poison_stacks -= 1           # trucizna spada o 1 każdą turę
		set_poison()
		take_damage(dmg, false, true) # is_from_poison=true żeby nie wywołać cierni

	# 5. Doom (Szaleństwo) tick - NOWE
	if doom_turns_left > 0:
		doom_turns_left -= 1
		if doom_turns_left <= 0:
			die()

# Alias dla starego zapisu (literówka w oryginale)
func start_tunr():
	start_turn()

# ============================================================
# SETTERY STATUSÓW
# ============================================================
func set_armor():
	if health_bar:
		if current_armor > 0:
			health_bar.tint_progress = Color("f2e8f4")
		else:
			health_bar.tint_progress = Color(17.765, 0.0, 0.0)
			
	if armor_sprite:
		armor_sprite.visible = current_armor > 0

	if armor_label:
		armor_label.text = "" if current_armor == 0 else "[font_size=40][color=black]" + str(current_armor)
		
func set_regeneration():
	if not regen_label: return
	regen_label.text = "" if regeneration_stacks <= 0 else "[font_size=100][color=green]" + str(regeneration_stacks)

func set_thorns():
	if not thorns_label: return
	thorns_label.text = "" if thorns_stacks <= 0 else "[font_size=100][color=yellow]" + str(thorns_stacks)

func set_weakness():
	if not weakness_label: return
	weakness_label.text = "" if weakness_stacks <= 0 else "[font_size=100][color=purple]" + str(weakness_stacks)

func set_poison():
	if not poison_label: return
	poison_label.text = "" if poison_stacks <= 0 else "[font_size=100][color=green]" + str(poison_stacks)

# ============================================================
# DODAWANIE STATUSÓW
# ============================================================
func add_armor(amount: int = 10):
	current_armor += amount
	set_armor()

func add_regeneration(amount: int):
	regeneration_stacks += amount
	set_regeneration()

func add_thorns(amount: int):
	thorns_stacks += amount
	set_thorns()

func add_weakness(amount: int):
	weakness_stacks += amount
	set_weakness()

func add_poison(amount: int):
	# NOWE: dodaj truciznę
	poison_stacks += amount
	set_poison()
	spawn_floating_number("+" + str(amount) + "☠", Color(0.2, 0.8, 0.0))

# ============================================================
# GŁÓWNA FUNKCJA EFEKTÓW
# ============================================================
func take(card):
	var effect_data
	var is_thorns = false
	
	if card is Array:
		effect_data = card
	else:
		effect_data = card.effect
		is_thorns = card.get("is_thorns") == true

	_apply_effect(effect_data, is_thorns)

func _apply_effect(effect_data: Array, is_thorns: bool = false):
	match effect_data[0]:

		# --- ISTNIEJĄCE ---
		0: # Zadaj obrażenia
			take_damage(effect_data[1], is_thorns)

		1: # Zyskaj pancerz
			add_armor(effect_data[1])

		2: # Dobierz karty
			if self.name == "Player" or self.is_in_group("Player"):
				draw_cards_for_player(effect_data[1])

		3: # Lecz się
			heal(effect_data[1])

		4: # Regeneracja
			add_regeneration(effect_data[1])

		5: # Ciernie
			add_thorns(effect_data[1])

		6: # Łączenie efektów
			for i in range(1, effect_data.size()):
				_apply_effect(effect_data[i], is_thorns)

		7: # Ciernie = pancerz
			add_thorns(current_armor)

		8: # Obrażenia = pancerz GRACZA (użyte przez cel, np. wroga)
			var gm = _get_gm()
			if gm and gm.player:
				take_damage(gm.player.current_armor)

		9: # Stracisz połowę HP, podwój pancerz
			var hp_loss = int(current_health / 2)
			take_damage(hp_loss, false, false)
			add_armor(current_armor)

		10: # Stracisz CAŁY pancerz → obrażenia dla wszystkich wrogów
			var gm = _get_gm()
			if gm and gm.player:
				var dmg = gm.player.current_armor
				gm.player.current_armor = 0
				gm.player.set_armor()
				take_damage(dmg)

		11: # Pasywna: draw_reduction +1, +3 pancerza co turę
			var gm = _get_gm()
			if gm and gm.player:
				gm.player.draw_reduction_stacks += 1
				gm.player.add_armor(3)

		12: # Cios Chwały: uderz za X jeśli warunki spełnione
			var gm = _get_gm()
			if gm and gm.player:
				var p = gm.player
				if p.thorns_stacks >= 1 and p.current_armor >= 1 and p.regeneration_stacks >= 1:
					take_damage(effect_data[1])

		13: # Uderz za X, jeśli armor ≥ min zwróć manę
			take_damage(effect_data[1])
			var gm = _get_gm()
			if gm and gm.player:
				if gm.player.current_armor >= effect_data[2]:
					gm.mana += effect_data[3]
					gm.mana_manager.set_mana(gm.mana)

		14: # Dodaj pancerz GRACZOWI (efekt pomocniczy dla kombo)
			var gm = _get_gm()
			if gm and gm.player:
				gm.player.add_armor(effect_data[1])

		15: # Osłabienie
			add_weakness(effect_data[1])

		# --- TRUCIZNA (NOWE) ---
		16: # Nałóż X trucizny na cel
			add_poison(effect_data[1])

		17: # Nałóż X trucizny na WSZYSTKICH wrogów
			var gm = _get_gm()
			if gm:
				for enemy in gm.enemies:
					if is_instance_valid(enemy):
						enemy.add_poison(effect_data[1])

		18: # Aktywuj natychmiastowe obrażenia z trucizny
			if poison_stacks > 0:
				take_damage(poison_stacks, false, true)

		19: # Nałóż truciznę na SIEBIE (gracza)
			var gm = _get_gm()
			if gm and gm.player:
				gm.player.add_poison(effect_data[1])

		20: # Podwój truciznę celu
			if poison_stacks > 0:
				add_poison(poison_stacks)

		21: # Wszyscy wrogowie dostają tyle trucizny ile ma WYBRANY wróg
			# Wywołane na konkretnym celu - efekt rozlewa się przez GameManager
			var source_poison = poison_stacks
			var gm = _get_gm()
			if gm:
				for enemy in gm.enemies:
					if is_instance_valid(enemy) and enemy != self:
						enemy.add_poison(source_poison)

		22: # Nałóż X trucizny + 1 za każde 3 trucizny już na celu
			var base = effect_data[1]
			var bonus = int(poison_stacks / 3)
			add_poison(base + bonus)

		23: # Nałóż truciznę = twój pancerz
			var gm = _get_gm()
			if gm and gm.player:
				add_poison(gm.player.current_armor)

		24: # Włącz tryb trującego ostrza na resztę tury
			var gm = _get_gm()
			if gm and gm.player:
				gm.player.poison_mode_active = true

		25: # Zyskaj X pancerza (discount obsługiwany w CardManager przed zagraniem)
			var gm = _get_gm()
			if gm and gm.player:
				gm.player.add_armor(effect_data[1])

		26: # 100 pancerza + doom za N tur
			add_armor(effect_data[1])
			doom_turns_left = 2
			spawn_floating_number("☠ 2 tury!", Color(1.0, 0.2, 0.2))

		27: # Pasywna co turę: nałóż X trucizny na wszystkich wrogów
			var gm = _get_gm()
			if gm:
				for enemy in gm.enemies:
					if is_instance_valid(enemy):
						enemy.add_poison(effect_data[1])

		28: # Nałóż 1 trucizny za każdą dobraną kartę w tej turze
			var gm = _get_gm()
			if gm and gm.player:
				var amount = gm.player.cards_drawn_this_turn
				if amount > 0:
					add_poison(amount)

# ============================================================
# POMOCNICZE
# ============================================================
func _get_gm():
	return get_tree().root.find_child("GameManager", true, false)

func draw_cards_for_player(amount: int):
	var gm = _get_gm()
	if gm and gm.deck and gm.hand:
		var drawn_cards = await gm.deck.draw_cards(amount)
		for c in drawn_cards:
			gm.hand.add_card(c)
			cards_drawn_this_turn += 1

func heal(amount: int):
	current_health = min(amount + current_health, max_health)
	update_health_bars()
	spawn_floating_number("+" + str(amount), Color(0.2, 1.0, 0.3))

func take_damage(amount: int = 10, is_from_thorns: bool = false, is_from_poison: bool = false):
	var incoming_damage = amount

	# Osłabienie zmniejsza obrażenia o połowę (zaokrąglenie w górę)
	if weakness_stacks > 0 and not is_from_thorns and not is_from_poison:
		amount = int(ceil(amount / 2.0))

	if current_armor >= amount:
		current_armor -= amount
	else:
		amount -= current_armor
		current_armor = 0
		current_health -= amount
		
	set_armor()
	
	if hit_sound:
		hit_sound.play()

	update_health_bars()

	if incoming_damage > 0:
		spawn_floating_number(str(incoming_damage), Color(1.0, 1.0, 1.0))
		
	# Ciernie odpowiadają tylko na obrażenia od gracza (nie od trucizny/cierni)
	if incoming_damage > 0 and thorns_stacks > 0 and not is_from_thorns and not is_from_poison:
		trigger_thorns()
		
	if current_health <= 0:
		die()

func update_health_bars():
	if health_bar:
		health_bar.value = current_health
		
	if white_health_bar:
		if hp_tween and hp_tween.is_valid():
			hp_tween.kill()
			
		hp_tween = create_tween()
		hp_tween.tween_property(white_health_bar, "value", current_health, 1)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_OUT)

func spawn_floating_number(text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.85))
	label.add_theme_constant_override("outline_size", 6)
	label.add_theme_font_size_override("font_size", 42)
	
	var start_pos: Vector2
	if damage_number_origin:
		start_pos = damage_number_origin.global_position
	elif health_bar:
		start_pos = health_bar.global_position
		start_pos.x += 50.0
		start_pos.y -= 10.0
	else:
		start_pos = global_position
	
	start_pos.x += randf_range(-18.0, 18.0)
	
	get_tree().current_scene.add_child(label)
	label.global_position = start_pos
	
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "global_position",
		start_pos + Vector2(0.0, FLOAT_DISTANCE),
		FLOAT_DURATION
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, FLOAT_DURATION)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)\
		.set_delay(FLOAT_DURATION * 0.35)
	
	tween.chain().tween_callback(label.queue_free)

func trigger_thorns():
	var damage_card = {
		"effect": [0, thorns_stacks],
		"is_thorns": true 
	}
	
	if self.name == "Player" or self.is_in_group("Player"):
		var gm = _get_gm()
		if gm and gm.enemies.size() > 0:
			gm.enemies.pick_random().take(damage_card)
	else:
		var gm = _get_gm()
		if gm and gm.player:
			gm.player.take(damage_card)

func die():
	queue_free()

# ============================================================
# RESET STATYSTYK NA POCZĄTKU WALKI
# ============================================================
func reset_combat_stats():
	current_armor = 0
	regeneration_stacks = 0
	thorns_stacks = 0
	weakness_stacks = 0
	draw_reduction_stacks = 0
	poison_stacks = 0
	poison_mode_active = false
	doom_turns_left = 0
	cards_drawn_this_turn = 0
	set_armor()
	set_regeneration()
	set_thorns()
	set_weakness()
	set_poison()
