class_name Projectile extends Area2D

@export var speed: float = 400.0
@export var damage: float = 1.0
@export var max_distance: float = 300.0
@export var lifetime: float = 2.0

var direction: Vector2 = Vector2.RIGHT
var traveled_distance: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	# Set up the projectile
	body_entered.connect(_on_body_entered)
	
	# Auto-destroy after lifetime
	var timer = get_tree().create_timer(lifetime)
	timer.timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	# Move the projectile
	var movement = direction * speed * delta
	position += movement
	traveled_distance += movement.length()
	
	# Destroy if traveled too far
	if traveled_distance >= max_distance:
		queue_free()

func initialize(start_position: Vector2, target_direction: Vector2, projectile_damage: float) -> void:
	position = start_position
	direction = target_direction.normalized()
	damage = projectile_damage
	
	# Rotate sprite to face direction of travel
	rotation = direction.angle()

func _on_body_entered(body: Node2D) -> void:
	# Only damage enemies
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		print("Projectile hit enemy: ", body.name)
		
		# Calculate knockback
		var knockback = direction * 150.0
		body.take_damage(damage, knockback)
		
		# Destroy projectile on hit
		queue_free()
	elif body.is_in_group("player"):
		# Don't hit the player who fired it
		return
	else:
		# Hit something else (like walls), destroy projectile
		queue_free()
