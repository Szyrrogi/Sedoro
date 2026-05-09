extends Node

# ============================================================
# RunManager – Singleton (dodaj do AutoLoad w Project Settings)
# Ścieżka pliku save: res://Data/run_save.json
# ============================================================

const SAVE_PATH = "user://Data/run_save.json"

# Startowa talia gracza (ID kart) – używana w iteracji 0
const STARTING_DECK: Array = [0, 0, 0, 1, 1, 1, 2, 3, 4, 5, 6]

# ----------------------------------------------------------------
# TABELKA ITERACJI – edytuj tutaj jeśli chcesz zmienić kolejność
#
#   iteration : iteracja (kolumna 0 z twojej tabelki)
#   player    : postać gracza (kolumna 1) – 1 lub 2
#   boss      : skąd pochodzi boss (kolumna 2)
#               0 = zwykły boss z EnemyDatabase
#               N = deck gracza z iteracji N-1 (np. boss=1 → deck z iteracji 0)
#
#   iteracja | postać gracza | boss
#      0     |      1        |  0
#      1     |      2        |  1
#      2     |      1        |  2
#      3     |      2        |  1
#      4     |      1        |  2
# ----------------------------------------------------------------
const ITERATION_TABLE: Array = [
	{ "iteration": 0, "player": 1, "boss": 0 },
	{ "iteration": 1, "player": 2, "boss": 1 },
	{ "iteration": 2, "player": 1, "boss": 2 },
	{ "iteration": 3, "player": 2, "boss": 1 },
	{ "iteration": 4, "player": 1, "boss": 2 },
]

# Aktualnie załadowane dane
var current_iteration: int = 0
var current_player_char: int = 1
var current_boss_type: int = 0

# Historia poprzednich przejść
var history: Array = []
func _ready():
	_ensure_data_dir()
	load_save()

func _ensure_data_dir():
	var dir = DirAccess.open("user://")
	if dir and not dir.dir_exists("Data"):
		dir.make_dir("Data")
	# Wypisz pełną ścieżkę systemową do pliku save (pomocne przy szukaniu)
	print("[RunManager] Plik save: ", ProjectSettings.globalize_path(SAVE_PATH))

# ============================================================
# ZAPIS I ODCZYT
# ============================================================

func save_run(player_deck: Array):
	"""Zapisuje aktualny stan po pokonaniu bossa. NIE zmienia current_iteration – robi to advance_iteration() po resecie."""
	# Upewnij się że deck to inty (zabezpieczenie przed float)
	var clean_deck: Array = []
	for card_id in player_deck:
		clean_deck.append(int(card_id))

	var entry = {
		"iteration":   current_iteration,
		"player_char": current_player_char,
		"deck":        clean_deck
	}
	history.append(entry)

	var save_data = {
		"next_iteration": current_iteration + 1,
		"history": history
	}

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()
		print("[RunManager] Zapisano przejście ", current_iteration, " deck: ", clean_deck)
	else:
		push_error("[RunManager] Nie można zapisać pliku: " + SAVE_PATH)

func advance_iteration():
	"""Wywołaj PO zakończeniu resetu gracza – przesuwa do następnej iteracji."""
	_set_iteration(current_iteration + 1)
	print("[RunManager] Nowa iteracja: ", current_iteration, " | player: ", current_player_char, " | boss_type: ", current_boss_type)

func load_save():
	"""Wczytuje plik save, jeśli istnieje."""
	if not FileAccess.file_exists(SAVE_PATH):
		print("[RunManager] Brak save'a – startujemy od iteracji 0.")
		_set_iteration(0)
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		push_error("[RunManager] Nie można odczytać pliku: " + SAVE_PATH)
		_set_iteration(0)
		return

	var json = JSON.new()
	var err = json.parse(file.get_as_text())
	file.close()

	if err != OK:
		push_error("[RunManager] Błąd parsowania JSON: " + json.get_error_message())
		_set_iteration(0)
		return

	var data = json.get_data()
	var next_iter = int(data.get("next_iteration", 0))

	# Jeśli save mówi iteracja 0 – to świeża gra, kasujemy stary plik
	if next_iter == 0:
		reset_save()
		return

	# Wczytaj historię, konwertując floaty z JSON z powrotem na inty
	var raw_history = data.get("history", [])
	history.clear()
	for entry in raw_history:
		var clean_deck: Array = []
		for card_id in entry["deck"]:
			clean_deck.append(int(card_id))
		history.append({
			"iteration":   int(entry["iteration"]),
			"player_char": int(entry["player_char"]),
			"deck":        clean_deck
		})

	_set_iteration(next_iter)
	print("[RunManager] Wczytano save. Iteracja: ", current_iteration, " Historia: ", history.size(), " wpisów.")

func _set_iteration(iter: int):
	current_iteration = iter
	if iter < ITERATION_TABLE.size():
		var row = ITERATION_TABLE[iter]
		current_player_char = row["player"]
		current_boss_type   = row["boss"]
	else:
		# Iteracje poza tabelką – naprzemiennie jak ostatnie dwa wiersze
		var row = ITERATION_TABLE[ITERATION_TABLE.size() - 1 - (iter % 2)]
		current_player_char = row["player"]
		current_boss_type   = row["boss"]

# ============================================================
# GETTERY – używane przez GameManager i enemy.gd
# ============================================================

func get_starting_deck() -> Array:
	"""Zwraca talię z poprzedniego przejścia gracza (iteracja-1), lub domyślną."""
	if current_iteration == 0 or history.is_empty():
		print("[RunManager] get_starting_deck: brak historii, zwracam STARTING_DECK")
		return STARTING_DECK.duplicate()
	# Gracz w iteracji N gra talią z iteracji N-1
	var prev = history[current_iteration - 1]
	print("[RunManager] get_starting_deck: iteracja ", current_iteration, " → deck z iteracji ", current_iteration - 1, ": ", prev["deck"])
	return prev["deck"].duplicate()

func get_boss_deck() -> Array:
	"""Zwraca talię, którą boss-poprzednie-przejście ma używać."""
	if current_boss_type == 0 or history.is_empty():
		print("[RunManager] get_boss_deck: zwykły boss lub brak historii")
		return []
	var history_index = current_iteration - current_boss_type
	print("[RunManager] get_boss_deck: iteracja ", current_iteration, " boss_type ", current_boss_type, " → deck z historii[", history_index, "]")
	if history_index >= 0 and history_index < history.size():
		return history[history_index]["deck"].duplicate()
	push_error("[RunManager] get_boss_deck: brak wpisu w historii dla indeksu " + str(history_index))
	return []

func is_hero_boss() -> bool:
	"""Czy boss na końcu mapy to 'hero' (poprzednie przejście gracza)?"""
	if current_boss_type == 0:
		return false
	# Sprawdź czy faktycznie mamy historię dla tego boss_type
	var history_index = current_iteration - current_boss_type
	if history_index < 0 or history_index >= history.size():
		push_warning("[RunManager] is_hero_boss: brak historii[" + str(history_index) + "], fallback na zwykłego bossa")
		return false
	return true

func reset_save():
	"""Usuwa plik save i resetuje do iteracji 0."""
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	history.clear()
	_set_iteration(0)
	print("[RunManager] Save zresetowany.")
