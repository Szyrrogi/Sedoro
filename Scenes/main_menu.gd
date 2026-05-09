extends Control
@onready var game_manager = $"../GameManager"
@onready var main_menu = $"." 
@onready var settings_panel = $"../OverlayUI/SettingsPanel"
@onready var settings_icon = $"../OverlayUI/OpenSettingsButton"
@onready var save_button = $"../OverlayUI/SaveButton"

func _ready():
	# Na starcie: widzimy menu, nie widzimy panelu ani ikonki ustawień
	main_menu.visible = true
	settings_panel.visible = false
	settings_icon.visible = false

# Kliknięcie NOWA GRA w menu
func _on_new_game_button_pressed():
	# Przed startem nowej gry upewnijmy się, że stara, zapisana mapa nie "wisi" w pamięci
	game_manager._regenerate_map()
	game_manager._reset_player_for_new_run()

	self.visible = false
	settings_icon.visible = true
	save_button.visible = true

# Kliknięcie ikonki ustawień w rogu (podczas gry/walki)
func _on_settings_button_pressed():
	print("Kliknieto w ustawienia z Menu Glownego!")
	settings_panel.visible = true
	
func _on_open_settings_button_pressed():
	print("Kliknieto w ikonke ustawien z poziomu gry!")
	settings_panel.visible = true

# Kliknięcie POWRÓT w panelu ustawień
func _on_back_button_pressed():
	settings_panel.visible = false
	# get_tree().paused = false # Jeśli użyłeś pauzy powyżej
	
func _on_save_button_pressed():
	game_manager.save_mid_run()
	
func _on_load_game_button_pressed():
	if game_manager.load_mid_run():
		# Jeśli wczytano sukcesem, schowaj menu i pokaż widok mapy
		self.visible = false 
		settings_icon.visible = true
		save_button.visible = true
		
		# Upewniamy się, że widać tylko mapę, a nie ekran walki z menu głównego
		game_manager.combat_node.hide()
		game_manager.map_node.show()
	else:
		print("Brak zapisu do wczytania!")
