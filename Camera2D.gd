extends Camera2D

# Declare variables for movement, rotation, and player reference
var player

# The speed at which the camera moves
var move_speed = 400

# Called every frame, move the camera based on input
func _process(delta):
    # Camera movement
    if Input.is_action_pressed("left"):
        position.x -= move_speed * delta
    if Input.is_action_pressed("right"):
        position.x += move_speed * delta
    if Input.is_action_pressed("up"):
        position.y -= move_speed * delta
    if Input.is_action_pressed("down"):
        position.y += move_speed * delta
    
    # Reset player HP/MP/movement when R key is pressed
    if Input.is_action_just_pressed("rotate_camera"):
        reset_player()
    
    # Recenter camera on player when C key is pressed
    if Input.is_action_just_pressed("recenter_camera"):
        recenter_on_player()

# Reset player HP, MP and movement (R key)
func reset_player():
	if player and player.has_method("full_reset"):
		player.full_reset()

# Recenter camera on player
func recenter_on_player():
    if player:
        global_position = player.global_position

# Example function to set player, called externally
func set_player(p):
    player = p

