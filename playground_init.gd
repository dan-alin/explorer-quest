extends TileMapLayer

# Script to initialize the playground with obstacles for testing

func _ready():
	# Wait a frame to ensure all nodes are ready
	await get_tree().process_frame
	
	# Find the ObstacleManager
	var obstacle_manager = get_node("ObstacleManager")
	if obstacle_manager:
		# Set the tilemap reference
		obstacle_manager.set_tilemap(self)
		
		# Debug: Print some tilemap info
		var used_cells = get_used_cells()
		print("Tilemap has ", used_cells.size(), " cells")
		if used_cells.size() > 0:
			print("First few cells: ", used_cells.slice(0, 5))
			
		# Find player's starting grid position
		var player = get_node("Player")
		if player:
			var player_local_pos = to_local(player.global_position)
			var player_grid_pos = local_to_map(player_local_pos)
			print("Player starts at grid position: ", player_grid_pos)
		
		# Add obstacles close to center, using smaller coordinates
		print("Adding test obstacles...")
		
		# Place obstacles around the center area (adjust based on player position)
		obstacle_manager.add_obstacle_at(Vector2i(6, 3))   # Near center
		obstacle_manager.add_obstacle_at(Vector2i(8, 4))   # Block path
		obstacle_manager.add_obstacle_at(Vector2i(7, 2))   # Force detour
		obstacle_manager.add_obstacle_at(Vector2i(9, 3))   # Another obstacle
		obstacle_manager.add_obstacle_at(Vector2i(5, 5))   # Create barrier
		
		print("Obstacles added! You should see red circles on the map.")
		obstacle_manager.debug_obstacles()
	else:
		print("Warning: ObstacleManager not found!")
