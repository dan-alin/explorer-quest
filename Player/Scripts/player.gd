class_name Player extends CharacterBody2D

var cardinal_direction: Vector2 = Vector2.DOWN
var direction: Vector2 = Vector2.ZERO

# Health properties
@export var max_health: float = 100.0
var current_health: float
var is_invulnerable: bool = false

# Dash/Dodge properties
var dash_direction: Vector2 = Vector2.ZERO
var can_dash: bool = true

# Projectile system
@export var projectile_scene: PackedScene
var projectile_spawn_offset: float = 20.0


@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
@onready var state_machine: PlayerStateMachine = $StateMachine


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	current_health = max_health
	add_to_group("player")  # Add to group so enemies can find us
	state_machine.Initialize(self)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	direction.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	direction.y = Input.get_action_strength("down") - Input.get_action_strength("up")
	
	pass


func _physics_process(delta: float) -> void:
	move_and_slide()


func SetDirection() -> bool:
	var new_direction: Vector2 = cardinal_direction
	
	if direction == Vector2.ZERO:
		return false
	
	if direction.y == 0: 
		new_direction = Vector2.LEFT if direction.x < 0 else Vector2.RIGHT
	elif direction.x == 0:
		new_direction = Vector2.UP if direction.y < 0 else Vector2.DOWN
		
	if new_direction == cardinal_direction:
		return false
	
	cardinal_direction = new_direction
	sprite.scale.x = -1 if cardinal_direction == Vector2.LEFT else 1
	return true
	


func UpdateAnimation(state: String) -> void:
	animation_player.play(state + "_" + AnimateDirection())
	pass


func AnimateDirection() -> String:
	if cardinal_direction == Vector2.DOWN:
		return 'down'
	elif cardinal_direction == Vector2.UP:
		return 'up'
	else:
		return "side"


# Damage system for player
func take_damage(damage: float, knockback_vector: Vector2) -> void:
	if is_invulnerable:
		return
	
	current_health -= damage
	print("Player took ", damage, " damage! Health: ", current_health, "/", max_health)
	
	# Apply knockback
	velocity += knockback_vector
	
	# Visual feedback
	flash_damage()
	
	# Brief invulnerability to prevent spam damage
	set_invulnerable(1.0)
	
	if current_health <= 0:
		die()

func flash_damage() -> void:
	if sprite:
		sprite.modulate = Color.RED
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.3)

func set_invulnerable(duration: float) -> void:
	is_invulnerable = true
	# Create flashing effect during invulnerability
	var tween = create_tween()
	tween.set_loops(int(duration * 10))  # Flash 10 times per second
	tween.tween_property(sprite, "modulate:a", 0.5, 0.05)
	tween.tween_property(sprite, "modulate:a", 1.0, 0.05)
	
	# End invulnerability
	var timer = get_tree().create_timer(duration)
	timer.timeout.connect(_end_invulnerability)

func _end_invulnerability() -> void:
	is_invulnerable = false
	if sprite:
		sprite.modulate = Color.WHITE

func die() -> void:
	print("Player died! Game Over")
	# For now, just restart the scene
	get_tree().reload_current_scene()

func shoot_projectile(target_position: Vector2) -> void:
	if not projectile_scene:
		print("No projectile scene assigned!")
		return
	
	# Calculate direction from player to target
	var shoot_direction = (target_position - global_position).normalized()
	
	# Spawn position slightly in front of player
	var spawn_position = global_position + shoot_direction * projectile_spawn_offset
	
	# Create and configure projectile
	var projectile = projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)
	projectile.initialize(spawn_position, shoot_direction, 1.0)  # 1 damage
	
	print("Player shoots projectile toward ", target_position)
