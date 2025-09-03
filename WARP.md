# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

**Explorer Quest** is a 2D isometric tile-based RPG game built with **Godot 4.4**. The game features turn-based movement on an isometric grid with pathfinding, obstacle avoidance, player combat states, and camera systems.

## Core Architecture

### Main Scene Structure
- **playground.tscn** - Main game scene with all core components
- **playground_init.gd** - Initializes obstacles and references between components

### Component Architecture
The game uses a modular component-based architecture:

```
Playground (Node2D)
├── TerrainLayer (TileMapLayer) - Isometric ground tiles
├── ObjectLayer (TileMapLayer) - Trees, rocks, buildings  
├── Player (CharacterBody2D) - Main player character
├── Camera2D - Camera system with multiple controller options
├── GridOverlay (Node2D) - Visual grid, movement highlighting, path preview
├── ObstacleManager (Node2D) - Dynamic obstacle management
└── UI (CanvasLayer) - Movement counter and camera controls
```

### Key Systems

#### 1. Turn-Based Movement System
- **MovementCalculator** - A* pathfinding with obstacle avoidance
- **GridOverlay** - Visual feedback for reachable cells and path preview
- **CharacterStats** - Movement range and turn management
- Grid-based movement with Manhattan distance calculations

#### 2. Player State Machine
Located in `Player/Scripts/`:
- **PlayerStateMachine** - Central state controller
- **State** classes: idle, walk, dash, attack, ranged_attack
- Event-driven state transitions

#### 3. Camera System
Multiple camera implementations available:
- **SimpleCamera.gd** - Basic camera following
- **CameraController.gd** - Advanced camera with rotation, boundaries
- **ProperCamera.gd** - Current production camera
- **FreeCamera.gd** - Free movement camera

#### 4. Combat System
- **CharacterStats** - Health, damage, movement stats
- **Projectile** system for ranged attacks
- **AttackArc** for melee combat visualization

## Development Commands

### Running the Game
```bash
# Open project in Godot Editor
godot -e .

# Run the game directly
godot --main-scene playground.tscn
```

### Project Structure Commands
```bash
# Find all game scripts
find . -name "*.gd" -type f

# Find scene files
find . -name "*.tscn" -type f

# Check tilemap resources
find . -name "*.png" -path "*/Sprites/*"
```

### Git Workflow
```bash
# Current development is on feature branches
git checkout main
git pull origin main

# Recent work focuses on multilayer obstacle system
git log --oneline -10
```

## Critical Implementation Details

### Coordinate System Handling
**CRITICAL**: The game uses isometric coordinates with specific camera-aware transformations:

```gdscript
# Always use camera-aware mouse positions
func get_camera_aware_mouse_position() -> Vector2:
    var camera = get_viewport().get_camera_2d()
    if camera:
        return camera.get_global_mouse_position()
    else:
        return get_global_mouse_position()
```

### Grid Position Calculations
- Player position: `current_grid_position` (Vector2i)
- Position offset: `cell_center_global + Vector2(1, -19)` for alignment
- Use `tilemap.local_to_map()` and `tilemap.map_to_local()` for conversions

### Movement Highlighting System
1. **MovementCalculator.get_reachable_cells()** - Calculates valid moves
2. **GridOverlay.highlight_reachable_cells()** - Visual feedback  
3. **Path preview** - Shows route to hovered cell
4. **Obstacle detection** - Red highlighting for blocked cells

### Obstacle Management
- **ObstacleManager** - Dynamic obstacle placement
- **ObjectLayer** - Static objects (trees, buildings)
- **Movement validation** - Pathfinding considers both types

## Input System

### Player Controls
- **WASD** - Player movement (when not using click movement)
- **Left Click** - Move to grid cell
- **Right Click** - Ranged attack
- **Space** - Dash/dodge action

### Camera Controls  
- **Arrow Keys** - Camera movement (free camera mode)
- **R** - Rotate camera 90 degrees
- **C** - Recenter camera on player
- **F** - Toggle follow/free camera mode
- **Mouse Wheel** - Camera zoom (if implemented)

## Development Patterns

### State Management
- Use the **PlayerStateMachine** for player behaviors
- States handle input, processing, and physics separately
- State transitions return new state or null to maintain current

### Resource Management
- **CharacterStats** extends Resource for data persistence
- Use `@export` variables for designer-configurable values
- Initialize references in `_ready()` with `call_deferred()` when needed

### Scene Communication
- Components find each other via parent navigation
- Use typed references: `var grid_overlay: GridOverlay`
- Debug prints for initialization confirmation

### Visual System Patterns
- **z_index** for layering (Player: 100, GridOverlay: 10, etc.)
- Use `queue_redraw()` for custom drawing updates
- Color coding: Blue for valid moves, Red for obstacles, Yellow for hover

## Camera Integration Notes

When adding or modifying camera systems:
1. Update **GridOverlay** to use camera-aware coordinates
2. Ensure all mouse input uses `get_camera_aware_mouse_position()`
3. Test both camera-enabled and camera-disabled modes
4. Verify coordinate transformations work correctly

## Common Development Tasks

### Adding New Player States
1. Create state script in `Player/Scripts/`
2. Extend `State` class 
3. Add as child to `PlayerStateMachine` node
4. Implement `Enter()`, `Exit()`, `Process()`, `Physics()`, `HandleInput()`

### Modifying Movement System
1. Update **MovementCalculator** for pathfinding logic
2. Update **GridOverlay** for visual feedback
3. Test with **ObstacleManager** and **ObjectLayer** obstacles
4. Verify turn-based movement counters update correctly

### Adding New Obstacle Types
1. Add tiles to **ObjectLayer** for static obstacles
2. Use **ObstacleManager** for dynamic/interactive obstacles
3. Update **MovementCalculator.is_obstacle()** if needed
4. Test pathfinding avoidance behavior

This architecture supports incremental development with clear separation between movement, combat, visuals, and input systems.
