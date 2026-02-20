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
		if arrow_sprite.texture != null:
			var mouse_pos = get_global_mouse_position()
			var target_pos = Vector2(
				clamp(mouse_pos.x, 0, screen_size.x),
				clamp(mouse_pos.y, 0, screen_size.y)
			)
			
			# Najpierw liczymy dystans
			var distance = targeting_card.global_position.distance_to(target_pos)
			
			# --- NOWY WARUNEK: MARTWA STREFA ---
			if distance < MIN_ARROW_DISTANCE:
				arrow_sprite.visible = false # Ukrywamy strzałkę blisko środka karty
			else:
				arrow_sprite.visible = true  # Pokazujemy, gdy wyjedzie poza strefę
				
				# Ustawiamy pozycję, obrót i skalę tylko wtedy, gdy strzałka jest widoczna
				arrow_sprite.global_position = targeting_card.global_position
				arrow_sprite.look_at(target_pos)
				
				var texture_width = arrow_sprite.texture.get_width()
				if texture_width > 0:
					arrow_sprite.scale.x = distance / texture_width
					arrow_sprite.scale.y = 0.3 
		
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
	# Jeśli jesteśmy w trybie celowania, ten blok przejmuje kliknięcia
	if targeting_card and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			finish_targeting()
			get_viewport().set_input_as_handled() # Zatrzymuje kliknięcie przed pójściem dalej
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			cancel_targeting()
			get_viewport().set_input_as_handled()


# --- LOGIKA CELOWANIA ---
func start_targeting(card):
	targeting_card = card
	if arrow_sprite: arrow_sprite.visible = true
	print("Rozpoczęto celowanie z karty: ", card.name)
	# Zmniejszamy kartę, jeśli była powiększona
	if card.has_method("set_hovered"):
		card.set_hovered(false)

func finish_targeting():
	var target_enemy = hovering_enemy_check()
	
	if target_enemy:
		print("TRAFIONO PRZECIWNIKA: ", target_enemy.name)
		if target_enemy.has_method("take_damage"):
			game_manager.mana -= int(hovered_card.cost)
			target_enemy.take(hovered_card)
			discard.add_to_discard(hovered_card)
			hand.recalculate_positions()
			#target_enemy.take_damage()
	else:
		# Jeśli chcesz sprawdzić czy trafiono inną kartę, zrób to tutaj
		print("Strzelono w puste pole.")
	
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
	parameters.collision_mask = COLLISION_MASK_ENEMY # Szukamy maski = 4
	
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		var hit_collider = result[0].collider
		print("TEST: Myszka dotknęła obiektu: ", hit_collider.name) # To nam bardzo pomoże w konsoli!
		
		# Sprawdzamy, czy sam trafiony obiekt ma funkcję (Scenariusz A)
		if hit_collider.has_method("take_damage"):
			return hit_collider
			
		# Sprawdzamy, czy jego rodzic ma funkcję (Scenariusz B)
		elif hit_collider.get_parent() and hit_collider.get_parent().has_method("take_damage"):
			return hit_collider.get_parent()
			
		# Jeśli nie znaleźliśmy funkcji, i tak zwracamy obiekt, żeby logika się nie popsuła
		return hit_collider 
		
	return null


# --- SYGNAŁY Z INPUT MANAGERA ---
func _on_card_left_clicked(card):
	if targeting_card: return # Ignoruj, jeśli celujemy
	
	if card.get_parent() == hand: 
		held_card = card
		hold_timer = 0.0

func _start_dragging(card):
	dragged_card = card
	card.is_dragged = true 
	card.z_index = 100 
	if card.has_method("set_hovered"): card.set_hovered(false) 

func _on_left_release():
	if targeting_card: return # Ignoruj, jeśli celujemy

	# To jest Twój KLIK - włącza tryb celowania strzałką!
	if held_card and not dragged_card:
		print("Karta kliknięta!")
		if held_card.cost <= game_manager.mana:
			start_targeting(held_card)

	# Puszczanie karty po przeciąganiu
	if dragged_card:
		dragged_card.is_dragged = false 
		dragged_card.z_index = 0 
		dragged_card = null
	
	held_card = null

func _on_card_right_clicked(card):
	if targeting_card: return # Ignoruj, jeśli celujemy
	
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
