extends Camera2D

# Proper camera that handles coordinate transformations correctly
var move_speed = 400.0
var zoom_speed = 0.1
var min_zoom = 0.5
var max_zoom = 3.0
var player_node = null
var follow_speed = 5.0

enum CameraMode {
    FREE,
    FOLLOW_PLAYER
}

var current_mode = CameraMode.FOLLOW_PLAYER

func _ready():
    # Find player automatically
    var player = get_node_or_null("../Player")
    if player:
        player_node = player
        global_position = player.global_position
        print("ProperCamera: Player found and camera positioned")
    
    # Make this camera current (important!)
    make_current()

func _process(delta):
    handle_camera_controls(delta)
    update_camera_mode(delta)

func handle_camera_controls(delta):
    # Only handle input in free mode and when no mouse buttons are pressed
    if current_mode == CameraMode.FREE and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
        var movement = Vector2.ZERO
        
        # Use WASD for camera movement
        if Input.is_action_pressed("left"):
            movement.x -= 1
        if Input.is_action_pressed("right"):
            movement.x += 1
        if Input.is_action_pressed("up"):
            movement.y -= 1
        if Input.is_action_pressed("down"):
            movement.y += 1
        
        if movement.length() > 0:
            global_position += movement.normalized() * move_speed * delta
    
    # Toggle between follow and free mode (use just_pressed to avoid repeated toggling)
    if Input.is_action_just_pressed("toggle_follow"):
        toggle_camera_mode()
    
    # Zoom with mouse wheel
    handle_zoom()

func handle_zoom():
    # Mouse wheel zoom
    if Input.is_action_just_pressed("wheel_up"):
        var new_zoom = zoom * (1.0 + zoom_speed)
        zoom = Vector2(clamp(new_zoom.x, min_zoom, max_zoom), clamp(new_zoom.y, min_zoom, max_zoom))
    
    if Input.is_action_just_pressed("wheel_down"):
        var new_zoom = zoom * (1.0 - zoom_speed)
        zoom = Vector2(clamp(new_zoom.x, min_zoom, max_zoom), clamp(new_zoom.y, min_zoom, max_zoom))

# Handle input events (for touchpad gestures)
func _input(event):
    # Handle touchpad pan gestures for zoom
    if event is InputEventPanGesture:
        var pan_gesture = event as InputEventPanGesture
        # Use the y-component of the pan for zoom (negative = zoom in, positive = zoom out)
        var zoom_factor = 1.0 + (pan_gesture.delta.y * zoom_speed * 0.5)
        var new_zoom = zoom * zoom_factor
        zoom = Vector2(clamp(new_zoom.x, min_zoom, max_zoom), clamp(new_zoom.y, min_zoom, max_zoom))
    
    # Handle magnify gestures (pinch to zoom on touchpad)
    if event is InputEventMagnifyGesture:
        var magnify_gesture = event as InputEventMagnifyGesture
        var zoom_factor = magnify_gesture.factor
        var new_zoom = zoom * zoom_factor
        zoom = Vector2(clamp(new_zoom.x, min_zoom, max_zoom), clamp(new_zoom.y, min_zoom, max_zoom))

func update_camera_mode(delta):
    if current_mode == CameraMode.FOLLOW_PLAYER and player_node:
        var target_pos = player_node.global_position
        global_position = global_position.lerp(target_pos, follow_speed * delta)

func toggle_camera_mode():
    match current_mode:
        CameraMode.FREE:
            current_mode = CameraMode.FOLLOW_PLAYER
            print("Camera: Following player")
        CameraMode.FOLLOW_PLAYER:
            current_mode = CameraMode.FREE
            print("Camera: Free mode")

# Helper function to convert screen coordinates to world coordinates
# This is what your GridOverlay should use instead of get_global_mouse_position()
func screen_to_world(screen_pos: Vector2) -> Vector2:
    return get_global_mouse_position()

# Alternative method for more precise control
func get_world_mouse_position() -> Vector2:
    return get_global_mouse_position()

# Getter for UI to access camera mode
func get_current_mode() -> int:
    return current_mode
