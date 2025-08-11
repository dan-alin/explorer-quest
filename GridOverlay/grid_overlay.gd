extends Node2D
class_name GridOverlay

# References
@export var tilemap: TileMapLayer
@export var grid_color: Color = Color(1, 0, 0, 0.8)  # Rosso più visibile per debug
@export var grid_width: float = 0  # Più spesso per essere più visibile
@export var hover_color: Color = Color(1, 1, 0, 0.6)  # Giallo per hover
@export var hover_width: float = 3.0  # Più spesso per evidenziare

# Movement highlighting
@export var highlight_color: Color = Color(0.5, 0.8, 1.0, 0.4)  # Sky blue semi-trasparente
@export var highlight_border_color: Color = Color(0.2, 0.6, 1.0, 0.8)  # Sky blue bordo
@export var highlight_border_width: float = 2.0

# Path preview colors
@export var path_preview_color: Color = Color(0.2, 0.4, 0.8, 0.6)  # Dark blue per preview
@export var path_preview_border_color: Color = Color(0.1, 0.3, 0.7, 0.8)  # Dark blue bordo
@export var path_preview_width: float = 3.0
@export var path_arrow_color: Color = Color(0.3, 0.5, 0.9, 0.9)  # Dark blue chiaro per frecce

# Target position colors
@export var target_color: Color = Color(0.1, 0.3, 0.7, 1.0)  # Dark blue opaco per target (same as border)
@export var target_border_color: Color = Color(0.1, 0.3, 0.7, 1.0)  # Dark blue opaco bordo per target

# Hover state
var hovered_cell: Vector2i = Vector2i(-999, -999)  # Cella attualmente sotto il mouse

# Movement highlighting state
var highlighted_cells: Array[Vector2i] = []  # Celle evidenziate per movimento
var obstacle_cells: Array[Vector2i] = []  # Celle ostacolo da evidenziare

# Obstacle highlighting colors
@export var obstacle_color: Color = Color(0.8, 0.2, 0.2, 0.6)  # Rosso semi-trasparente per ostacoli
@export var obstacle_border_color: Color = Color(1.0, 0.0, 0.0, 0.8)  # Rosso bordo per ostacoli

# Path preview state
var path_preview: Array[Vector2i] = []  # Percorso di anteprima
var player_reference: Player = null  # Riferimento al player per calcolare il percorso

func _ready():
	print("GridOverlay: _ready() called")
	
	# Il GridOverlay è figlio di Playground (Node2D), dobbiamo trovare TerrainLayer
	tilemap = get_parent().get_node("TerrainLayer") as TileMapLayer
	if not tilemap:
		print("GridOverlay: TerrainLayer not found! Parent type: ", get_parent().get_class())
		return
	else:
		print("GridOverlay: TerrainLayer found: ", tilemap.name)
	
	# Metti la griglia sotto i personaggi ma sopra il terreno
	z_index = 10
	
	# Forza il primo disegno
	queue_redraw()

func _process(_delta):
	# Aggiorna la cella sotto il mouse
	update_hover_cell()

func update_hover_cell():
	if not tilemap:
		return
	
	# Ottieni posizione mouse globale (camera-aware)
	var mouse_pos = get_camera_aware_mouse_position()
	
	# Converti in coordinate griglia
	var local_mouse_pos = tilemap.to_local(mouse_pos)
	var grid_pos = tilemap.local_to_map(local_mouse_pos)
	
	# Controlla se la cella è valida (contiene una tile)
	var tile_data = tilemap.get_cell_tile_data(grid_pos)
	var new_hovered_cell = grid_pos if tile_data != null else Vector2i(-999, -999)
	
	# Se la cella hover è cambiata, aggiorna il preview del percorso
	if new_hovered_cell != hovered_cell:
		hovered_cell = new_hovered_cell
		update_path_preview()
		queue_redraw()

func _draw():
	if not tilemap:
		return
	
	# Ottieni i bounds della tilemap
	var used_cells = tilemap.get_used_cells()
	if used_cells.is_empty():
		return
	
	# Trova i limiti min/max della griglia
	var min_x = used_cells[0].x
	var max_x = used_cells[0].x
	var min_y = used_cells[0].y  
	var max_y = used_cells[0].y
	
	for cell in used_cells:
		min_x = min(min_x, cell.x)
		max_x = max(max_x, cell.x)
		min_y = min(min_y, cell.y)
		max_y = max(max_y, cell.y)
	
	# Disegna la griglia
	draw_grid_lines(min_x, max_x, min_y, max_y)
	
	# Disegna le celle evidenziate per movimento
	draw_highlighted_cells()
	
	# Disegna gli ostacoli evidenziati
	draw_obstacle_cells()
	
	# Disegna il preview del percorso
	draw_path_preview()
	
	# Disegna l'hover se c'è una cella sotto il mouse
	draw_hover_cell()

