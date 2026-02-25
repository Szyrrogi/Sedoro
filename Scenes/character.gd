extends Node2D

@export var max_health: int = 30 
var current_health: int

@export var health_bar = TextureProgressBar
@onready var hit_sound: AudioStreamPlayer2D = $HitSound


func _ready():
	current_health = max_health/2
	if health_bar:
		health_bar.max_value = max_health 
		health_bar.value = current_health

#func take(card: Node2D):
#	print(card.effect)
#	if card.effect[0] == 0:
#		take_damage(card.effect[1])

func take_damage(amount: int = 10):
	current_health -= amount
	
	# ODTWARZANIE DŹWIĘKU TRAFIENIA
	if hit_sound:
		hit_sound.play()
		
	if health_bar:
		health_bar.value = current_health
		
	if current_health <= 0:
		die()
		
func die():
	print("aha umarlem se xd")
