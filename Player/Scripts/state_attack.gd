class_name State_Attack extends State

@export var attack_damage: float = 1.0
@export var attack_range: float = 60.0
@export var attack_duration: float = 0.4
@export var attack_knockback: float = 250.0

@onready var walk: State = $"../Walk"
@onready var idle: State = $"../Idle"
@onready var dash: State = $"../Dash"
@onready var attack_arc: AttackArc = $"../../AttackArc"

var attack_timer: float = 0.0
var has_attacked: bool = false




## what happens when the player enters this state?
func Enter() -> void:
	player.UpdateAnimation("attack")
	attack_timer = attack_duration
	has_attacked = false
	# Don't stop movement - player can move while attacking
	print("Melee attack!")
	pass
	
func Exit() -> void:
	has_attacked = false
	pass

func Process(_delta: float) -> State:
	attack_timer -= _delta
	
	# Perform attack at halfway point of animation
	if not has_attacked and attack_timer <= attack_duration * 0.5:
		perform_melee_attack()
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


func perform_melee_attack() -> void:
	# Show the attack arc animation
	if attack_arc:
		attack_arc.show_arc(player.cardinal_direction)
	
	# Check for enemies in arc range
	var bodies_in_scene = player.get_tree().get_nodes_in_group("enemies")
	
	for body in bodies_in_scene:
		if body == player:  # Don't attack self
			continue
			
		# Check if enemy is within arc range
		if is_in_attack_arc(body.global_position):
			# Calculate knockback direction
			var knockback_direction = (body.global_position - player.global_position).normalized()
			
			# Apply damage if the body has a health system
			if body.has_method("take_damage"):
				body.take_damage(attack_damage, knockback_direction * attack_knockback)
			elif body.has_method("apply_impulse") and body is RigidBody2D:
				# For physics bodies, just apply knockback
				body.apply_impulse(knockback_direction * attack_knockback)
			
			print("Melee attack hit: ", body.name, " for ", attack_damage, " damage!")
	
	print("Player melee attacks in direction: ", player.cardinal_direction)

func is_in_attack_arc(target_position: Vector2) -> bool:
	# Check if target is within attack range
	var distance = player.global_position.distance_to(target_position)
	if distance > attack_range:
		return false
	
	# Check if target is within the attack arc angle (90 degrees)
	var direction_to_target = (target_position - player.global_position).normalized()
	var attack_direction = player.cardinal_direction
	var angle_difference = acos(direction_to_target.dot(attack_direction))
	
	# Convert 90 degrees to radians and check if within arc
	return angle_difference <= (90.0 * PI / 180.0) * 0.5
