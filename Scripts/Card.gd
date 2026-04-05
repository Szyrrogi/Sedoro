extends Node2D
class_name Card

var is_selected: bool = false
var is_dragged: bool = false
var is_hovered: bool = false

@export var frame: Node2D
const CardDatabase = preload("res://Scripts/CardDatabase.gd")

var target_position: Vector2 = Vector2.ZERO

const SCALE_NORMAL = Vector2(1.0, 1.0)
const SCALE_HOVER = Vector2(1.2, 1.2)
const COLOR_SELECTED = Color(0.6, 1.0, 0.6)
const COLOR_NORMAL = Color.WHITE

var id: int = 0
var effect          # główny efekt [opcode, ...]
var effect_extra    # efekt warunkowy (drugi efekt z wymaganiem koloru)
var cost_color      # kolor wymagany dla efektu extra
var cost: int       # bazowy koszt many
var put_type: int   # cel: 0=wybrany wróg, 1=gracz, 2=wszyscy wrogowie
var active: int     # kolor aktywacji (używany przez CardManager)
var exhaust: bool = false  # NOWE: czy karta znika po zagraniu

# Rzeczywisty koszt po rabatach (np. karta 35 trucizny)
var effective_cost: int = -1

func _ready():
	pass

func _process(delta):
	if is_dragged:
		pass 
	else:
		position = position.lerp(target_position, 15 * delta)
		
		if is_hovered:
			z_index = 50
		elif is_selected:
			z_index = 10
		else:
			z_index = 0

	var target_scale = SCALE_HOVER if is_hovered else SCALE_NORMAL
	scale = scale.lerp(target_scale, 20 * delta)

func setup_card(_id: int):
	id = _id
	var data = CardDatabase.CARDS[_id]

	put_type   = data[5]
	effect     = data[6]
	cost       = data[1]
	active     = data[7]
	exhaust    = data[9] == 1 if data.size() > 9 else false

	if data[4].size() > 0:
		effect_extra = data[4][2]
		cost_color   = data[4][0]

	effective_cost = cost

	# Rabat dla karty Trująca Osłona (efekt [25, X, min_poison]):
	# kosztuje 2 mniej jeśli wybrany wróg ma ≥ min_poison trucizny
	_recalculate_cost()

	frame.set_up(_id)
	print("Card setup: ", data[0], " exhaust=", exhaust, " efekt=", effect)

# ============================================================
# PRZELICZ KOSZT (wywołaj po wyborze celu lub na początku tury)
# ============================================================
func _recalculate_cost():
	if effect is Array and effect[0] == 25 and effect.size() >= 3:
		var min_poison = effect[2]
		var gm = get_tree().root.find_child("GameManager", true, false)
		if gm and gm.enemies.size() > 0:
			# Sprawdź wybranego wroga lub pierwszego
			for enemy in gm.enemies:
				if is_instance_valid(enemy) and "poison_stacks" in enemy:
					if enemy.poison_stacks >= min_poison:
						effective_cost = max(0, cost - 2)
						return
		effective_cost = cost
	else:
		effective_cost = cost

# ============================================================
# CZY TO KARTA PASYWNA?
# Pasywna = jej efekt jest aktywowany co turę przez PassiveManager
# a nie bezpośrednio przy zagraniu.
# ============================================================
func is_passive() -> bool:
	if not (effect is Array): return false
	# Efekty pasywne: 11 (Twarda Głowa), 27 (Trująca Aura)
	return effect[0] in [11, 27]

# ============================================================
# PUBLICZNE METODY
# ============================================================
func set_selected(state: bool):
	is_selected = state
	update_color()

func set_hovered(state: bool):
	is_hovered = state

func update_color():
	modulate = COLOR_SELECTED if is_selected else COLOR_NORMAL

func set_start_position(pos: Vector2):
	position = pos
	target_position = pos
