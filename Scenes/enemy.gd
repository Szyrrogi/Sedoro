extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


# Znajdujemy nasz głośnik
@onready var hit_sound = $HitSound

# Ta funkcja zostanie wywołana przez CardManager, gdy trafi go strzałka
func take_damage():
	print("Ała! Dostałem!")
	
	# Jeśli mamy dźwięk, odtwórz go
	if hit_sound:
		hit_sound.play()
		
	# Tu możesz dodać też animację, np.:
	# scale = Vector2(0.9, 0.9) # Przeciwnik się kuli z bólu
