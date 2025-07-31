class_name Enemy extends CharacterBody2D

@export var max_health: float = 3.0
@export var knockback_resistance: float = 0.8
@export var collision_damage: float = 30.0
@export var chase_range: float = 120.0
@export var move_speed: float = 80.0
@export var damage_cooldown: float = 1.0

var current_health: float
var is_dead: bool = false
var damage_timer: float = 0.0
var player: Player = null
var knockback_timer: float = 0.0
var knockback_duration: float = 0.5

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	current_health = max_health
	# Add to enemies group so the attack system can find us
	add_to_group("enemies")
	# Assicura che l'enemy sia sopra la griglia
	z_index = 100
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_dead:
		return
	
	# Find player if we don't have reference
	if not player:
		find_player()
	
	# Update damage cooldown
	if damage_timer > 0:
		damage_timer -= delta
	
	# Update knockback timer
	if knockback_timer > 0:
		knockback_timer -= delta
	
	# Simple AI: only chase if not in knockback
	# DISABLED: Enemy movement disabled for grid-based gameplay
	# if player and knockback_timer <= 0:
	#	var distance_to_player = global_position.distance_to(player.global_position)
	#	if distance_to_player <= chase_range:
	#		chase_player(delta)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	# Apply basic gravity/friction to slow down knockback
	velocity = velocity.move_toward(Vector2.ZERO, 200.0 * delta)
	move_and_slide()
	
	# Check for collision damage
	check_collision_damage()

# This is called by the player's attack system
func take_damage(damage: float, knockback_vector: Vector2) -> void:
	if is_dead:
		return
	
	current_health -= damage
	print("Enemy took ", damage, " damage! Health: ", current_health)
	
	# Apply knockback
	velocity = knockback_vector * knockback_resistance
	
	# Start knockback timer to prevent AI interference
	knockback_timer = knockback_duration
	
	# Visual feedback - flash red briefly
	flash_damage()
	
	print("Enemy knocked back with velocity: ", velocity)
	
	# Check if dead
	if current_health <= 0:
		die()

func flash_damage() -> void:
	# Simple red flash effect
	if sprite:
		sprite.modulate = Color.RED
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)

func die() -> void:
	if is_dead:
		return
		
	is_dead = true
	print("Enemy died!")
	
	# Disable collision
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	
	# Visual death effect - fade out and scale down
	if sprite:
		var tween = create_tween()
		tween.parallel().tween_property(sprite, "modulate", Color(1, 1, 1, 0), 0.5)
		tween.parallel().tween_property(sprite, "scale", Vector2(0.5, 0.5), 0.5)
		tween.tween_callback(queue_free)  # Remove from scene after animation

func find_player() -> void:
	# Find the player node in the scene
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	else:
		# Fallback: search for Player class
		var all_nodes = get_tree().get_nodes_in_group("all")
		for node in all_nodes:
			if node is Player:
				player = node
				break

func chase_player(delta: float) -> void:
	if not player:
		return
	
	# Move toward player
	var direction_to_player = (player.global_position - global_position).normalized()
	velocity = direction_to_player * move_speed

func check_collision_damage() -> void:
	# Only damage if cooldown is finished
	if damage_timer > 0 or not player:
		return
	
	# Check if we're colliding with the player
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if collider is Player and not collider.is_invulnerable:
			print("Enemy collision damage!")
			
			# Calculate knockback direction (away from enemy)
			var knockback_direction = (collider.global_position - global_position).normalized()
			var knockback_force = knockback_direction * 200.0
			
			# Damage the player
			collider.take_damage(collision_damage, knockback_force)
			
			# Start damage cooldown
			damage_timer = damage_cooldown
			
			# Visual feedback - briefly change color
			if sprite:
				sprite.modulate = Color.YELLOW
				var tween = create_tween()
				tween.tween_property(sprite, "modulate", Color.WHITE, 0.3)
			
			break  # Only damage once per frame
