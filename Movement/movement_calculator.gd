class_name MovementCalculator extends RefCounted

# Calculate all reachable cells from a starting position using pathfinding
static func get_reachable_cells(tilemap: TileMapLayer, start_position: Vector2i, movement_range: int) -> Array[Vector2i]:
	if not tilemap or movement_range <= 0:
		return []
	
	var reachable_cells: Array[Vector2i] = []
	var used_cells = tilemap.get_used_cells()  # Only cells with tiles
	
	# Calculate reachable cells
	
	# Use pathfinding to calculate reachable cells considering obstacles
	for cell in used_cells:
		# Skip if it's the starting position or an obstacle
		if cell == start_position or is_obstacle(tilemap, cell):
			continue
		
		# Use pathfinding to verify if the cell is reachable
		var path = find_path_avoiding_obstacles(tilemap, start_position, cell, movement_range)
		if not path.is_empty():
			# The path represents the movement steps needed (doesn't include starting position)
			var actual_distance = path.size()
			if actual_distance <= movement_range:
				reachable_cells.append(cell)
			# Cell is reachable
	return reachable_cells

# Check if a cell is an obstacle
static func is_obstacle(tilemap: TileMapLayer, cell_pos: Vector2i) -> bool:
	if not tilemap:
		return true  # Consider as obstacle if there's no tilemap
	
	# Get cell data
	var tile_data = tilemap.get_cell_tile_data(cell_pos)
	if not tile_data:
		return true  # Cells without tiles are obstacles
	
	# Check if there's a custom "walkable" data set
	if tile_data.get_custom_data("walkable") != null:
		return not tile_data.get_custom_data("walkable")
	
	# Check if there are objects in the ObjectLayer (trees, rocks, buildings, etc.)
	if has_object_at_position(tilemap, cell_pos):
		return true
	
	# Check if there are obstacles placed on this cell (legacy)
	if has_obstacle_at_position(tilemap, cell_pos):
		return true
	
	# By default, all cells with tiles are walkable
	return false

# Calculate Manhattan distance between two cells
static func get_manhattan_distance(from: Vector2i, to: Vector2i) -> int:
	return abs(from.x - to.x) + abs(from.y - to.y)

# Check if a cell is reachable from a position within a certain range
static func is_cell_reachable(tilemap: TileMapLayer, from: Vector2i, to: Vector2i, movement_range: int) -> bool:
	if not tilemap:
		return false
	
	# Quick Manhattan distance check
	var distance = get_manhattan_distance(from, to)
	if distance > movement_range:
		return false
	
	# Check if the destination cell has a tile
	var used_cells = tilemap.get_used_cells()
	if not to in used_cells:
		return false
	
	# For a more accurate check, we could implement pathfinding,
	# but for now we use Manhattan distance as approximation
	return true

# Find a path that avoids obstacles using A* with movement limit
static func find_path_avoiding_obstacles(tilemap: TileMapLayer, start: Vector2i, end: Vector2i, max_movement: int = -1) -> Array[Vector2i]:
	if not tilemap or is_obstacle(tilemap, end):
		return []  # Cannot reach an obstacle
	
	# If movement is limited, check Manhattan distance
	if max_movement > 0 and get_manhattan_distance(start, end) > max_movement:
		return []  # Too far
	
	# Simplified A* pathfinding implementation
	var open_set = [start]
	var came_from = {}
	var g_score = {start: 0}
	var f_score = {start: get_manhattan_distance(start, end)}
	
	while not open_set.is_empty():
		# Find the node with the lowest f_score
		var current = open_set[0]
		for node in open_set:
			if f_score.get(node, INF) < f_score.get(current, INF):
				current = node
		
		if current == end:
			# Reconstruct the path
			return reconstruct_path(came_from, current)
		
		open_set.erase(current)
		
		# Examine neighbors (4 directions)
		var neighbors = [
			current + Vector2i(1, 0),   # Right
			current + Vector2i(-1, 0),  # Left
			current + Vector2i(0, 1),   # Down
			current + Vector2i(0, -1)   # Up
		]
		
		for neighbor in neighbors:
			# Skip if it's an obstacle or out of bounds
			if is_obstacle(tilemap, neighbor):
				continue
			
			var tentative_g_score = g_score.get(current, INF) + 1
			
			# If there's a movement limit, check if this path would exceed it
			if max_movement > 0 and tentative_g_score > max_movement:
				continue  # Path too long, skip this neighbor
			
			if tentative_g_score < g_score.get(neighbor, INF):
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g_score
				f_score[neighbor] = tentative_g_score + get_manhattan_distance(neighbor, end)
				
				if neighbor not in open_set:
					open_set.append(neighbor)
	
	return []  # No path found

