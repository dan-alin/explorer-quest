extends Node2D
class_name GridOverlay

# References
@export var tilemap: TileMapLayer
@export var grid_color: Color = Color(1, 0, 0, 0.8)  # Red more visible for debug
@export var grid_width: float = 0  # Thicker to be more visible
@export var hover_color: Color = Color(1, 1, 0, 0.6)  # Yellow for hover
@export var hover_width: float = 3.0  # Thicker to highlight

# Movement highlighting
@export var highlight_color: Color = Color(0.5, 0.8, 1.0, 0.4)  # Sky blue semi-transparent
@export var highlight_border_color: Color = Color(0.2, 0.6, 1.0, 0.8)  # Sky blue border
@export var highlight_border_width: float = 2.0

# Path preview colors
@export var path_preview_color: Color = Color(0.2, 0.4, 0.8, 0.6)  # Dark blue for preview
@export var path_preview_border_color: Color = Color(0.1, 0.3, 0.7, 0.8)  # Dark blue border
@export var path_preview_width: float = 3.0
@export var path_arrow_color: Color = Color(0.3, 0.5, 0.9, 0.9)  # Light dark blue for arrows

# Target position colors
@export var target_color: Color = Color(0.1, 0.3, 0.7, 1.0)  # Dark blue opaque for target (same as border)
@export var target_border_color: Color = Color(0.1, 0.3, 0.7, 1.0)  # Dark blue opaque border for target

# Hover state
var hovered_cell: Vector2i = Vector2i(-999, -999)  # Cell currently under mouse

# Movement highlighting state
var highlighted_cells: Array[Vector2i] = []  # Cells highlighted for movement
var obstacle_cells: Array[Vector2i] = []  # Obstacle cells to highlight

# Obstacle highlighting colors
@export var obstacle_color: Color = Color(0.8, 0.2, 0.2, 0.6)  # Red semi-transparent for obstacles
@export var obstacle_border_color: Color = Color(1.0, 0.0, 0.0, 0.8)  # Red border for obstacles

# Path preview state
var path_preview: Array[Vector2i] = []  # Preview path
var player_reference: Player = null  # Reference to player for path calculation

func _ready():
	print("GridOverlay: _ready() called")
	
	# The GridOverlay is child of Playground (Node2D), we need to find TerrainLayer
	tilemap = get_parent().get_node("TerrainLayer") as TileMapLayer
	if not tilemap:
		print("GridOverlay: TerrainLayer not found! Parent type: ", get_parent().get_class())
		return
	else:
		print("GridOverlay: TerrainLayer found: ", tilemap.name)
	
	# Put the grid under characters but above terrain
	z_index = 10
	
	# Force first draw
	queue_redraw()

func _process(_delta):
	# Update cell under mouse
	update_hover_cell()

func update_hover_cell():
	if not tilemap:
		return
	
	# Get global mouse position (camera-aware)
	var mouse_pos = get_camera_aware_mouse_position()
	
	# Convert to grid coordinates
	var local_mouse_pos = tilemap.to_local(mouse_pos)
	var grid_pos = tilemap.local_to_map(local_mouse_pos)
	
	# Check if cell is valid (contains a tile)
	var tile_data = tilemap.get_cell_tile_data(grid_pos)
	var new_hovered_cell = grid_pos if tile_data != null else Vector2i(-999, -999)
	
	# If hover cell changed, update path preview
	if new_hovered_cell != hovered_cell:
		hovered_cell = new_hovered_cell
		update_path_preview()
		queue_redraw()

func _draw():
	if not tilemap:
		return
	
	# Get tilemap bounds
	var used_cells = tilemap.get_used_cells()
	if used_cells.is_empty():
		return
	
	# Find min/max grid limits
	var min_x = used_cells[0].x
	var max_x = used_cells[0].x
	var min_y = used_cells[0].y  
	var max_y = used_cells[0].y
	
	for cell in used_cells:
		min_x = min(min_x, cell.x)
		max_x = max(max_x, cell.x)
		min_y = min(min_y, cell.y)
		max_y = max(max_y, cell.y)
	
	# Draw the grid
	draw_grid_lines(min_x, max_x, min_y, max_y)
	
	# Draw cells highlighted for movement
	draw_highlighted_cells()
	
	# Draw highlighted obstacles
	draw_obstacle_cells()
	
	# Draw path preview
	draw_path_preview()
	
	# Draw hover if there's a cell under mouse
	draw_hover_cell()

