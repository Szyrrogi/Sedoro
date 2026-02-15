extends Node2D
#
#signal left_mouse_button_clicked
#signal left_mouse_button_released
#
#var card_manager_reference
#var deck_reference
#
#func _ready() -> void:
	#card_manager_reference = $"../CardManager"
	## deck_reference = $"../Deck" # Odkomentuj jak będziesz miał Deck
#
#func _input(event):
	#if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		#if event.pressed:
			#emit_signal("left_mouse_button_clicked")
			#raycast_at_coursor()
		#else:
			#emit_signal("left_mouse_button_released")
#
#func raycast_at_coursor():
	#var space_state = get_world_2d().direct_space_state
	#var parameters = PhysicsPointQueryParameters2D.new()
	#parameters.position = get_global_mouse_position()
	#parameters.collide_with_areas = true
	#parameters.collision_mask = 5 # 1 (karty) + 4 (deck)
	#
	#var result = space_state.intersect_point(parameters)
	#
	#if result.size() > 0:
		#var result_collision_layer = result[0].collider.collision_layer 
		#
		#if result_collision_layer == 1:
			#var card_found = result[0].collider.get_parent()
			#if card_found:
				#card_manager_reference.start_drag(card_found)
		##elif result_collision_layer == 4:
			##deck_reference.draw_card()
