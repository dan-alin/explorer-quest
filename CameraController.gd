extends Camera2D

# Camera settings
var move_speed = 400.0
var follow_speed = 5.0
var rotation_speed = 180.0  # degrees per second for smooth rotation

# Camera modes
enum CameraMode {
    FREE,
    FOLLOW_PLAYER
}

var current_mode = CameraMode.FOLLOW_PLAYER  # Start in follow mode
var player_node = null
var target_rotation = 0.0

# Camera boundaries (optional)
var use_boundaries = false
var boundary_rect = Rect2()

# Called when the node enters the scene tree
func _ready():
    # Set lower process priority so player input is handled first
    process_priority = -1
    
    # Find player node automatically if it exists
    var player = get_node_or_null("../Player")
    if player:
        set_player(player)
        print("Camera: Player found and set")
    else:
        print("Camera: Player not found at ../Player")

# Called every frame
func _process(delta):
    # Only update camera mode and rotation - NO INPUT HANDLING
    update_camera_mode(delta)
    smooth_rotation(delta)

# Handle all input for camera controls
func handle_input(delta):
    # Only handle camera input if no mouse buttons are pressed (don't interfere with player clicks)
    var mouse_pressed = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
    
    # Camera movement (only in free mode and when mouse isn't being used)
    if current_mode == CameraMode.FREE and not mouse_pressed:
        var movement = Vector2()
        
        if Input.is_action_pressed("left"):
            movement.x -= 1
        if Input.is_action_pressed("right"):
            movement.x += 1
        if Input.is_action_pressed("up"):
            movement.y -= 1
        if Input.is_action_pressed("down"):
            movement.y += 1
        
        # Apply movement
        if movement.length() > 0:
            movement = movement.normalized()
            global_position += movement * move_speed * delta
            
            # Apply boundaries if enabled
            if use_boundaries:
                global_position.x = clamp(global_position.x, boundary_rect.position.x, boundary_rect.end.x)
                global_position.y = clamp(global_position.y, boundary_rect.position.y, boundary_rect.end.y)
    
    # Rotate camera 90 degrees when R key is pressed
    if Input.is_action_just_pressed("rotate_camera"):
        rotate_camera_90()
    
    # Toggle between free and follow mode when F key is pressed
    if Input.is_action_just_pressed("toggle_follow"):
        toggle_camera_mode()
    
    # Recenter camera on player when C key is pressed
    if Input.is_action_just_pressed("recenter_camera"):
        recenter_on_player()

# Update camera based on current mode
func update_camera_mode(delta):
    match current_mode:
        CameraMode.FOLLOW_PLAYER:
            if player_node:
                var target_pos = player_node.global_position
                global_position = global_position.lerp(target_pos, follow_speed * delta)

# Smooth rotation handling
func smooth_rotation(delta):
    if abs(rotation_degrees - target_rotation) > 1.0:
        rotation_degrees = lerp_angle(deg_to_rad(rotation_degrees), deg_to_rad(target_rotation), rotation_speed * delta / 180.0) * 180.0 / PI

# Rotate camera 90 degrees clockwise
func rotate_camera_90():
    target_rotation += 90.0
    if target_rotation >= 360.0:
        target_rotation -= 360.0

# Recenter camera on player
func recenter_on_player():
    if player_node:
        global_position = player_node.global_position
        current_mode = CameraMode.FOLLOW_PLAYER

# Toggle between free camera and follow player mode
func toggle_camera_mode():
    match current_mode:
        CameraMode.FREE:
            current_mode = CameraMode.FOLLOW_PLAYER
            print("Camera: Following player")
        CameraMode.FOLLOW_PLAYER:
            current_mode = CameraMode.FREE
            print("Camera: Free mode")

# Set the player node to follow
func set_player(player):
    player_node = player

# Set camera boundaries for the map
func set_boundaries(rect: Rect2):
    use_boundaries = true
    boundary_rect = rect

# Disable camera boundaries
func remove_boundaries():
    use_boundaries = false

# Reset camera rotation
func reset_rotation():
    target_rotation = 0.0

# Zoom functions
func zoom_in():
    zoom = zoom * Vector2(1.2, 1.2)

func zoom_out():
    zoom = zoom * Vector2(0.8, 0.8)
