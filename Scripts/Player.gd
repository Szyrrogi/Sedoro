extends Character

func _ready():
	super._ready()
	current_health = max_health / 2  # gracz startuje z połową hp
	if health_bar:
		health_bar.value = current_health

func die():
	print("aha umarlem se xd")
	# tu możesz np. odpalić ekran game over
