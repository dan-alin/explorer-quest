class_name MovementHighlighter extends Node2D

# Colors for highlighting
@export var highlight_color: Color = Color(0.2, 0.8, 0.2, 0.6)  # Green semi-transparent for reachable cells
@export var highlight_border_color: Color = Color(0.0, 1.0, 0.0, 0.8)  # Green border for reachable cells
@export var obstacle_color: Color = Color(0.8, 0.2, 0.2, 0.6)  # Red semi-transparent for obstacles
@export var obstacle_border_color: Color = Color(1.0, 0.0, 0.0, 0.8)  # Red border for obstacles
@export var highlight_border_width: float = 2.0

# References
var tilemap: TileMapLayer
var highlighted_cells: Array[Vector2i] = []
var obstacle_cells: Array[Vector2i] = []  # Obstacle cells to highlight
var highlight_sprites: Array[Node2D] = []

func _ready():
	# Set z_index to be above tilemap but below player
	z_index = 50

# Set tilemap reference
func set_tilemap(tm: TileMapLayer) -> void:
	tilemap = tm

# Highlight reachable cells from a position
func highlight_reachable_cells(start_position: Vector2i, movement_range: int) -> void:
	# First clear previous highlights
	clear_highlights()
	
	if not tilemap:
		print("MovementHighlighter: No tilemap reference set!")
		return
	
	# Calculate reachable cells
	highlighted_cells = MovementCalculator.get_reachable_cells(tilemap, start_position, movement_range)
	
	# Find obstacles in movement range to highlight in red
	find_obstacles_in_range(start_position, movement_range)
	
	print("Highlighting ", highlighted_cells.size(), " reachable cells and ", obstacle_cells.size(), " obstacles")
	
	# Create highlighting sprites for reachable cells (green)
	for cell_pos in highlighted_cells:
		create_highlight_sprite(cell_pos, false)
	
	# Create highlighting sprites for obstacles (red)
	for cell_pos in obstacle_cells:
		create_highlight_sprite(cell_pos, true)

# Create highlighting sprite for specific cell
func create_highlight_sprite(cell_pos: Vector2i, is_obstacle: bool = false) -> void:
	if not tilemap:
		return
	
	# Check if we're in the scene tree
	if not get_tree():
		print("MovementHighlighter: Not in scene tree yet!")
		return
	
	# Convert grid position to world position
	var cell_center_local = tilemap.map_to_local(cell_pos)
	var cell_center_global = tilemap.to_global(cell_center_local)
	
	# Create node for highlighting
	var highlight_node = Node2D.new()
	highlight_node.position = cell_center_global
	highlight_node.z_index = z_index
	
	# Add node as child of this highlighter instead of to scene
	add_child(highlight_node)
	highlight_sprites.append(highlight_node)
	
	# Connect draw signal with information if it's an obstacle
	highlight_node.draw.connect(_draw_highlight_cell.bind(highlight_node, is_obstacle))
	
	# Force redraw
	highlight_node.queue_redraw()

# Draw cell highlighting
func _draw_highlight_cell(node: Node2D, is_obstacle: bool = false) -> void:
	if not tilemap:
		return
	
	# Get tilemap cell dimensions
	var tile_size = tilemap.tile_set.tile_size
	
	# For isometric tilemaps, create diamond shape
	var half_width = tile_size.x / 2
	var quarter_height = tile_size.y / 4  # Isometric proportions 2:1
	
	# Points for isometric diamond shape
	var points = PackedVector2Array([
		Vector2(0, -quarter_height),     # Top
		Vector2(half_width, 0),          # Right
		Vector2(0, quarter_height),      # Bottom
		Vector2(-half_width, 0)          # Left
	])
	
	# Choose colors based on cell type
	var fill_color = obstacle_color if is_obstacle else highlight_color
	var border_color = obstacle_border_color if is_obstacle else highlight_border_color
	
	# Draw diamond fill
	node.draw_colored_polygon(points, fill_color)
	
	# Draw diamond border
	var closed_points = points
	closed_points.append(points[0])  # Close the polygon
	node.draw_polyline(closed_points, border_color, highlight_border_width)

# Find obstacles in movement range
func find_obstacles_in_range(start_position: Vector2i, movement_range: int) -> void:
	obstacle_cells.clear()
	
	if not tilemap:
		print("MovementHighlighter: No tilemap for obstacle detection")
		return
	
	# Look for ObstacleManager in scene
	var obstacle_manager = MovementCalculator.find_obstacle_manager(tilemap)
	if not obstacle_manager:
		print("MovementHighlighter: No ObstacleManager found")
		return
	
	print("MovementHighlighter: Found ObstacleManager, checking for obstacles...")
	
	# Get all tilemap cells
	var used_cells = tilemap.get_used_cells()
	var total_obstacles = 0
	
	# Check each cell to see if it's an obstacle in range
	for cell in used_cells:
		# Skip if it's the starting position
		if cell == start_position:
			continue
		
		# Check if it's an obstacle
		if obstacle_manager.has_obstacle_at(cell):
			total_obstacles += 1
			# Check if it's in movement range (using Manhattan distance as filter)
			var distance = MovementCalculator.get_manhattan_distance(start_position, cell)
			print("  Found obstacle at ", cell, " distance: ", distance)
			if distance <= movement_range:
				obstacle_cells.append(cell)
				print("    Added to highlight list")
			else:
				print("    Too far (distance ", distance, " > range ", movement_range, ")")
	
	print("MovementHighlighter: Found ", total_obstacles, " total obstacles, ", obstacle_cells.size(), " in range")

# Clear all highlights
func clear_highlights() -> void:
	for sprite in highlight_sprites:
		if is_instance_valid(sprite):
			sprite.queue_free()
	
	highlight_sprites.clear()
	highlighted_cells.clear()
	obstacle_cells.clear()
	print("Cleared movement highlights")

# Check if a cell is currently highlighted
func is_cell_highlighted(cell_pos: Vector2i) -> bool:
	return cell_pos in highlighted_cells

# Get all currently highlighted cells
func get_highlighted_cells() -> Array[Vector2i]:
	return highlighted_cells.duplicate()

# Debug: print info about highlighted cells
func debug_highlighted_cells() -> void:
	print("=== HIGHLIGHTED CELLS DEBUG ===")
	print("Total highlighted cells: ", highlighted_cells.size())
	for cell in highlighted_cells:
		print("  Highlighted cell: ", cell)
	print("===============================")
