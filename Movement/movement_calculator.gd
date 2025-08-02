class_name MovementCalculator extends RefCounted

# Calcola tutte le celle raggiungibili da una posizione di partenza usando pathfinding
static func get_reachable_cells(tilemap: TileMapLayer, start_position: Vector2i, movement_range: int) -> Array[Vector2i]:
	if not tilemap or movement_range <= 0:
		return []
	
	var reachable_cells: Array[Vector2i] = []
	var used_cells = tilemap.get_used_cells()  # Solo celle con tiles
	
	print("=== CALCULATING REACHABLE CELLS ===")
	print("Start position: ", start_position)
	print("Movement range: ", movement_range)
	print("Total cells in tilemap: ", used_cells.size())
	
	# Usa pathfinding per calcolare le celle raggiungibili considerando gli ostacoli
	for cell in used_cells:
		# Salta se è la posizione di partenza o è un ostacolo
		if cell == start_position or is_obstacle(tilemap, cell):
			continue
		
		# Usa pathfinding per verificare se la cella è raggiungibile
		var path = find_path_avoiding_obstacles(tilemap, start_position, cell, movement_range)
		if not path.is_empty():
			# Il path rappresenta i passi di movimento necessari (non include la posizione di partenza)
			var actual_distance = path.size()
			if actual_distance <= movement_range:
				reachable_cells.append(cell)
				print("  Added cell ", cell, " at path distance ", actual_distance)
			else:
				print("  Skipped cell ", cell, " - path too long (", actual_distance, " > ", movement_range, ")")
		else:
			var manhattan_distance = get_manhattan_distance(start_position, cell)
			if manhattan_distance <= movement_range:
				print("  Skipped unreachable cell ", cell, " (blocked by obstacles)")
	
	print("Total reachable cells: ", reachable_cells.size())
	print("=====================================")
	return reachable_cells

# Verifica se una cella è un ostacolo
static func is_obstacle(tilemap: TileMapLayer, cell_pos: Vector2i) -> bool:
	if not tilemap:
		return true  # Considera come ostacolo se non c'è tilemap
	
	# Ottieni i dati della cella
	var tile_data = tilemap.get_cell_tile_data(cell_pos)
	if not tile_data:
		return true  # Celle senza tile sono ostacoli
	
	# Controlla se c'è un custom data "walkable" impostato
	if tile_data.get_custom_data("walkable") != null:
		return not tile_data.get_custom_data("walkable")
	
	# Controlla se ci sono ostacoli posizionati sopra questa cella
	if has_obstacle_at_position(tilemap, cell_pos):
		return true
	
	# Di default, tutte le celle con tile sono camminabili
	return false

# Calcola la distanza Manhattan tra due celle
static func get_manhattan_distance(from: Vector2i, to: Vector2i) -> int:
	return abs(from.x - to.x) + abs(from.y - to.y)

# Verifica se una cella è raggiungibile da una posizione con un certo range
static func is_cell_reachable(tilemap: TileMapLayer, from: Vector2i, to: Vector2i, movement_range: int) -> bool:
	if not tilemap:
		return false
	
	# Controllo rapido della distanza Manhattan
	var distance = get_manhattan_distance(from, to)
	if distance > movement_range:
		return false
	
	# Controlla se la cella di destinazione ha un tile
	var used_cells = tilemap.get_used_cells()
	if not to in used_cells:
		return false
	
	# Per un controllo più accurato, potremmo implementare pathfinding,
	# ma per ora usiamo la distanza Manhattan come approssimazione
	return true

# Trova un percorso che evita gli ostacoli usando A* con limite di movimento
static func find_path_avoiding_obstacles(tilemap: TileMapLayer, start: Vector2i, end: Vector2i, max_movement: int = -1) -> Array[Vector2i]:
	if not tilemap or is_obstacle(tilemap, end):
		return []  # Non può raggiungere un ostacolo
	
	# Se il movimento è limitato, verifica la distanza Manhattan
	if max_movement > 0 and get_manhattan_distance(start, end) > max_movement:
		return []  # Troppo lontano
	
	# A* pathfinding implementation semplificata
	var open_set = [start]
	var came_from = {}
	var g_score = {start: 0}
	var f_score = {start: get_manhattan_distance(start, end)}
	
	while not open_set.is_empty():
		# Trova il nodo con il f_score più basso
		var current = open_set[0]
		for node in open_set:
			if f_score.get(node, INF) < f_score.get(current, INF):
				current = node
		
		if current == end:
			# Ricostruisci il percorso
			return reconstruct_path(came_from, current)
		
		open_set.erase(current)
		
		# Esamina i vicini (4 direzioni)
		var neighbors = [
			current + Vector2i(1, 0),   # Destra
			current + Vector2i(-1, 0),  # Sinistra
			current + Vector2i(0, 1),   # Giù
			current + Vector2i(0, -1)   # Su
		]
		
		for neighbor in neighbors:
			# Salta se è un ostacolo o fuori dalla mappa
			if is_obstacle(tilemap, neighbor):
				continue
			
			var tentative_g_score = g_score.get(current, INF) + 1
			
			# Se c'è un limite di movimento, controlla se questo percorso lo supererebbe
			if max_movement > 0 and tentative_g_score > max_movement:
				continue  # Percorso troppo lungo, salta questo vicino
			
			if tentative_g_score < g_score.get(neighbor, INF):
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g_score
				f_score[neighbor] = tentative_g_score + get_manhattan_distance(neighbor, end)
				
				if neighbor not in open_set:
					open_set.append(neighbor)
	
	return []  # Nessun percorso trovato

# Ricostruisce il percorso dall'algoritmo A*
static func reconstruct_path(came_from: Dictionary, current: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	while current in came_from:
		path.push_front(current)
		current = came_from[current]
	return path

# Controlla se c'è un ostacolo posizionato in una certa posizione della griglia
static func has_obstacle_at_position(tilemap: TileMapLayer, cell_pos: Vector2i) -> bool:
	# Cerca un ObstacleManager nella scena per gestire gli ostacoli
	var obstacle_manager = find_obstacle_manager(tilemap)
	if obstacle_manager:
		return obstacle_manager.has_obstacle_at(cell_pos)
	return false

# Trova l'ObstacleManager nella scena
static func find_obstacle_manager(tilemap: TileMapLayer) -> Node:
	# Cerca prima nel parent della tilemap
	var parent = tilemap.get_parent()
	if parent:
		for child in parent.get_children():
			if child.has_method("has_obstacle_at"):
				return child
	
	# Se non trovato, cerca nella root della scena
	var scene_root = tilemap.get_tree().current_scene
	if scene_root:
		for child in scene_root.get_children():
			if child.has_method("has_obstacle_at"):
				return child
	
	return null

# Ottieni tutte le celle nell'area di movimento (inclusi ostacoli)
static func get_all_cells_in_movement_range(tilemap: TileMapLayer, start_position: Vector2i, movement_range: int) -> Array[Vector2i]:
	if not tilemap or movement_range <= 0:
		return []
	
	var cells_in_range: Array[Vector2i] = []
	var used_cells = tilemap.get_used_cells()  # Solo celle con tiles
	
	# Controlla ogni cella per vedere se è nell'area di movimento usando distanza Manhattan
	for cell in used_cells:
		var distance = get_manhattan_distance(start_position, cell)
		if distance <= movement_range:
			cells_in_range.append(cell)
	
	return cells_in_range

# Debug: stampa info sulle celle raggiungibili
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