# Reconstruct the path from A* algorithm
static func reconstruct_path(came_from: Dictionary, current: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	while current in came_from:
		path.push_front(current)
		current = came_from[current]
	return path

# Check if there's an object (tree, rock, building, etc.) at a grid position
static func has_object_at_position(tilemap: TileMapLayer, cell_pos: Vector2i) -> bool:
	# Find the ObjectLayer in the scene
	var object_layer = find_object_layer(tilemap)
	if object_layer:
		# Check if there's a tile in the ObjectLayer at this position
		var tile_data = object_layer.get_cell_tile_data(cell_pos)
		return tile_data != null
	return false

# Find the ObjectLayer in the scene
static func find_object_layer(tilemap: TileMapLayer) -> TileMapLayer:
	# Structure is: Playground (Node2D) -> TerrainLayer, ObjectLayer
	var playground = tilemap.get_parent()  # Node2D (Playground)
	if playground:
		for child in playground.get_children():
			if child is TileMapLayer and child.name == "ObjectLayer":
				return child
	return null

# Check if there's an obstacle placed at a grid position (legacy)
static func has_obstacle_at_position(tilemap: TileMapLayer, cell_pos: Vector2i) -> bool:
	# Look for an ObstacleManager in the scene to handle obstacles
	var obstacle_manager = find_obstacle_manager(tilemap)
	if obstacle_manager:
		return obstacle_manager.has_obstacle_at(cell_pos)
	return false

# Find the ObstacleManager in the scene
static func find_obstacle_manager(tilemap: TileMapLayer) -> Node:
	# Current structure is: Playground (Node2D) -> TerrainLayer (tilemap) and ObstacleManager
	# The tilemap's parent is directly Playground (Node2D)
	var playground = tilemap.get_parent()  # Node2D (Playground)
	if playground:
		for child in playground.get_children():
			if child.has_method("has_obstacle_at"):
				return child
	
	# If not found, search in scene root as fallback
	var scene_root = tilemap.get_tree().current_scene
	if scene_root:
		for child in scene_root.get_children():
			if child.has_method("has_obstacle_at"):
				return child
	
	return null

# Get all cells in movement range (including obstacles)
static func get_all_cells_in_movement_range(tilemap: TileMapLayer, start_position: Vector2i, movement_range: int) -> Array[Vector2i]:
	if not tilemap or movement_range <= 0:
		return []
	
	var cells_in_range: Array[Vector2i] = []
	var used_cells = tilemap.get_used_cells()  # Only cells with tiles
	
	# Check each cell to see if it's in movement range using Manhattan distance
	for cell in used_cells:
		var distance = get_manhattan_distance(start_position, cell)
		if distance <= movement_range:
			cells_in_range.append(cell)
	
	return cells_in_range

# Debug: print info about reachable cells
static func debug_reachable_cells(tilemap: TileMapLayer, start_position: Vector2i, movement_range: int) -> void:
	var cells = get_reachable_cells(tilemap, start_position, movement_range)
	print("=== REACHABLE CELLS DEBUG ===")
	print("Start position: ", start_position)
	print("Movement range: ", movement_range)
	print("Found ", cells.size(), " reachable cells:")
	for cell in cells:
		var distance = get_manhattan_distance(start_position, cell)
		print("  Cell ", cell, " (distance: ", distance, ")")
	print("===============================")
