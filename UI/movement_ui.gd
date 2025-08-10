extends CanvasLayer
class_name MovementUI

@onready var movement_counter: Label = $MovementCounter
var player_reference: Player = null

func _ready():
	print("MovementUI: Ready")

func set_player_reference(player: Player) -> void:
	player_reference = player
	print("MovementUI: Player reference set")
	# Update the counter initially
	update_movement_counter()

func update_movement_counter() -> void:
	if not player_reference or not movement_counter:
		return
	
	var remaining = player_reference.get_remaining_movement()
	var total = player_reference.get_movement_range()
	
	movement_counter.text = "%d/%d" % [remaining, total]
	print("MovementUI: Updated counter to ", movement_counter.text)

# Called when movement is consumed or turn starts
func on_movement_changed() -> void:
	update_movement_counter()
