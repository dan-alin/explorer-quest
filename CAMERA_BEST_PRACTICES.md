# Camera Best Practices in Godot

## 🎯 The Problem We Encountered

Your game uses **mouse coordinates** to determine tile clicks. When we added Camera2D nodes, they changed how mouse coordinates are interpreted, breaking the player movement system.

## 🔧 Why Cameras Break Coordinate Systems

### Without Camera:
- `get_global_mouse_position()` returns **screen coordinates = world coordinates**
- Mouse click at (100, 100) on screen = world position (100, 100)

### With Camera:
- Camera transforms the view (zoom, pan, rotate)
- `get_global_mouse_position()` now accounts for camera transformation
- Mouse click at (100, 100) on screen ≠ world position (100, 100)

## ✅ Proper Camera Implementation

### 1. **Camera-Aware Coordinate Conversion**

```gdscript
# WRONG - Direct mouse position (what your code was doing)
var mouse_pos = get_global_mouse_position()

# RIGHT - Camera-aware mouse position
var camera = get_viewport().get_camera_2d()
if camera:
    var mouse_pos = camera.get_global_mouse_position()
else:
    var mouse_pos = get_global_mouse_position()  # Fallback
```

### 2. **GridOverlay Camera Integration**

Your GridOverlay needs to be camera-aware:

```gdscript
func update_hover_cell():
    if not tilemap:
        return
    
    # Get camera-aware mouse position
    var mouse_pos: Vector2
    var camera = get_viewport().get_camera_2d()
    if camera:
        mouse_pos = camera.get_global_mouse_position()
    else:
        mouse_pos = get_global_mouse_position()
    
    # Rest of your logic...
```

## 🎮 Camera Implementation Options

### **Option 1: Simple Follow Camera (Recommended)**
```gdscript
extends Camera2D

func _ready():
    var player = get_node("../Player")
    if player:
        global_position = player.global_position

func _process(delta):
    var player = get_node("../Player")
    if player:
        global_position = global_position.lerp(player.global_position, 5.0 * delta)
```

### **Option 2: Free Camera with Proper Coordinate Handling**
- Use different input keys (Arrow keys vs WASD)
- Make GridOverlay camera-aware
- Handle coordinate transformations properly

### **Option 3: No Camera (What You Have Now)**
- Simplest approach
- No coordinate transformation issues
- Player movement works perfectly
- Limited view of the game world

## 🚀 Recommended Approach for Your Game

### **Phase 1: Get Movement Working (✅ Done)**
- No camera for now
- Focus on perfecting the movement system
- Ensure all game mechanics work

### **Phase 2: Add Simple Follow Camera**
```gdscript
# Add this to your scene later
extends Camera2D

var player_node: Player
var follow_speed = 3.0

func _ready():
    player_node = get_node("../Player")
    if player_node:
        global_position = player_node.global_position

func _process(delta):
    if player_node:
        global_position = global_position.lerp(player_node.global_position, follow_speed * delta)
```

### **Phase 3: Make Systems Camera-Aware**
Update GridOverlay to use proper coordinate conversion:
```gdscript
func get_world_mouse_position() -> Vector2:
    var camera = get_viewport().get_camera_2d()
    return camera.get_global_mouse_position() if camera else get_global_mouse_position()
```

## 📝 Key Principles

### **1. Coordinate System Consistency**
- Always use the same coordinate system throughout your game
- If you have a camera, ALL systems must be camera-aware

### **2. Input Separation**
- Camera controls: Arrow keys, F key, Mouse wheel
- Player controls: WASD, Mouse clicks, Space

### **3. Gradual Implementation**
- Start without camera (working state)
- Add simple follow camera
- Add camera controls later
- Make systems camera-aware last

## 🔍 Debugging Camera Issues

### **Check Coordinate Conversion:**
```gdscript
func _input(event):
    if event is InputEventMouseButton and event.pressed:
        var screen_pos = event.position
        var world_pos = get_global_mouse_position()
        print("Screen: ", screen_pos, " World: ", world_pos)
```

### **Verify Camera State:**
```gdscript
func _ready():
    var camera = get_viewport().get_camera_2d()
    if camera:
        print("Camera active: ", camera.name)
        print("Camera position: ", camera.global_position)
        print("Camera zoom: ", camera.zoom)
    else:
        print("No camera active")
```

## 🎯 Next Steps for Your Project

1. **Keep current working state** (no camera)
2. **Perfect your movement system** 
3. **Add simple follow camera** when ready
4. **Gradually add camera features** (zoom, free movement)
5. **Update GridOverlay** to be camera-aware

The key is **incremental implementation** - don't add complex camera systems until your core gameplay is solid!
