extends Node

# Referencje do innych systemów
@export var deck: Node2D
@export var hand: Node2D
@export var discard: Node2D
@export var end_turn_button: Button
@export var shuffle_button: Button # NOWE: Przycisk za 3 many do odzyskiwania kart
@export var mana_manager: Node2D
@export var player: Node2D
@export var card_manager: Node2D

@export var enemies: Array[Node] # Tablica, która teraz będzie wypełniana automatycznie
@export var enemy_scene: PackedScene # Scena .tscn z Twoim przeciwnikiem
@export var spawn_start_position: Vector2 = Vector2(1300, 500) # Środek prawej strony ekranu (zmień pod swoją rozdzielczość)
@export var spawn_spacing: float = 300.0 # Odstęp między przeciwnikami

# Prosta maszyna stanów
enum State { PLAYER_START, PLAYER_ACTION, ENEMY_TURN }
var current_state = State.PLAYER_START

const HAND_LIMIT = 5
const CARDS_PER_TURN = 3
const CARDS_START = 4 # Nowa stała dla pierwszej tury
const MANA_MAX = 5
const SHUFFLE_COST = 3 # Koszt przetasowania kart z odrzuconych do talii

var is_first_turn: bool = true # Flaga sprawdzająca, czy to początek gry
var mana = 6

func _ready():
	if end_turn_button:
		end_turn_button.pressed.connect(_on_end_turn_button_pressed)
		
	if shuffle_button:
		shuffle_button.pressed.connect(_on_shuffle_button_pressed)
		
	player.modulate = Color(1, 1, 1)
	
	# === TWORZYMY HORDĘ WROGÓW ===
	spawn_horde(0)
	
	await get_tree().create_timer(0.5).timeout
	start_player_turn()

# NOWA FUNKCJA TWORZĄCA WROGÓW
func spawn_horde(horde_id: int):
	enemies.clear() # Czyścimy starych wrogów
	
	const EnemyDatabase = preload("res://Scripts/EnemyDatabase.gd")
	if not EnemyDatabase.HORD.has(horde_id):
		push_error("Brak hordy o ID: " + str(horde_id))
		return
		
	var horde = EnemyDatabase.HORD[horde_id]
	var enemy_count = horde.size()
	
	# Szerokość całej grupy, byśmy mogli ich idealnie wyśrodkować
	var total_width = (enemy_count - 1) * spawn_spacing
	var start_x = spawn_start_position.x - (total_width / 2.0)
	
	for i in range(enemy_count):
		var enemy_id = horde[i]
		
		# Tworzymy nowego przeciwnika ze sceny
		var enemy_inst = enemy_scene.instantiate()
		
		# Dodajemy go do sceny (możesz też stworzyć pusty Node2D "Enemies" i dać 'enemies_parent.add_child(enemy_inst)')
		add_child(enemy_inst)
		
		# Podpinamy zmienne
		enemy_inst.player = player
		enemy_inst.modulate = Color(1, 1, 1)
		
		# Ustawiamy statystyki z bazy danych
		enemy_inst.setup(enemy_id)
		
		# Ustawiamy go na planszy - układając od lewej do prawej
		enemy_inst.global_position = Vector2(start_x + (i * spawn_spacing), spawn_start_position.y)
		
		# Dodajemy go do oficjalnej tury
		enemies.append(enemy_inst)
	
func _process(delta: float) -> void:
	mana_manager.set_mana(mana)
	
	if shuffle_button:
		# POPRAWKA: Patrzymy na wielkość tablicy discard_data w skrypcie Discard
		var discard_count = discard.discard_data.size()
		
		# Przycisk widoczny tylko jeśli są karty w odrzuconych
		shuffle_button.visible = discard_count > 0 
		
		# Przycisk aktywny tylko jeśli jest nasza tura i mamy min. 3 many
		shuffle_button.disabled = mana < SHUFFLE_COST or current_state != State.PLAYER_ACTION

