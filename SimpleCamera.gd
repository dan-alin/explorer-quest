extends Camera2D

# Simple camera that only follows the player
var player_node = null
var follow_speed = 5.0

# Called when the node enters the scene tree
func _ready():
    # Find player node automatically
    var player = get_node_or_null("../Player")
    if player:
        player_node = player
        print("SimpleCamera: Player found and set")
        # Start at player position
        global_position = player.global_position
    else:
        print("SimpleCamera: Player not found at ../Player")

# Called every frame - ONLY follow the player, no input handling
func _process(delta):
    if player_node:
        var target_pos = player_node.global_position
        global_position = global_position.lerp(target_pos, follow_speed * delta)
