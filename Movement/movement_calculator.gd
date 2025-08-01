class_name MovementCalculator extends RefCounted

# Calcola tutte le celle raggiungibili da una posizione di partenza
static func get_reachable_cells(tilemap: TileMapLayer, start_position: Vector2i, movement_range: int) -> Array[Vector2i]:
	if not tilemap or movement_range <= 0:
		return []
	
	var reachable_cells: Array[Vector2i] = []
	var used_cells = tilemap.get_used_cells()  # Solo celle con tiles
	
	print("=== CALCULATING REACHABLE CELLS ===")
	print("Start position: ", start_position)
	print("Movement range: ", movement_range)
	print("Total cells in tilemap: ", used_cells.size())
	
	# Usa distanza Manhattan per calcolare tutte le celle raggiungibili
	# Questo assicura che la distanza sia sempre corretta in tutte le direzioni
	for cell in used_cells:
		var distance = get_manhattan_distance(start_position, cell)
		# Se la cella è entro il range di movimento e non è la posizione di partenza
		if distance <= movement_range and distance > 0:
			reachable_cells.append(cell)
			print("  Added cell ", cell, " at distance ", distance)
	
	print("Total reachable cells: ", reachable_cells.size())
	print("=====================================")
	return reachable_cells

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
	print("=============================")