func draw_grid_lines(min_x: int, max_x: int, min_y: int, max_y: int):
	# Draw vertical and horizontal lines for each cell
	for x in range(min_x, max_x + 2):
		for y in range(min_y, max_y + 2):
			var grid_pos = Vector2i(x, y)
			
			# Get cell corner positions in tilemap local coordinates
			var cell_corners = get_cell_corners(grid_pos)
			
			# Convert to global coordinates for this overlay
			var global_corners = []
			for corner in cell_corners:
				var global_corner = tilemap.to_global(corner)
				global_corners.append(to_local(global_corner))
			
			# Draw cell borders (isometric diamond)
			if global_corners.size() == 4:
				# Draw the 4 diamond lines
				draw_line(global_corners[0], global_corners[1], grid_color, grid_width)  # Top -> Right
				draw_line(global_corners[1], global_corners[2], grid_color, grid_width)  # Right -> Bottom  
				draw_line(global_corners[2], global_corners[3], grid_color, grid_width)  # Bottom -> Left
				draw_line(global_corners[3], global_corners[0], grid_color, grid_width)  # Left -> Top

func get_cell_corners(grid_pos: Vector2i) -> Array[Vector2]:
	# For isometric tiles, calculate the 4 diamond corners
	var center = tilemap.map_to_local(grid_pos)
	var tile_size = tilemap.tile_set.tile_size
	
	# Half dimensions for isometric
	var half_width = tile_size.x / 2.0
	var half_height = tile_size.y / 2.0
	
	# The 4 corners of the isometric diamond
	var corners: Array[Vector2] = [
		center + Vector2(0, -half_height),      # Top
		center + Vector2(half_width, 0),        # Right
		center + Vector2(0, half_height),       # Bottom  
		center + Vector2(-half_width, 0)        # Left
	]
	
	return corners

func draw_highlighted_cells():
	# Draw highlighting for reachable cells
	for cell in highlighted_cells:
		var cell_corners = get_cell_corners(cell)
		var local_corners = []
		for corner in cell_corners:
			var global_corner = tilemap.to_global(corner)
			local_corners.append(to_local(global_corner))
		
		# Draw highlighting with green border
		if local_corners.size() == 4:
			draw_polygon(local_corners, [highlight_color])
			draw_line(local_corners[0], local_corners[1], highlight_border_color, highlight_border_width)
			draw_line(local_corners[1], local_corners[2], highlight_border_color, highlight_border_width)
			draw_line(local_corners[2], local_corners[3], highlight_border_color, highlight_border_width)
			draw_line(local_corners[3], local_corners[0], highlight_border_color, highlight_border_width)

func draw_hover_cell():
	# Draw highlighting for cell under mouse
	if hovered_cell == Vector2i(-999, -999):
		return  # No cell under mouse
	
	# Get corners of hovered cell
	var cell_corners = get_cell_corners(hovered_cell)
	
	# Convert to local coordinates for this overlay
	var local_corners = []
	for corner in cell_corners:
		var global_corner = tilemap.to_global(corner)
		local_corners.append(to_local(global_corner))
	
	# Check if cell is reachable (valid target)
	var is_valid_target = is_cell_highlighted(hovered_cell)
	
	if local_corners.size() == 4:
		if is_valid_target:
			# Draw valid target with opaque dark blue
			draw_polygon(local_corners, [target_color])
			draw_line(local_corners[0], local_corners[1], target_border_color, highlight_border_width)
			draw_line(local_corners[1], local_corners[2], target_border_color, highlight_border_width)
			draw_line(local_corners[2], local_corners[3], target_border_color, highlight_border_width)
			draw_line(local_corners[3], local_corners[0], target_border_color, highlight_border_width)
		else:
			# Draw normal hover (yellow diamond for invalid targets)
			draw_line(local_corners[0], local_corners[1], hover_color, hover_width)  # Top -> Right
			draw_line(local_corners[1], local_corners[2], hover_color, hover_width)  # Right -> Bottom  
			draw_line(local_corners[2], local_corners[3], hover_color, hover_width)  # Bottom -> Left
			draw_line(local_corners[3], local_corners[0], hover_color, hover_width)  # Left -> Top
