extends TileMapLayer

# Corrected obstacle placement script

func _ready():
    await get_tree().process_frame  # Wait for all nodes to be ready

    var obstacle_manager = get_node("/root/Main/ObstacleManager")
    
    if obstacle_manager:
        obstacle_manager.set_tilemap(self)

        # Reinforce movement range constraints and place obstacles accurately
        obstacle_manager.add_obstacle_at(Vector2i(1, 1))
        obstacle_manager.add_obstacle_at(Vector2i(2, 2))
        obstacle_manager.add_obstacle_at(Vector2i(3, 3))
        obstacle_manager.add_obstacle_at(Vector2i(4, 4))
        obstacle_manager.add_obstacle_at(Vector2i(5, 5))

        obstacle_manager.debug_obstacles()
    else:
        print("Could not find ObstacleManager!")
