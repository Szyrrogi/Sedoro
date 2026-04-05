extends Node
class_name PassiveManager

# ============================================================
# PassiveManager - zarządza kartami pasywnymi gracza
#
# Karty pasywne to karty z exhaust=1, które po zagraniu
# NIE trafiają do odrzutni, lecz tu - i aktywują swój efekt
# na początku każdej tury gracza.
#
# Aby podpiąć: umieść ten Node jako dziecko GameManager lub Player,
# ustaw referencję game_manager, i wywołaj trigger_all_passives()
# w start_player_turn() GameManagera.
# ============================================================

@export var game_manager: Node  # referencja do GameManager

# Lista aktywnych efektów pasywnych: [ [effect_data, card_id], ... ]
var active_passives: Array = []

# Referencja do UI listy pasywnych (opcjonalnie - Label lub VBoxContainer)
@export var passives_ui: Control

func _ready():
	pass

# ============================================================
# DODAJ PASYWNĄ (wywoływane przez CardManager po zagraniu karty)
# ============================================================
func add_passive(card_id: int, effect_data: Array) -> void:
	active_passives.append({
		"card_id": card_id,
		"effect": effect_data
	})
	print("PassiveManager: dodano pasywną kartę ID=", card_id, " efekt=", effect_data)
	_update_ui()

# ============================================================
# AKTYWUJ WSZYSTKIE PASYWNE (wywoływane co turę gracza)
# ============================================================
func trigger_all_passives() -> void:
	if active_passives.is_empty():
		return

	print("PassiveManager: aktywuję ", active_passives.size(), " pasywnych efektów")

	for passive in active_passives:
		_apply_passive(passive)

func _apply_passive(passive: Dictionary) -> void:
	if not game_manager:
		game_manager = get_tree().root.find_child("GameManager", true, false)
	if not game_manager:
		return

	var player = game_manager.player
	var effect = passive["effect"]

	match effect[0]:
		# Efekt 11: draw_reduction +1 i +3 pancerza
		11:
			if player:
				player.draw_reduction_stacks += 1
				player.add_armor(3)
				print("Pasywna Twarda Głowa: draw_reduction=", player.draw_reduction_stacks, " armor+3")

		# Efekt 27: nałóż X trucizny na WSZYSTKICH wrogów
		27:
			var amount = effect[1] if effect.size() > 1 else 2
			for enemy in game_manager.enemies:
				if is_instance_valid(enemy):
					enemy.add_poison(amount)
			print("Pasywna Trująca Aura: ", amount, " trucizny na wszystkich")

		# Ogólny fallback - wyślij do gracza jako normalny efekt
		_:
			if player and player.has_method("_apply_effect"):
				player._apply_effect(effect)

# ============================================================
# USUŃ WSZYSTKIE PASYWNE (reset walki)
# ============================================================
func clear_all_passives() -> void:
	active_passives.clear()
	print("PassiveManager: usunięto wszystkie pasywne")
	_update_ui()

# ============================================================
# OPCJONALNE UI
# ============================================================
func _update_ui() -> void:
	if not passives_ui:
		return

	# Wyczyść poprzednie dzieci UI
	for child in passives_ui.get_children():
		child.queue_free()

	# Dodaj Label dla każdej pasywnej
	for passive in active_passives:
		var label = Label.new()
		var card_id = passive["card_id"]

		# Pobierz nazwę karty z bazy
		const DB = preload("res://Scripts/CardDatabase.gd")
		if DB.CARDS.has(card_id):
			label.text = "⚡ " + DB.CARDS[card_id][0]
		else:
			label.text = "⚡ Pasywna #" + str(card_id)

		label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
		passives_ui.add_child(label)
