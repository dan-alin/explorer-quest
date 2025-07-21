class_name State_Dash extends State

@export var dodge_speed: float = 350.0
@export var dodge_duration: float = 0.3
@export var dodge_cooldown: float = 1.2
@export var invincibility_duration: float = 0.25

@onready var idle: State = $"../Idle"
@onready var walk: State = $"../Walk"

var dodge_timer: float = 0.0


## what happens when the player enters this state?
func Enter() -> void:
	# Use current movement direction, or last cardinal direction if not moving
	if player.direction != Vector2.ZERO:
		player.dash_direction = player.direction.normalized()
	else:
		player.dash_direction = player.cardinal_direction
	
	player.can_dash = false
	dodge_timer = dodge_duration
	
	# Set dodge velocity
	player.velocity = player.dash_direction * dodge_speed
	
	# Grant invincibility during dodge
	player.set_invulnerable(invincibility_duration)
	
	# Disable collision with enemies during dodge
	set_enemy_collision(false)
	
	# For now, use the walk animation since we don't have dodge sprites
	player.UpdateAnimation("walk")
	print("Player dodges through enemies!")
	pass
	
func Exit() -> void:
	# Re-enable collision with enemies
	set_enemy_collision(true)
	
	# Start cooldown timer
	var cooldown_timer = get_tree().create_timer(dodge_cooldown)
	cooldown_timer.timeout.connect(_on_dodge_cooldown_finished)
	pass

func Process(_delta: float) -> State:
	dodge_timer -= _delta
	
	# End dodge when timer runs out
	if dodge_timer <= 0.0:
		# Check if player is still inputting movement
		if player.direction != Vector2.ZERO:
			return walk
		else:
			return idle
	
	# Continue dodging
	player.velocity = player.dash_direction * dodge_speed
	return null
	

func Physics(_delta: float) -> State:
	return null 


func HandleInput(_event: InputEvent) -> State:
	return null 


func _on_dodge_cooldown_finished() -> void:
	player.can_dash = true

func set_enemy_collision(enabled: bool) -> void:
	# Simple approach: disable all enemy collision shapes during dodge
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy.has_node("CollisionShape2D"):
			var collision_shape = enemy.get_node("CollisionShape2D")
			if collision_shape:
				collision_shape.set_deferred("disabled", not enabled)
	
	if not enabled:
		print("Dodge: Disabled collision with ", enemies.size(), " enemies")
	else:
		print("Dodge ended: Re-enabled collision with enemies")
