extends Node2D
class_name Card

var is_selected: bool = false
var is_dragged: bool = false # Czy gracz ją trzyma?
var is_hovered: bool = false # Czy myszka jest nad nią?

var target_position: Vector2 = Vector2.ZERO

# --- USTAWIENIA WIZUALNE ---
const SCALE_NORMAL = Vector2(1.0, 1.0)
const SCALE_HOVER = Vector2(1.2, 1.2) # Powiększenie
const COLOR_SELECTED = Color(0.6, 1.0, 0.6) # Zielonkawy
const COLOR_NORMAL = Color.WHITE

var id: int = 0

func _ready():
	# Ważne: Żeby raycast trafiał w kartę, Area2D musi być w tej warstwie
	# Upewnij się w edytorze, że Area2D ma Collision Layer = 1
	pass

func _process(delta):
	# LOGIKA RUCHU
	if is_dragged:
		# Jeśli ciągniemy, pozycją steruje CardManager/Myszka
		# Możemy tu dodać lekkie pochylanie przy ruchu (juice)
		pass 
	else:
		# Jeśli nie ciągniemy, wracamy do pozycji w ręce (Lerp)
		position = position.lerp(target_position, 15 * delta)
		
		# Proste zarządzanie Z-Indexem (żeby hovered była wyżej)
		if is_hovered:
			z_index = 50
		elif is_selected:
			z_index = 10 # Wybrane lekko wyżej
		else:
			z_index = 0

	# LOGIKA SKALI (Lerp dla płynnego powiększania)
	var target_scale = SCALE_HOVER if is_hovered else SCALE_NORMAL
	scale = scale.lerp(target_scale, 20 * delta)

func setup_card(_id: int):
	id = _id
#	Tu będzie się uzupełniać

# --- PUBLICZNE METODY ---
func set_selected(state: bool):
	is_selected = state
	update_color()

func set_hovered(state: bool):
	is_hovered = state
	# Tutaj nie zmieniamy skali natychmiast, robimy to w _process (lerp)

func update_color():
	if is_selected:
		modulate = COLOR_SELECTED
		# Opcjonalnie: Włącz ramkę / Shader
	else:
		modulate = COLOR_NORMAL

# --- SETUP ---
func set_start_position(pos: Vector2):
	position = pos
	target_position = pos
