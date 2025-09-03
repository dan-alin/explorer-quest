class_name CharacterStats extends Resource

# Signals for stat changes (Note: Resources can't emit signals directly)
# We'll handle notifications through the player instead

# Movement stats
@export var movement_range: int = 5  # How many grid cells the character can move per turn
@export var movement_speed: float = 200.0  # Animation speed when moving between cells

# Health stats
@export var max_health: float = 100.0
@export var current_health: float = 100.0

# Mana stats
@export var max_mana: float = 50.0
@export var current_mana: float = 50.0

# Constructor to initialize stats
func _init():
	current_health = max_health
	current_mana = max_mana

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

# Mana management
func consume_mana(amount: float) -> bool:
	if amount > current_mana:
		return false
	current_mana = max(0.0, current_mana - amount)
	return true

func restore_mana(amount: float) -> void:
	current_mana = min(max_mana, current_mana + amount)

func get_mana_percentage() -> float:
	if max_mana <= 0:
		return 0.0
	return current_mana / max_mana

func has_mana(amount: float) -> bool:
	return current_mana >= amount

# Movement helpers
func can_move_to_distance(distance: int) -> bool:
	return distance <= movement_range and distance > 0

func get_movement_range() -> int:
	return movement_range

# Generic character stats creation
static func create_character_stats(move_range: int, move_speed: float, max_hp: float, max_mp: float = 50.0) -> CharacterStats:
	var stats = CharacterStats.new()
	stats.movement_range = move_range
	stats.movement_speed = move_speed
	stats.max_health = max_hp
	stats.current_health = max_hp
	stats.max_mana = max_mp
	stats.current_mana = max_mp
	return stats

# Debug info
func get_stats_info() -> String:
	return "Stats - HP: %d/%d, MP: %d/%d, Move Range: %d" % [
		current_health, max_health, current_mana, max_mana, movement_range
	]
