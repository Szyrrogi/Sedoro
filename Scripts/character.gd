extends Node2D
class_name Character

@export var max_health: int = 30
var current_health: int
var current_armor: int

@export var health_bar: TextureProgressBar
@onready var hit_sound: AudioStreamPlayer2D = $HitSound
@export var armor_label: RichTextLabel 

func _ready():
	current_health = max_health
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
	set_armor()
		
func start_tunr():
	current_armor = 0
	set_armor()
	
func set_armor():
	print("wdo")
	if current_armor == 0:
		armor_label.text=""
	else:
		armor_label.text = "[font_size=155][color=white]" + str(current_armor)

func add_armor(amount: int = 10):
	print("ddd")
	current_armor += amount
	set_armor()

func take(card):
	print(card.effect)
	print("nigga")
	if card.effect[0] == 0:
		take_damage(card.effect[1])
		
	if card.effect[0] == 1:
		add_armor(card.effect[1])
		
	if card.effect[0] == 3:
		heal(card.effect[1])

func heal(amount: int):
	current_health = min(amount+current_health,max_health)
	health_bar.value = current_health

func take_damage(amount: int = 10):
	if(current_armor >= amount):
		current_armor -= amount
	else:
		amount -= current_armor
		current_armor = 0
		current_health -= amount
	set_armor()
	
	if hit_sound:
		hit_sound.play()
		
	if health_bar:
		health_bar.value = current_health
		
	if current_health <= 0:
		die()

func die():
	queue_free()