func update_path_preview():
	if not player_reference or hovered_cell == Vector2i(-999, -999):
		path_preview.clear()
		return
	
	# Only calculate path if cell is reachable
	if not is_cell_highlighted(hovered_cell):
		path_preview.clear()
		return
	
	var start_position = player_reference.current_grid_position
	path_preview = calculate_path(start_position, hovered_cell)

func calculate_path(start: Vector2i, end: Vector2i) -> Array[Vector2i]:
	# Get movement limit from player
	var movement_limit = -1
	if player_reference:
		movement_limit = player_reference.get_remaining_movement()
	
	# Use A* pathfinding to avoid obstacles with movement limit
	var path = MovementCalculator.find_path_avoiding_obstacles(tilemap, start, end, movement_limit)
	
	# If A* doesn't find a path, try linear path as fallback
	if path.is_empty():
		path = calculate_linear_path(start, end)
	
	return path

func calculate_linear_path(start: Vector2i, end: Vector2i) -> Array[Vector2i]:
	# Calculate linear path (Manhattan path) from start to end as fallback
	var path: Array[Vector2i] = []
	var current = start
	
	# First move horizontally
	while current.x != end.x:
		if end.x > current.x:
			current.x += 1
		else:
			current.x -= 1
		# Check if it's not an obstacle before adding
		if not MovementCalculator.is_obstacle(tilemap, Vector2i(current.x, current.y)):
			path.append(Vector2i(current.x, current.y))
	
	# Then move vertically
	while current.y != end.y:
		if end.y > current.y:
			current.y += 1
		else:
			current.y -= 1
		# Check if it's not an obstacle before adding
		if not MovementCalculator.is_obstacle(tilemap, Vector2i(current.x, current.y)):
			path.append(Vector2i(current.x, current.y))
	
	return path

# Draw path preview
func draw_path_preview():
	for cell in path_preview:
		var cell_corners = get_cell_corners(cell)
		var local_corners = []
		for corner in cell_corners:
			var global_corner = tilemap.to_global(corner)
			local_corners.append(to_local(global_corner))
		if local_corners.size() == 4:
			draw_polygon(local_corners, [path_preview_color])
			draw_line(local_corners[0], local_corners[1], path_preview_border_color, path_preview_width)
			draw_line(local_corners[1], local_corners[2], path_preview_border_color, path_preview_width)
			draw_line(local_corners[2], local_corners[3], path_preview_border_color, path_preview_width)
			draw_line(local_corners[3], local_corners[0], path_preview_border_color, path_preview_width)


# Path preview functions
func set_player_reference(player: Player) -> void:
	# Set player reference for path calculations
	player_reference = player
	print("GridOverlay: Player reference set")

# Movement highlighting functions
func highlight_reachable_cells(start_position: Vector2i, movement_range: int) -> void:
	# Calculate reachable cells
	highlighted_cells = MovementCalculator.get_reachable_cells(tilemap, start_position, movement_range)
	
	# Find obstacles in movement range to highlight in red
	find_obstacles_in_range(start_position, movement_range)
	
	print("GridOverlay: Highlighting ", highlighted_cells.size(), " reachable cells and ", obstacle_cells.size(), " obstacles")
	# Redraw to show new highlights
	queue_redraw()

# Draw highlighted obstacles
func draw_obstacle_cells():
	# Draw obstacle highlighting in red
	for cell in obstacle_cells:
		var cell_corners = get_cell_corners(cell)
		var local_corners = []
		for corner in cell_corners:
			var global_corner = tilemap.to_global(corner)
			local_corners.append(to_local(global_corner))
		
		# Draw highlighting with red border
		if local_corners.size() == 4:
			draw_polygon(local_corners, [obstacle_color])
			draw_line(local_corners[0], local_corners[1], obstacle_border_color, highlight_border_width)
			draw_line(local_corners[1], local_corners[2], obstacle_border_color, highlight_border_width)
			draw_line(local_corners[2], local_corners[3], obstacle_border_color, highlight_border_width)
			draw_line(local_corners[3], local_corners[0], obstacle_border_color, highlight_border_width)