func draw_grid_lines(min_x: int, max_x: int, min_y: int, max_y: int):
	# Disegna le linee verticali e orizzontali per ogni cella
	for x in range(min_x, max_x + 2):
		for y in range(min_y, max_y + 2):
			var grid_pos = Vector2i(x, y)
			
			# Ottieni le posizioni degli angoli della cella in coordinate locali della tilemap
			var cell_corners = get_cell_corners(grid_pos)
			
			# Converti in coordinate globali per questo overlay
			var global_corners = []
			for corner in cell_corners:
				var global_corner = tilemap.to_global(corner)
				global_corners.append(to_local(global_corner))
			
			# Disegna i bordi della cella (diamante isometrico)
			if global_corners.size() == 4:
				# Disegna le 4 linee del diamante
				draw_line(global_corners[0], global_corners[1], grid_color, grid_width)  # Top -> Right
				draw_line(global_corners[1], global_corners[2], grid_color, grid_width)  # Right -> Bottom  
				draw_line(global_corners[2], global_corners[3], grid_color, grid_width)  # Bottom -> Left
				draw_line(global_corners[3], global_corners[0], grid_color, grid_width)  # Left -> Top

func get_cell_corners(grid_pos: Vector2i) -> Array[Vector2]:
	# Per le tile isometriche, calcoliamo i 4 angoli del diamante
	var center = tilemap.map_to_local(grid_pos)
	var tile_size = tilemap.tile_set.tile_size
	
	# Half dimensions per isometrico
	var half_width = tile_size.x / 2.0
	var half_height = tile_size.y / 2.0
	
	# I 4 angoli del diamante isometrico
	var corners: Array[Vector2] = [
		center + Vector2(0, -half_height),      # Top
		center + Vector2(half_width, 0),        # Right
		center + Vector2(0, half_height),       # Bottom  
		center + Vector2(-half_width, 0)        # Left
	]
	
	return corners

func draw_highlighted_cells():
	# Disegna l'evidenziazione delle celle raggiungibili
	for cell in highlighted_cells:
		var cell_corners = get_cell_corners(cell)
		var local_corners = []
		for corner in cell_corners:
			var global_corner = tilemap.to_global(corner)
			local_corners.append(to_local(global_corner))
		
		# Disegna l'evidenziazione con un bordo verde
		if local_corners.size() == 4:
			draw_polygon(local_corners, [highlight_color])
			draw_line(local_corners[0], local_corners[1], highlight_border_color, highlight_border_width)
			draw_line(local_corners[1], local_corners[2], highlight_border_color, highlight_border_width)
			draw_line(local_corners[2], local_corners[3], highlight_border_color, highlight_border_width)
			draw_line(local_corners[3], local_corners[0], highlight_border_color, highlight_border_width)

func draw_hover_cell():
	# Disegna l'evidenziazione della cella sotto il mouse
	if hovered_cell == Vector2i(-999, -999):
		return  # Nessuna cella sotto il mouse
	
	# Ottieni gli angoli della cella in hover
	var cell_corners = get_cell_corners(hovered_cell)
	
	# Converti in coordinate locali per questo overlay
	var local_corners = []
	for corner in cell_corners:
		var global_corner = tilemap.to_global(corner)
		local_corners.append(to_local(global_corner))
	
	# Controlla se la cella è raggiungibile (target valido)
	var is_valid_target = is_cell_highlighted(hovered_cell)
	
	if local_corners.size() == 4:
		if is_valid_target:
			# Disegna il target valido con dark blue opaco
			draw_polygon(local_corners, [target_color])
			draw_line(local_corners[0], local_corners[1], target_border_color, highlight_border_width)
			draw_line(local_corners[1], local_corners[2], target_border_color, highlight_border_width)
			draw_line(local_corners[2], local_corners[3], target_border_color, highlight_border_width)
			draw_line(local_corners[3], local_corners[0], target_border_color, highlight_border_width)
		else:
			# Disegna l'hover normale (diamante giallo per target non validi)
			draw_line(local_corners[0], local_corners[1], hover_color, hover_width)  # Top -> Right
			draw_line(local_corners[1], local_corners[2], hover_color, hover_width)  # Right -> Bottom  
			draw_line(local_corners[2], local_corners[3], hover_color, hover_width)  # Bottom -> Left
			draw_line(local_corners[3], local_corners[0], hover_color, hover_width)  # Left -> Top
