class_name State_RangedAttack extends State

@export var attack_damage: float = 1.0
@export var attack_duration: float = 0.3
@export var projectile_speed: float = 400.0

@onready var walk: State = $"../Walk"
@onready var idle: State = $"../Idle"
@onready var dash: State = $"../Dash"

var attack_timer: float = 0.0
var has_attacked: bool = false
var mouse_position: Vector2 = Vector2.ZERO


## what happens when the player enters this state?
func Enter() -> void:
	player.UpdateAnimation("attack")
	attack_timer = attack_duration
	has_attacked = false
	# Don't stop movement - player can move while attacking
	
	# Capture mouse position for ranged attack
	mouse_position = player.get_global_mouse_position()
	print("Ranged attack toward: ", mouse_position)
	pass
	
func Exit() -> void:
	has_attacked = false
	pass

func Process(_delta: float) -> State:
	attack_timer -= _delta
	
	# Perform attack at halfway point of animation
	if not has_attacked and attack_timer <= attack_duration * 0.5:
		perform_ranged_attack()
		has_attacked = true
	
	# Allow movement while attacking
	if player.direction != Vector2.ZERO:
		player.velocity = player.direction * 100.0  # Same speed as walking
		# Update direction for sprite flipping during movement
		player.SetDirection()
	else:
		player.velocity = Vector2.ZERO
	
	# End attack when timer runs out
	if attack_timer <= 0.0:
		# Transition based on movement input
		if player.direction != Vector2.ZERO:
			return walk
		else:
			return idle
	
	return null
	

func Physics(_delta: float) -> State:
	return null 


func HandleInput(_event: InputEvent) -> State:
	if _event.is_action_pressed("dash") and player.can_dash:
		return dash
	return null


func perform_ranged_attack() -> void:
	# Shoot projectile toward mouse position
	player.shoot_projectile(mouse_position)
