extends Node2D

@onready var input_manager = $"../InputManager"
@onready var hand = $"../WALKA/Hand"
@onready var discard = $"../WALKA/Discard"
@onready var game_manager = $"../GameManager"

@onready var arrow_sprite: Sprite2D = $ArrowSprite

const DRAG_DELAY: float = 0.1
const MIN_ARROW_DISTANCE: float = 120

# MASKI KOLIZJI
const COLLISION_MASK_CARD = 1
const COLLISION_MASK_CARD_SLOT = 2
const COLLISION_MASK_ENEMY = 4

# STAN KART
var dragged_card: Node2D = null
var hovered_card: Node2D = null
var held_card: Node2D = null 
var hold_timer: float = 0.0

# STAN CELOWANIA
var targeting_card: Node2D = null
var screen_size: Vector2

@export var player: Node2D
@export var deck: Node2D

var redraws_used: int = 0
const MAX_REDRAWS: int = 2

const DISCARD_MANA_GAIN = 2  # Mana za odrzucenie karty prawym klikiem


func _ready():
	await get_tree().process_frame
	screen_size = get_viewport_rect().size
	
	if arrow_sprite:
		arrow_sprite.visible = false
		
	input_manager.connect("card_left_clicked", _on_card_left_clicked)
	input_manager.connect("card_right_clicked", _on_card_right_clicked)
	input_manager.connect("left_mouse_button_released", _on_left_release)
	input_manager.connect("background_clicked", _on_background_clicked)

func _process(delta):
	# --- 1. OBSŁUGA STRZAŁKI CELOWANIA ---
	if targeting_card and arrow_sprite:
		if targeting_card.put_type == 0:
			if arrow_sprite.texture != null:
				var mouse_pos = get_global_mouse_position()
				var target_pos = Vector2(
					clamp(mouse_pos.x, 0, screen_size.x),
					clamp(mouse_pos.y, 0, screen_size.y)
				)
				
				var distance = targeting_card.global_position.distance_to(target_pos)
				
				if distance < MIN_ARROW_DISTANCE:
					arrow_sprite.visible = false 
				else:
					arrow_sprite.visible = true 
					
					arrow_sprite.global_position = targeting_card.global_position
					arrow_sprite.look_at(target_pos)
					
					var texture_width = arrow_sprite.texture.get_width()
					if texture_width > 0:
						arrow_sprite.scale.x = distance / texture_width
						arrow_sprite.scale.y = 0.3 
		else:
			arrow_sprite.visible = false
		
		return

	# --- 2. SPRAWDZANIE PRZYTRZYMANIA (Hold -> Drag) ---
	if held_card and not dragged_card:
		hold_timer += delta
		if hold_timer >= DRAG_DELAY:
			_start_dragging(held_card)

	# --- 3. OBSŁUGA DRAG (Ruszanie kartą) ---
	if dragged_card:
		dragged_card.global_position = get_global_mouse_position()
		return 

	# --- 4. OBSŁUGA HOVER (Powiększanie po najechaniu) ---
	var result = input_manager.raycast_at_cursor()
	var new_hovered_card = null
	
	if result and result.collider.collision_mask == input_manager.COLLISION_MASK_CARD:
		new_hovered_card = result.collider.get_parent()
	
	if new_hovered_card != hovered_card:
		if hovered_card and hovered_card.has_method("set_hovered"):
			hovered_card.set_hovered(false) 
		if new_hovered_card and new_hovered_card.has_method("set_hovered") and new_hovered_card != targeting_card:
			new_hovered_card.set_hovered(true) 
		hovered_card = new_hovered_card


# --- BEZPOŚREDNIA OBSŁUGA MYSZY DLA CELOWANIA ---
func _input(event):
	if targeting_card and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			finish_targeting()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			cancel_targeting()
			get_viewport().set_input_as_handled()


# --- LOGIKA CELOWANIA ---
func start_targeting(card):
	targeting_card = card
	
	if arrow_sprite:
		if card.put_type == 0:
			arrow_sprite.visible = true
		else:
			arrow_sprite.visible = false
			
	print("Rozpoczęto celowanie z karty: ", card.name)
	
	if card.has_method("set_hovered"):
		card.set_hovered(false)

var active
@export var active_label: Sprite2D

func set_active():
	if active != 0:
		active_label.visible = true
		active_label.texture = load("res://Art/Card/division" +  str(active) + ".png")
	else:
		active_label.visible = false