func _on_shuffle_button_pressed():
	print("klika")
	if current_state == State.PLAYER_ACTION and mana >= SHUFFLE_COST:
		mana -= SHUFFLE_COST
		print("Ręczne przenoszenie odrzuconych kart do talii...")
		
		# POPRAWKA: Używamy gotowej funkcji, którą masz już w Deck.gd!
		deck.reshuffle_from_discard()
			
		print("Karty przetasowane! Pozostała mana: ", mana)

func _on_end_turn_button_pressed():
	if current_state == State.PLAYER_ACTION:
		end_player_turn()



func start_player_turn():
	current_state = State.PLAYER_START
	print("\n--- POCZĄTEK TURY GRACZA ---")
	mana = MANA_MAX
	player.start_tunr() # Zachowałem Twoją oryginalną literówkę w nazwie funkcji ;)
	
	# NOWE: Podświetlenie gracza podczas jego tury (lekko jaśniejszy)
	player.modulate = Color(1.5, 1.5, 1.5)
	
	# --- LOGIKA DOBIERANIA ---
	var current_hand_size = hand.get_child_count()
	
	# Ile chcemy dobrać? 4 na start, potem po 3
	var cards_to_draw = CARDS_START if is_first_turn else CARDS_PER_TURN
	
	# Sprawdzamy limit ręki (5)
	var space_in_hand = HAND_LIMIT - current_hand_size
	
	# Dobieramy tylko tyle, na ile jest miejsce
	var final_draw_count = min(cards_to_draw, space_in_hand)
	
	if final_draw_count > 0:
		print("Dobieram: ", final_draw_count, " kart.")
		
		# Upewnij się, że funkcja draw_cards w skrypcie talii (deck) NIE uzupełnia jej już
		# automatycznie. Powinna po prostu zwrócić pustą tablicę, gdy zabraknie kart!
		var new_cards = await deck.draw_cards(final_draw_count)
		
		for card in new_cards:
			hand.add_card(card)
			await get_tree().create_timer(0.2).timeout
	else:
		print("Ręka pełna! Masz 5 kart, więc nic nie dostajesz.")
	
	is_first_turn = false # Pierwsza tura za nami, wyłączamy flagę
	current_state = State.PLAYER_ACTION
	print("Faza akcji: Zrób coś mądrego z tymi kartami.")

func end_player_turn():
	if current_state != State.PLAYER_ACTION:
		return
	
	print("Koniec tury gracza. Czas na sprzątanie...")
	
	card_manager.active = 0
	card_manager.set_active()
	var cards_in_hand = hand.get_all_cards().duplicate()
	
	for card in cards_in_hand:
		if card.is_selected:
			# ZAZNACZONE lecą na śmietnik!
			card.set_selected(false) # Resetujemy stan wizualny przed wyrzuceniem
			hand.remove_card(card)   # Wyrywamy z ręki
			discard.add_to_discard(card) # Rzucamy na pożarcie do Discardu
		else:
			# Niezaznaczone grzecznie zostają na ręce
			pass
			
	# Przejście do tury wroga
	start_enemy_turn()

func start_enemy_turn():
	current_state = State.ENEMY_TURN
	print("Tura przeciwnika...")
	
	# NOWE: Zgaszenie podświetlenia gracza (wraca do normalnego koloru)
	player.modulate = Color(1, 1, 1)
	
	for enemy in enemies:
		# NOWE: Podświetlenie przeciwnika, który w tym momencie się rusza
		enemy.modulate = Color(1.5, 1.5, 1.5)
		
		enemy.action()
		await get_tree().create_timer(1).timeout
		
		# NOWE: Zgaszenie podświetlenia przeciwnika po jego akcji
		enemy.modulate = Color(1, 1, 1)
		
	await get_tree().create_timer(1).timeout
	
	print("Przeciwnik zakończył ruch.")
	start_player_turn()
	
func set_button_active(is_active: bool):
	if end_turn_button:
		end_turn_button.disabled = !is_active
		if is_active:
			end_turn_button.text = "ZAKOŃCZ TURĘ"
		else:
			end_turn_button.text = "CZEKAJ..."

func _input(event):
	if event.is_action_pressed("ui_accept"):
		end_player_turn()
