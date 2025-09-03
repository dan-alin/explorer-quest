class_name State_Defend extends State

@export var defense_multiplier: float = 0.5  # Reduce incoming damage by 50%
@export var defend_duration: float = 2.0     # How long the defensive stance lasts

@onready var idle: State = $"../Idle"
@onready var walk: State = $"../Walk"
@onready var dash: State = $"../Dash"

var defend_timer: float = 0.0
var is_defending: bool = false

# What happens when the player enters this state?
func Enter() -> void:
	player.UpdateAnimation("idle")  # Use idle animation for now
	defend_timer = defend_duration
	is_defending = true
	
	# Set defense modifier on player
	if player.stats:
		# We'll add a defense modifier to the character stats
		# For now, we'll use a simple flag system
		player.stats.set_defense_mode(true, defense_multiplier)
	
	print("Player assumes defensive stance! Damage reduced by ", (1.0 - defense_multiplier) * 100, "%")

func Exit() -> void:
	# Remove defense modifier
	if player.stats and player.stats.has_method("set_defense_mode"):
		player.stats.set_defense_mode(false, 1.0)
	
	is_defending = false
	print("Player exits defensive stance")

func Process(_delta: float) -> State:
	defend_timer -= _delta
	
	# Allow movement while defending (reduced speed)
	if player.direction != Vector2.ZERO:
		player.velocity = player.direction * 50.0  # Slower movement while defending
		player.SetDirection()
		
		# If moving, transition to walk state but maintain some defense
		if defend_timer > 0:
			# Keep some defense benefit while moving
			return walk
	else:
		player.velocity = Vector2.ZERO
	
	# End defensive stance when timer runs out
	if defend_timer <= 0.0:
		return idle
	
	return null

func Physics(_delta: float) -> State:
	return null

func HandleInput(_event: InputEvent) -> State:
	# Can dash out of defensive stance
	if _event.is_action_pressed("dash") and player.can_dash:
		return dash
		
	# Can exit defensive stance by pressing defend again
	if _event.is_action_pressed("defend"):
		return idle
	
	return null

# Utility function to check if player is currently defending
func is_player_defending() -> bool:
	return is_defending and defend_timer > 0.0

# Get current defense multiplier
func get_defense_multiplier() -> float:
	if is_defending and defend_timer > 0.0:
		return defense_multiplier
	return 1.0
