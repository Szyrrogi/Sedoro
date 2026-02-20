extends Node2D

@export var max_health: int = 30 
var current_health: int

@export var health_bar = TextureProgressBar
@onready var hit_sound: AudioStreamPlayer2D = $HitSound


func _ready():
	current_health = max_health
	if health_bar:
		health_bar.max_value = max_health 
		health_bar.value = current_health

func take(card: Node2D):
	print(card.effect)
	if card.effect[0] == 0:
		take_damage(card.effect[1])

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
	print("Przeciwnik pokonany!")
	
	# 1. Ukrywamy wroga i wyłączamy jego kolizję, żeby nie blokował kolejnych strzałek
	visible = false
	$Area2D.set_deferred("monitorable", false) 
	$Area2D.set_deferred("monitoring", false)
	
	# 2. Czekamy aż dźwięk skończy grać (jeśli w ogóle gra)
	if hit_sound and hit_sound.playing:
		await hit_sound.finished
		
	# 3. Dopiero teraz usuwamy wroga na dobre
	queue_free()
