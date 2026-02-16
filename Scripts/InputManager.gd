extends Node2D

# Sygnały
signal card_left_clicked(card_node)
signal card_right_clicked(card_node) # NOWE: Do zaznaczania
signal deck_left_clicked
signal background_clicked
signal left_mouse_button_released

const COLLISION_MASK_CARD = 1
const COLLISION_MASK_DECK = 4

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Lewy klik (start drag)
				handle_click(true) 
			else:
				# Lewy puszczony (stop drag)
				emit_signal("left_mouse_button_released")
				
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			# Prawy klik (selection)
			handle_click(false)

# Uniwersalna funkcja do kliknięć
func handle_click(is_left_click: bool):
	var result = raycast_at_cursor()
	
	if result:
		var collider = result.collider
		var parent = collider.get_parent()
		
		if collider.collision_mask == COLLISION_MASK_CARD:
			if is_left_click:
				emit_signal("card_left_clicked", parent)
			else:
				emit_signal("card_right_clicked", parent)
				
		elif collider.collision_mask == COLLISION_MASK_DECK and is_left_click:
			emit_signal("deck_left_clicked")
	else:
		if is_left_click:
			emit_signal("background_clicked")

# Ta funkcja teraz zwraca wynik, żeby CardManager mógł jej używać do HOVERA w _process
func raycast_at_cursor():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_CARD | COLLISION_MASK_DECK 
	
	var results = space_state.intersect_point(parameters)
	
	if results.size() > 0:
		return get_topmost_object(results)
	return null

func get_topmost_object(results_array):
	if results_array.size() == 1:
		return results_array[0]
	
	var highest_z_object = results_array[0]
	var highest_z_index = -999
	
	for hit in results_array:
		var parent = hit.collider.get_parent()
		if parent.get("z_index") != null:
			if parent.z_index > highest_z_index:
				highest_z_object = hit
				highest_z_index = parent.z_index
				
	return highest_z_object
