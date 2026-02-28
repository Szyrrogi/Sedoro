extends Node2D

@onready var input_manager = $"../InputManager"
@onready var hand = $"../Hand"
@onready var discard = $"../Background/Discard"
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
		# Rysujemy strzałkę TYLKO jeśli put_type wynosi 0
		if targeting_card.put_type == 0:
			if arrow_sprite.texture != null:
				var mouse_pos = get_global_mouse_position()
				var target_pos = Vector2(
					clamp(mouse_pos.x, 0, screen_size.x),
					clamp(mouse_pos.y, 0, screen_size.y)
				)
				
				# Najpierw liczymy dystans
				var distance = targeting_card.global_position.distance_to(target_pos)
				
				# --- WARUNEK: MARTWA STREFA ---
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
			# Jeśli put_type jest inny niż 0, upewniamy się, że strzałka jest ukryta
			arrow_sprite.visible = false
		
		# ZATRZYMUJEMY KOD TUTAJ - jak celujemy, karta nie reaguje na drag i hover
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
		# Nie powiększaj karty, którą aktualnie celujemy
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
	
	# === ZMIANA: Pokaż strzałkę tylko, jeśli typ to 0 ===
	if arrow_sprite:
		if card.put_type == 0:
			arrow_sprite.visible = true
		else:
			arrow_sprite.visible = false
			
	print("Rozpoczęto celowanie z karty: ", card.name)
	
	if card.has_method("set_hovered"):
		card.set_hovered(false)

func finish_targeting():
	var card_played = false
	
	if targeting_card.put_type == 0:
		# 1. KARTA CELOWANA W KONKRETNEGO PRZECIWNIKA
		var target_enemy = hovering_enemy_check()
		if target_enemy:
			print("TRAFIONO PRZECIWNIKA: ", target_enemy.name)
			if target_enemy.has_method("take_damage"): 
				target_enemy.take(targeting_card)
				card_played = true
		else:
			print("Strzelono w puste pole. Karta wraca do ręki.")
			
	elif targeting_card.put_type == 1:
		# 2. KARTA NA GRACZA (np. Leczenie, Tarcza, Dobieranie)
		print("ZAGRANO KARTĘ NA GRACZA: ", targeting_card.name)
		player.take(targeting_card)
		card_played = true
		
	elif targeting_card.put_type == 2:
		# 3. KARTA OBSZAROWA (Atakuje wszystkich wrogów)
		print("ZAGRANO KARTĘ OBSZAROWĄ (Wszyscy wrogowie)!")
		if game_manager.enemies.size() > 0:
			for enemy in game_manager.enemies:
				enemy.take(targeting_card)
			card_played = true
		else:
			print("Brak przeciwników do ataku.")
			
	elif targeting_card.put_type == 3:
		# 4. KARTA W LOSOWEGO WROGA
		print("ZAGRANO KARTĘ W LOSOWEGO WROGA!")
		if game_manager.enemies.size() > 0:
			var random_enemy = game_manager.enemies.pick_random()
			print("Wylosowano: ", random_enemy.name)
			random_enemy.take(targeting_card)
			card_played = true
		else:
			print("Brak przeciwników do ataku.")

	# Jeśli karta została poprawnie użyta: zabieramy manę i usuwamy ją z ręki
	if card_played:
		game_manager.mana -= int(targeting_card.cost)
		discard.add_to_discard(targeting_card)
		hand.recalculate_positions()
	
	# Na koniec zawsze anulujemy tryb celowania (sprzątamy po sobie)
	cancel_targeting()

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

func _on_card_right_clicked(card):
	if targeting_card: return
	if card.get_parent() == hand:
		toggle_card_selection(card)

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