func update_path_preview():
	if not player_reference or hovered_cell == Vector2i(-999, -999):
		path_preview.clear()
		return
	
	# Solo calcola il percorso se la cella è raggiungibile
	if not is_cell_highlighted(hovered_cell):
		path_preview.clear()
		return
	
	var start_position = player_reference.current_grid_position
	path_preview = calculate_path(start_position, hovered_cell)

func calculate_path(start: Vector2i, end: Vector2i) -> Array[Vector2i]:
	# Ottieni il limite di movimento dal player
	var movement_limit = -1
	if player_reference:
		movement_limit = player_reference.get_remaining_movement()
	
	# Usa A* pathfinding per evitare ostacoli con limite di movimento
	var path = MovementCalculator.find_path_avoiding_obstacles(tilemap, start, end, movement_limit)
	
	# Se A* non trova un percorso, prova il percorso lineare come fallback
	if path.is_empty():
		path = calculate_linear_path(start, end)
	
	return path

func calculate_linear_path(start: Vector2i, end: Vector2i) -> Array[Vector2i]:
	# Calcola un percorso lineare (Manhattan path) da start a end come fallback
	var path: Array[Vector2i] = []
	var current = start
	
	# First move horizontally
	while current.x != end.x:
		if end.x > current.x:
			current.x += 1
		else:
			current.x -= 1
		# Controlla se non è un ostacolo prima di aggiungere
		if not MovementCalculator.is_obstacle(tilemap, Vector2i(current.x, current.y)):
			path.append(Vector2i(current.x, current.y))
	
	# Then move vertically
	while current.y != end.y:
		if end.y > current.y:
			current.y += 1
		else:
			current.y -= 1
		# Controlla se non è un ostacolo prima di aggiungere
		if not MovementCalculator.is_obstacle(tilemap, Vector2i(current.x, current.y)):
			path.append(Vector2i(current.x, current.y))
	
	return path

# Disegna il percorso di anteprima
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
	# Imposta il riferimento al player per calcolare i percorsi
	player_reference = player
	print("GridOverlay: Player reference set")

# Movement highlighting functions
func highlight_reachable_cells(start_position: Vector2i, movement_range: int) -> void:
	# Calcola le celle raggiungibili
	highlighted_cells = MovementCalculator.get_reachable_cells(tilemap, start_position, movement_range)
	
	# Trova gli ostacoli nel range di movimento per evidenziarli in rosso
	find_obstacles_in_range(start_position, movement_range)
	
	print("GridOverlay: Highlighting ", highlighted_cells.size(), " reachable cells and ", obstacle_cells.size(), " obstacles")
	# Ridisegna per mostrare le nuove evidenziazioni
	queue_redraw()

# Disegna gli ostacoli evidenziati
func draw_obstacle_cells():
	# Disegna l'evidenziazione degli ostacoli in rosso
	for cell in obstacle_cells:
		var cell_corners = get_cell_corners(cell)
		var local_corners = []
		for corner in cell_corners:
			var global_corner = tilemap.to_global(corner)
			local_corners.append(to_local(global_corner))
		
		# Disegna l'evidenziazione con un bordo rosso
		if local_corners.size() == 4:
			draw_polygon(local_corners, [obstacle_color])
			draw_line(local_corners[0], local_corners[1], obstacle_border_color, highlight_border_width)
			draw_line(local_corners[1], local_corners[2], obstacle_border_color, highlight_border_width)
			draw_line(local_corners[2], local_corners[3], obstacle_border_color, highlight_border_width)
			draw_line(local_corners[3], local_corners[0], obstacle_border_color, highlight_border_width)

