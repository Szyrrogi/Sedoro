extends Character




var game_manager: Node 




@export var player: Node2D
@export var status_text: RichTextLabel
@export var status_art: Sprite2D

# NOWE: Referencja do głównego obrazka przeciwnika, by móc go podmieniać
@export var sprite: Sprite2D 

const CardDatabase = preload("res://Scripts/CardDatabase.gd")
# EnemyDatabase jest globalną klasą (class_name) – nie trzeba jej importować

var deck_data = []

# Zmienne przechowujące ZAPLANOWANĄ akcję (zamiar przeciwnika)
var planned_card_id = -1
var planned_effect = null
var planned_put_type = -1

func _ready():
	super()
	# UWAGA: Usunięto stąd plan_next_action(). Wywoła się dopiero po wczytaniu talii!

# Wczytuje dane wroga po stworzeniu go przez GameManager (zwykły wróg)
func setup(enemy_id: int):
	var data = EnemyDatabase.ENEMY[enemy_id]
	# data = ["Wąż", "Enemy1", 10, [101,101,102]] (czyli [Nazwa, Obrazek, Zdrowie, Deck])
	
	self.name = data[0]
	
	# Ustawienie zdrowia (zmienne dziedziczone z klasy Character)
	max_health = data[2]
	current_health = max_health
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
		
	# Skopiowanie talii z bazy
	deck_data = data[3].duplicate()
	
	# Podmiana grafiki wroga
	if sprite:
		sprite.texture = load("res://Art/Enemy/" + str(data[1]) + ".png")
		
	# Losujemy pierwszy ruch po ustawieniu wszystkiego!
	plan_next_action()

# NOWE: Ustawia bossa jako "hero boss" – postać z poprzedniego przejścia gracza
func setup_as_hero_boss(hero_deck: Array):
	self.name = "Hero"

	# Zdrowie bossa – możesz dostosować mnożnik
	max_health = 60
	current_health = max_health
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health

	# Deck bossa = talia gracza z poprzedniego przejścia
	deck_data = hero_deck.duplicate()
	deck_data.shuffle()

	# Grafika bossa-bohatera
	if sprite:
		var tex_path = "res://Art/Enemy/Hero2.3.png"
		if ResourceLoader.exists(tex_path):
			sprite.texture = load(tex_path)
		else:
			push_warning("[enemy.gd] Brak grafiki hero bossa: " + tex_path)

	plan_next_action()

# Funkcja wywoływana, gdy nadchodzi tura przeciwnika
func action():
	# 1. Najpierw WYKONAJ to, co zaplanowałeś w poprzedniej turze
	if planned_card_id != -1:
		execute_planned_action()
	
	# 2. Następnie ZAPLANUJ i POKAŻ graczowi co zrobisz w kolejnej turze
	plan_next_action()

func execute_planned_action():
	var card_data = CardDatabase.CARDS[planned_card_id]
	var card_name = card_data[0]
	
	print("Przeciwnik wykonuje zaplanowaną kartę: ", card_name)

	var virtual_card = {
		"effect": planned_effect
	}

	if planned_put_type == 0:
		print("Przeciwnik atakuje Gracza!")
		player.take(virtual_card)
		
	elif planned_put_type == 1:
		print("Przeciwnik używa karty na sobie!")
		self.take(virtual_card)

func plan_next_action():
	if deck_data.is_empty():
		print("Przeciwnik nie ma już kart w talii!")
		planned_card_id = -1
		if status_text: status_text.text = ""
		if status_art: status_art.texture = null
		return

	# Losowanie – szukamy karty którą boss może użyć (ma put_type i effect)
	deck_data.shuffle()
	var found = false
	for card_id in deck_data:
		if not CardDatabase.CARDS.has(card_id):
			continue
		var card_data = CardDatabase.CARDS[card_id]
		if card_data.size() < 7:
			continue  # karta gracza bez put_type/effect – pomijamy
		planned_card_id = card_id
		planned_put_type = card_data[5]
		planned_effect   = card_data[6]
		found = true
		break

	if not found:
		print("Boss nie ma żadnej grywalnej karty w talii!")
		planned_card_id = -1
		if status_text: status_text.text = ""
		if status_art: status_art.texture = null
		return

	# Aktualizacja interfejsu (pokazanie intencji)
	if status_text:
		status_text.text = "[font_size=100]" + str(planned_effect[1])
	if status_art:
		var art_path = "res://Art/Stats/Status" + str(planned_effect[0]) + ".png"
		if ResourceLoader.exists(art_path):
			status_art.texture = load(art_path)
		else:
			status_art.texture = null

func die():
	print("Przeciwnik ", self.name, " został pokonany!")
	
	# Korzystamy z bezpośredniej referencji, a nie z find_child
	if game_manager and game_manager.enemies.has(self):
		game_manager.enemies.erase(self)
		print("Usunięto wroga z listy enemies. Pozostało wrogów: ", game_manager.enemies.size())
		
		# --- Sprawdzenie wygranej ---
		if game_manager.enemies.size() == 0:
			# Opóźniamy nieco wywołanie win_battle, by dać pętli wroga się zakończyć
			game_manager.call_deferred("win_battle")
			
	# Na koniec wywołujemy die() z character.gd
	super()
