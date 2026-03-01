extends Character

@export var player: Node2D
@export var status_text: RichTextLabel
@export var status_art: Sprite2D

# NOWE: Referencja do głównego obrazka przeciwnika, by móc go podmieniać
@export var sprite: Sprite2D 

const CardDatabase = preload("res://Scripts/CardDatabase.gd")
const EnemyDatabase = preload("res://Scripts/EnemyDatabase.gd") # NOWE

var deck_data = []

# Zmienne przechowujące ZAPLANOWANĄ akcję (zamiar przeciwnika)
var planned_card_id = -1
var planned_effect = null
var planned_put_type = -1

func _ready():
	super()
	# UWAGA: Usunięto stąd plan_next_action(). Wywoła się dopiero po wczytaniu talii!

# NOWA FUNKCJA: Wczytuje dane wroga po stworzeniu go przez GameManager
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
		status_text.text = ""
		status_art.texture = null
		return
		
	# Losowanie karty
	deck_data.shuffle() 
	planned_card_id = deck_data[0]
	
	# Zapisanie danych karty do zmiennych zaplanowanej akcji
	var card_data = CardDatabase.CARDS[planned_card_id]
	planned_put_type = card_data[5]
	planned_effect = card_data[6]
	
	# Aktualizacja interfejsu (pokazanie intencji)
	status_text.text = "[font_size=100]" + str(planned_effect[1])
	status_art.texture = load("res://Art/Stats/Status" + str(planned_effect[0]) + ".png")

func die():
	print("Przeciwnik ", self.name, " został pokonany!")
	
	# Szukamy GameManagera na scenie
	var game_manager = get_tree().root.find_child("GameManager", true, false)
	
	# Jeśli znaleźliśmy GameManager i ten przeciwnik jest na liście, usuwamy go
	if game_manager and game_manager.enemies.has(self):
		game_manager.enemies.erase(self)
		print("Usunięto wroga z listy enemies. Pozostało wrogów: ", game_manager.enemies.size())
		
	# Na koniec wywołujemy die() z character.gd, co fizycznie usunie go z gry (queue_free)
	super()
