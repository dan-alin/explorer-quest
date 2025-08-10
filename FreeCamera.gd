extends Camera2D

# Free camera that uses arrow keys and doesn't interfere with player movement
var camera_speed = 300.0
var zoom_speed = 0.1
var min_zoom = 0.5
var max_zoom = 3.0

func _ready():
    print("FreeCamera: Free camera initialized")

func _process(delta):
    handle_camera_movement(delta)
    handle_camera_zoom()

func handle_camera_movement(delta):
    var movement = Vector2.ZERO
    
    # Use arrow keys for camera movement (different from player WASD)
    if Input.is_key_pressed(KEY_LEFT):
        movement.x -= 1
    if Input.is_key_pressed(KEY_RIGHT):
        movement.x += 1
    if Input.is_key_pressed(KEY_UP):
        movement.y -= 1
    if Input.is_key_pressed(KEY_DOWN):
        movement.y += 1
    
    # Apply movement
    if movement.length() > 0:
        movement = movement.normalized()
        global_position += movement * camera_speed * delta

func handle_camera_zoom():
    # Mouse wheel for zoom
    if Input.is_action_just_pressed("wheel_up"):
        var new_zoom = zoom * (1.0 + zoom_speed)
        zoom = Vector2(clamp(new_zoom.x, min_zoom, max_zoom), clamp(new_zoom.y, min_zoom, max_zoom))
    
    if Input.is_action_just_pressed("wheel_down"):
        var new_zoom = zoom * (1.0 - zoom_speed)
        zoom = Vector2(clamp(new_zoom.x, min_zoom, max_zoom), clamp(new_zoom.y, min_zoom, max_zoom))