func finish_targeting():
	var card_played = false
	var combo_triggered = false
	
	# === 1. SPRAWDZENIE COMBO ===
	if targeting_card.cost_color != null and targeting_card.cost_color != 0 and targeting_card.cost_color == active:
		combo_triggered = true
		active = 0
		set_active()
	# === 2. GŁÓWNY EFEKT KARTY ===
	if targeting_card.put_type == 0:
		var target_enemy = hovering_enemy_check()
		if target_enemy:
			print("TRAFIONO PRZECIWNIKA: ", target_enemy.name)
			if target_enemy.has_method("take_damage"): 
				target_enemy.take(targeting_card)
				if combo_triggered:
					trigger_combo_effect(target_enemy)
				card_played = true
		else:
			print("Strzelono w puste pole. Karta wraca do ręki.")
			
	elif targeting_card.put_type == 1:
		print("ZAGRANO KARTĘ NA GRACZA: ", targeting_card.name)
		player.take(targeting_card)
		if combo_triggered:
			trigger_combo_effect()
		card_played = true
		
	elif targeting_card.put_type == 2:
		print("ZAGRANO KARTĘ OBSZAROWĄ (Wszyscy wrogowie)!")
		if game_manager.enemies.size() > 0:
			var wrogowie_do_zranienia = game_manager.enemies.duplicate()
			for enemy in wrogowie_do_zranienia:
				if is_instance_valid(enemy):
					enemy.take(targeting_card)
			if combo_triggered:
				trigger_combo_effect()
			card_played = true
		else:
			print("Brak przeciwników do ataku.")
			
	elif targeting_card.put_type == 3:
		print("ZAGRANO KARTĘ W LOSOWEGO WROGA!")
		if game_manager.enemies.size() > 0:
			var random_enemy = game_manager.enemies.pick_random()
			print("Wylosowano: ", random_enemy.name)
			random_enemy.take(targeting_card)
			if combo_triggered:
				trigger_combo_effect(random_enemy)
			card_played = true
		else:
			print("Brak przeciwników do ataku.")

	# === 3. CZYSZCZENIE I AKTUALIZACJA ZMIENNYCH ===
	if card_played:
		if targeting_card.active != null and targeting_card.active != 0:
			active = targeting_card.active
			if has_method("set_active"):
				set_active()
			
		game_manager.mana -= int(targeting_card.cost)
		discard.add_to_discard(targeting_card)
		hand.recalculate_positions()
	
	cancel_targeting()

# === COMBO ===
func trigger_combo_effect(target_enemy = null):
	if targeting_card.effect_extra == null:
		return
		
	var extra_card = {"effect": targeting_card.effect_extra}
	var extra_type = targeting_card.effect_extra[0]
	
	print("COMBO AKTYWNE! Dodatkowy efekt: ", targeting_card.effect_extra)
	
	if extra_type == 1 or extra_type == 2 or extra_type == 3:
		player.take(extra_card)
	elif extra_type == 0:
		if targeting_card.put_type == 0 and target_enemy:
			target_enemy.take(extra_card)
		elif targeting_card.put_type == 2:
			for enemy in game_manager.enemies:
				enemy.take(extra_card)
		elif targeting_card.put_type == 3 and target_enemy:
			target_enemy.take(extra_card)

func cancel_targeting():
	targeting_card = null
	if arrow_sprite: arrow_sprite.visible = false
	print("Anulowano/Zakończono celowanie")

func hovering_enemy_check():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_ENEMY
	
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		var hit_collider = result[0].collider
		if hit_collider.has_method("take_damage"):
			return hit_collider
		elif hit_collider.get_parent() and hit_collider.get_parent().has_method("take_damage"):
			return hit_collider.get_parent()
		return hit_collider 
		
	return null

# --- SYGNAŁY Z INPUT MANAGERA ---
func _on_card_left_clicked(card):
	if targeting_card: return
	if card.get_parent() == hand: 
		held_card = card
		hold_timer = 0.0

func _start_dragging(card):
	dragged_card = card
	card.is_dragged = true 
	card.z_index = 100 
	if card.has_method("set_hovered"): card.set_hovered(false) 

func _on_left_release():
	if targeting_card: return

	if held_card and not dragged_card:
		print("Karta kliknięta!")
		if held_card.cost <= game_manager.mana:
			start_targeting(held_card)

	if dragged_card:
		dragged_card.is_dragged = false 
		dragged_card.z_index = 0 
		dragged_card = null
	
	held_card = null

# Prawy klik: odrzuć kartę i daj 2 many
func _on_card_right_clicked(card):
	if targeting_card: return
	if card.get_parent() != hand: return
	if game_manager.current_state != game_manager.State.PLAYER_ACTION: return
	
	print("Odrzucono kartę: ", card.name, " | +", DISCARD_MANA_GAIN, " many")
	
	# Clamp, żeby nie przekroczyć maks many
	game_manager.mana = min(game_manager.mana + DISCARD_MANA_GAIN, game_manager.MANA_MAX)
	
	discard.add_to_discard(card)
	hand.recalculate_positions()

func toggle_card_selection(card):
	if card.is_selected:
		card.set_selected(false)
	else:
		card.set_selected(true)

func get_selected_count() -> int:
	var count = 0
	for c in hand.get_all_cards():
		if c.is_selected: count += 1
	return count

func _on_background_clicked():
	pass
