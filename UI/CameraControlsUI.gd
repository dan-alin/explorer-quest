extends Control

# Camera controls UI panel
@onready var camera_mode_label: Label = $PanelContainer/VBoxContainer/CameraModeLabel
@onready var controls_label: Label = $PanelContainer/VBoxContainer/ControlsLabel

var camera: Camera2D

func _ready():
    # Find the camera
    camera = get_viewport().get_camera_2d()
    
    # Update initial state
    update_camera_mode_display()
    
    # Set up the controls text
    setup_controls_text()

func _process(_delta):
    # Update camera mode display
    update_camera_mode_display()

func update_camera_mode_display():
    if camera and camera.has_method("get_current_mode"):
        var mode = camera.get_current_mode()
        if mode == 0:  # CameraMode.FREE
            camera_mode_label.text = "🎮 FREE"
            camera_mode_label.modulate = Color.YELLOW
        else:  # CameraMode.FOLLOW_PLAYER
            camera_mode_label.text = "👤 FOLLOW"
            camera_mode_label.modulate = Color.CYAN
    else:
        camera_mode_label.text = "📷 NO CAMERA"
        camera_mode_label.modulate = Color.WHITE

func setup_controls_text():
    var controls_text = """F - Toggle Mode
WASD - Move (Free)
Wheel/Pad - Zoom"""
    
    controls_label.text = controls_text
