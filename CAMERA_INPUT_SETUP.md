# Camera Input Setup Guide

To use the camera controller scripts, you'll need to set up the following input actions in Godot's Input Map (Project > Project Settings > Input Map):

## Required Input Actions

### Basic Movement (Already available in Godot)
- `ui_left` - Move camera left (Arrow Left / A key)
- `ui_right` - Move camera right (Arrow Right / D key)
- `ui_up` - Move camera up (Arrow Up / W key)
- `ui_down` - Move camera down (Arrow Down / S key)

### Custom Camera Actions (You need to add these)
1. **rotate_camera**
   - Key: R
   - Description: Rotate camera 90 degrees clockwise

2. **recenter_camera**
   - Key: C
   - Description: Recenter camera on player

3. **toggle_follow**
   - Key: F
   - Description: Toggle between free camera and follow player mode

## How to Set Up Custom Actions in Godot:

1. Open your project in Godot
2. Go to Project > Project Settings
3. Click on the "Input Map" tab
4. For each custom action:
   - Type the action name in the text field at the top
   - Click "Add"
   - Click the "+" button next to the action
   - Press the key you want to assign
   - Click "OK"

## Camera Features:

### Movement
- Use arrow keys or WASD to move the camera around the map in free mode
- Smooth movement with configurable speed

### Rotation
- Press R to rotate the camera 90 degrees clockwise
- Smooth rotation animation
- Can rotate multiple times to get different perspectives

### Player Following
- Press F to toggle between free camera and player following mode
- In follow mode, camera smoothly follows the player
- Configurable follow speed

### Recentering
- Press C to instantly center the camera on the player
- Also switches to follow mode

### Optional Features
- Map boundaries to prevent camera from going outside the game area
- Zoom in/out functions (can be extended with mouse wheel)
- Automatic player detection

## Using the Camera Scripts:

### Basic Camera (Camera2D.gd)
Simple camera with basic functionality - good for learning or simple projects.

### Advanced Camera (CameraController.gd)
Full-featured camera system with:
- Smooth movement and rotation
- Multiple camera modes
- Boundary constraints
- Automatic player detection
- Extensible design

## Setup in Your Scene:

1. Add a Camera2D node to your scene
2. Attach either Camera2D.gd or CameraController.gd to the Camera2D node
3. Make sure your player node is accessible (the script tries to find "../Player" automatically)
4. Set up the input actions as described above
5. Optionally configure camera boundaries using `set_boundaries(rect)` method

## Customization:

You can adjust these variables in the script:
- `move_speed`: How fast the camera moves
- `follow_speed`: How quickly the camera follows the player
- `rotation_speed`: How fast the camera rotates
- `use_boundaries`: Whether to constrain camera movement to map bounds