# Find obstacles in movement range
func find_obstacles_in_range(start_position: Vector2i, movement_range: int) -> void:
	obstacle_cells.clear()
	
	if not tilemap:
		print("GridOverlay: No tilemap for obstacle detection")
		return
	
	# Look for ObstacleManager in scene
	print("GridOverlay: Looking for ObstacleManager...")
	print("GridOverlay: tilemap parent is: ", tilemap.get_parent().get_class())
	var obstacle_manager = MovementCalculator.find_obstacle_manager(tilemap)
	if not obstacle_manager:
		print("GridOverlay: No ObstacleManager found")
		# Debug: search manually
		var playground = tilemap.get_parent()
		print("GridOverlay: Playground children count: ", playground.get_child_count())
		for child in playground.get_children():
			print("  Child: ", child.name, " (class: ", child.get_class(), ")")
			if child.has_method("has_obstacle_at"):
				print("    Found node with has_obstacle_at method!")
		return
	
	print("GridOverlay: Found ObstacleManager: ", obstacle_manager.name, " (class: ", obstacle_manager.get_class(), ")")
	
	# Debug: test if specific obstacles exist
	print("GridOverlay: Testing specific obstacle positions...")
	var test_positions = [Vector2i(6, 3), Vector2i(8, 4), Vector2i(7, 2), Vector2i(9, 3), Vector2i(5, 5)]
	for pos in test_positions:
		var has_obstacle = obstacle_manager.has_obstacle_at(pos)
		print("  Position ", pos, ": has_obstacle = ", has_obstacle)
	
	# Get all tilemap cells
	var used_cells = tilemap.get_used_cells()
	var total_obstacles = 0
	
	# For each cell, check if it's an obstacle AND would be reachable without obstacles
	for cell in used_cells:
		# Skip if it's the starting position
		if cell == start_position:
			continue
		
		# Check if it's an obstacle
		if obstacle_manager.has_obstacle_at(cell):
			# Now check if this cell would be reachable if it weren't an obstacle
			# Use pathfinding IGNORING obstacles to see if it would be reachable
			var path_ignoring_obstacles = find_path_ignoring_obstacles(start_position, cell, movement_range)
			if not path_ignoring_obstacles.is_empty() and path_ignoring_obstacles.size() <= movement_range:
				total_obstacles += 1
				obstacle_cells.append(cell)
				print("  Found relevant obstacle at ", cell, " (would be reachable in ", path_ignoring_obstacles.size(), " steps)")
			else:
				print("  Ignoring distant obstacle at ", cell, " (too far to be relevant)")
	
	print("GridOverlay: Found ", total_obstacles, " relevant obstacles within movement range")

func clear_highlights() -> void:
	# Clear all highlights
	highlighted_cells.clear()
	obstacle_cells.clear()
	print("GridOverlay: Cleared movement highlights")
	# Redraw to remove highlights
	queue_redraw()

func is_cell_highlighted(cell_pos: Vector2i) -> bool:
	# Check if a cell is currently highlighted
	return cell_pos in highlighted_cells

func get_highlighted_cells() -> Array[Vector2i]:
	# Get all currently highlighted cells
	return highlighted_cells.duplicate()

# Clear path preview
func clear_path_preview() -> void:
	path_preview.clear()
	queue_redraw()
	
# Helper function to find path ignoring obstacles (for obstacle highlighting)
func find_path_ignoring_obstacles(start: Vector2i, target: Vector2i, max_distance: int) -> Array[Vector2i]:
	# Calculate simple path ignoring obstacles to determine if
	# an obstacle is "relevant" (i.e. along a path the player might want to follow)
	
	# Use Manhattan distance as approximation
	var manhattan_distance = abs(target.x - start.x) + abs(target.y - start.y)
	if manhattan_distance > max_distance:
		return []  # Too far even without obstacles
	
	# Create simple linear path (Manhattan path)
	var path: Array[Vector2i] = []
	var current = start
	
	# First move horizontally
	while current.x != target.x:
		if target.x > current.x:
			current.x += 1
		else:
			current.x -= 1
		path.append(Vector2i(current.x, current.y))
	
	# Then move vertically  
	while current.y != target.y:
		if target.y > current.y:
			current.y += 1
		else:
			current.y -= 1
		path.append(Vector2i(current.x, current.y))
	
	return path

# Force redraw when needed
func refresh_grid():
	queue_redraw()

# Camera-aware mouse position function (CRITICAL for camera compatibility)
func get_camera_aware_mouse_position() -> Vector2:
	# Get the current camera
	var camera = get_viewport().get_camera_2d()
	if camera:
		# Camera is active - use camera-aware mouse position
		return camera.get_global_mouse_position()
	else:
		# No camera - use regular mouse position
		return get_global_mouse_position()
