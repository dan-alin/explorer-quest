class_name CharacterStats extends Resource

# Movement stats
@export var movement_range: int = 3  # How many grid cells the character can move per turn
@export var movement_speed: float = 200.0  # Animation speed when moving between cells

# Health stats
@export var max_health: float = 100.0
@export var current_health: float = 100.0

# Constructor to initialize stats
func _init():
	current_health = max_health

# Health management
func take_damage(damage: float) -> float:
	var actual_damage = max(0.0, damage)
	current_health = max(0.0, current_health - actual_damage)
	return actual_damage

func heal(amount: float) -> void:
	current_health = min(max_health, current_health + amount)

func is_alive() -> bool:
	return current_health > 0.0

func get_health_percentage() -> float:
	if max_health <= 0:
		return 0.0
	return current_health / max_health

# Movement helpers
func can_move_to_distance(distance: int) -> bool:
	return distance <= movement_range and distance > 0

func get_movement_range() -> int:
	return movement_range

# Generic character stats creation
static func create_character_stats(move_range: int, move_speed: float, max_hp: float) -> CharacterStats:
	var stats = CharacterStats.new()
	stats.movement_range = move_range
	stats.movement_speed = move_speed
	stats.max_health = max_hp
	stats.current_health = max_hp
	return stats

# Debug info
func get_stats_info() -> String:
	return "Stats - HP: %d/%d, Move Range: %d" % [
		current_health, max_health, movement_range
	]
