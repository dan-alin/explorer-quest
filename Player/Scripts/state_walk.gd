class_name State_Walk extends State

@export var move_speed: float = 100.0
@onready var idle: State = $"../Idle"
@onready var dash: State = $"../Dash"
@onready var attack: State = $"../Attack"
@onready var ranged_attack: State = $"../RangedAttack"


## what hapens when the player enters this state?
func Enter() -> void:
	player.UpdateAnimation("walk")
	pass
	
func Exit() -> void:
	pass

func Process(_delta: float) -> State:
	if player.direction == Vector2.ZERO:
		return idle
	
	player.velocity = player.direction * move_speed
	
	if player.SetDirection():
		player.UpdateAnimation("walk")
	return null
	

func Physics(_delta: float) -> State:
	return null 


func HandleInput(_event: InputEvent) -> State:
	if _event.is_action_pressed("dash") and player.can_dash:
		return dash
	if _event.is_action_pressed("click"):
		return attack
	if _event.is_action_pressed("ranged_attack"):
		return ranged_attack
	return null