# Trova gli ostacoli nel range di movimento
func find_obstacles_in_range(start_position: Vector2i, movement_range: int) -> void:
	obstacle_cells.clear()
	
	if not tilemap:
		print("GridOverlay: No tilemap for obstacle detection")
		return
	
	# Cerca l'ObstacleManager nella scena
	print("GridOverlay: Looking for ObstacleManager...")
	print("GridOverlay: tilemap parent is: ", tilemap.get_parent().get_class())
	var obstacle_manager = MovementCalculator.find_obstacle_manager(tilemap)
	if not obstacle_manager:
		print("GridOverlay: No ObstacleManager found")
		# Debug: cerca manualmente
		var playground = tilemap.get_parent()
		print("GridOverlay: Playground children count: ", playground.get_child_count())
		for child in playground.get_children():
			print("  Child: ", child.name, " (class: ", child.get_class(), ")")
			if child.has_method("has_obstacle_at"):
				print("    Found node with has_obstacle_at method!")
		return
	
	print("GridOverlay: Found ObstacleManager: ", obstacle_manager.name, " (class: ", obstacle_manager.get_class(), ")")
	
	# Debug: testa se specifici ostacoli esistono
	print("GridOverlay: Testing specific obstacle positions...")
	var test_positions = [Vector2i(6, 3), Vector2i(8, 4), Vector2i(7, 2), Vector2i(9, 3), Vector2i(5, 5)]
	for pos in test_positions:
		var has_obstacle = obstacle_manager.has_obstacle_at(pos)
		print("  Position ", pos, ": has_obstacle = ", has_obstacle)
	
	# Ottieni tutte le celle della tilemap
	var used_cells = tilemap.get_used_cells()
	var total_obstacles = 0
	
	# Per ogni cella, controlla se è un ostacolo E se sarebbe raggiungibile senza ostacoli
	for cell in used_cells:
		# Salta se è la posizione di partenza
		if cell == start_position:
			continue
		
		# Controlla se è un ostacolo
		if obstacle_manager.has_obstacle_at(cell):
			# Ora controlla se questa cella sarebbe raggiungibile se non fosse un ostacolo
			# Usa pathfinding IGNORANDO gli ostacoli per vedere se sarebbe raggiungibile
			var path_ignoring_obstacles = find_path_ignoring_obstacles(start_position, cell, movement_range)
			if not path_ignoring_obstacles.is_empty() and path_ignoring_obstacles.size() <= movement_range:
				total_obstacles += 1
				obstacle_cells.append(cell)
				print("  Found relevant obstacle at ", cell, " (would be reachable in ", path_ignoring_obstacles.size(), " steps)")
			else:
				print("  Ignoring distant obstacle at ", cell, " (too far to be relevant)")
	
	print("GridOverlay: Found ", total_obstacles, " relevant obstacles within movement range")

func clear_highlights() -> void:
	# Pulisce tutte le evidenziazioni
	highlighted_cells.clear()
	obstacle_cells.clear()
	print("GridOverlay: Cleared movement highlights")
	# Ridisegna per rimuovere le evidenziazioni
	queue_redraw()

func is_cell_highlighted(cell_pos: Vector2i) -> bool:
	# Controlla se una cella è attualmente evidenziata
	return cell_pos in highlighted_cells

func get_highlighted_cells() -> Array[Vector2i]:
	# Ottieni tutte le celle attualmente evidenziate
	return highlighted_cells.duplicate()

# Pulisce il path preview
func clear_path_preview() -> void:
	path_preview.clear()
	queue_redraw()
	
# Helper function to find path ignoring obstacles (for obstacle highlighting)
func find_path_ignoring_obstacles(start: Vector2i, target: Vector2i, max_distance: int) -> Array[Vector2i]:
	# Calcola un percorso semplice ignorando gli ostacoli per determinare se
	# un ostacolo è "rilevante" (cioè lungo un percorso che il giocatore potrebbe voler seguire)
	
	# Usa la distanza Manhattan come approssimazione
	var manhattan_distance = abs(target.x - start.x) + abs(target.y - start.y)
	if manhattan_distance > max_distance:
		return []  # Troppo lontano anche senza ostacoli
	
	# Crea un percorso lineare semplice (Manhattan path)
	var path: Array[Vector2i] = []
	var current = start
	
	# Prima muoviti orizzontalmente
	while current.x != target.x:
		if target.x > current.x:
			current.x += 1
		else:
			current.x -= 1
		path.append(Vector2i(current.x, current.y))
	
	# Poi muoviti verticalmente  
	while current.y != target.y:
		if target.y > current.y:
			current.y += 1
		else:
			current.y -= 1
		path.append(Vector2i(current.x, current.y))
	
	return path

# Forza il ridisegno quando necessario
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
