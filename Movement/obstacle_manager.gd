class_name ObstacleManager extends Node2D

# Gestisce gli ostacoli posizionati sopra le tile della mappa
var obstacles: Dictionary = {}  # Vector2i -> bool (grid_pos -> is_obstacle)
var tilemap: TileMapLayer

func _ready():
	print("ObstacleManager: Initialized")

# Imposta il riferimento alla tilemap
func set_tilemap(tm: TileMapLayer):
	tilemap = tm

# Aggiunge un ostacolo in una posizione della griglia
func add_obstacle_at(grid_pos: Vector2i) -> void:
	obstacles[grid_pos] = true
	print("ObstacleManager: Added obstacle at ", grid_pos)
	
	# Visual marker sarà gestito dal MovementHighlighter quando necessario

# Rimuove un ostacolo da una posizione della griglia
func remove_obstacle_at(grid_pos: Vector2i) -> void:
	if grid_pos in obstacles:
		obstacles.erase(grid_pos)
		print("ObstacleManager: Removed obstacle at ", grid_pos)
		
		# Visual marker sarà gestito dal MovementHighlighter quando necessario

# Controlla se c'è un ostacolo in una posizione della griglia
func has_obstacle_at(grid_pos: Vector2i) -> bool:
	return grid_pos in obstacles

# Ottieni tutte le posizioni degli ostacoli
func get_all_obstacles() -> Array[Vector2i]:
	var obstacle_positions: Array[Vector2i] = []
	for pos in obstacles.keys():
		obstacle_positions.append(pos)
	return obstacle_positions

# Crea un visual marker per l'ostacolo evidenziando la tile isometrica in rosso
func create_obstacle_visual(grid_pos: Vector2i) -> void:
	if not tilemap:
		return
	
	# Converti posizione griglia in posizione mondo per isometrico
	var cell_center_local = tilemap.map_to_local(grid_pos)
	var cell_center_global = tilemap.to_global(cell_center_local)
	
	# Crea un nodo Node2D per disegnare la forma isometrica
	var obstacle_visual = Node2D.new()
	obstacle_visual.position = cell_center_global
	obstacle_visual.name = "Obstacle_Overlay_" + str(grid_pos.x) + "_" + str(grid_pos.y)
	obstacle_visual.z_index = 1  # Sopra le tile
	
	# Aggiungi il nodo come figlio
	add_child(obstacle_visual)
	
	# Collega il segnale di disegno per disegnare la forma isometrica
	obstacle_visual.draw.connect(_draw_isometric_obstacle.bind(obstacle_visual))
	obstacle_visual.queue_redraw()

# Rimuovi il visual marker dell'ostacolo rimuovendo l'overlay rosso
func remove_obstacle_visual(grid_pos: Vector2i) -> void:
	if not tilemap:
		return
	
	# Rimuovi l'overlay Node2D
	var overlay_name = "Obstacle_Overlay_" + str(grid_pos.x) + "_" + str(grid_pos.y)
	var overlay_node = get_node_or_null(overlay_name)
	if overlay_node:
		overlay_node.queue_free()

# Disegna un overlay isometrico rosso per rappresentare l'ostacolo
func _draw_isometric_obstacle(node: Node2D) -> void:
	if not tilemap:
		return
	
	var tile_size = tilemap.tile_set.tile_size
	# Per tile isometriche, le proporzioni sono solitamente 2:1 (larghezza:altezza)
	# Adatta le dimensioni per abbinare meglio le tile isometriche
	var half_width = tile_size.x / 2
	var quarter_height = tile_size.y / 4  # Usa 1/4 dell'altezza per proporzioni isometriche
	
	# Punti per la forma a diamante isometrica (proporzioni 2:1)
	var points = PackedVector2Array([
		Vector2(0, -quarter_height),           # Top
		Vector2(half_width, 0),                # Right
		Vector2(0, quarter_height),            # Bottom
		Vector2(-half_width, 0)                # Left
	])
	
	# Disegna il diamante rosso semitrasparente
	node.draw_colored_polygon(points, Color(1.0, 0.0, 0.0, 0.6))
	# Aggiungi un bordo rosso scuro
	var closed_points = points
	closed_points.append(points[0])  # Chiudi il poligono
	node.draw_polyline(closed_points, Color.DARK_RED, 2.0)


# Aggiunge ostacoli casuali per testing (opzionale)
func add_random_obstacles(count: int = 5) -> void:
	if not tilemap:
		print("ObstacleManager: No tilemap set, cannot add random obstacles")
		return
	
	var used_cells = tilemap.get_used_cells()
	if used_cells.is_empty():
		return
	
	# Aggiungi ostacoli casuali
	for i in range(count):
		var random_cell = used_cells[randi() % used_cells.size()]
		# Evita di mettere ostacoli sulla posizione del player (assumendo che sia vicino al centro)
		if random_cell != Vector2i(0, 0):  # Cambia questa logica se necessario
			add_obstacle_at(random_cell)

# Debug: stampa info sugli ostacoli
func debug_obstacles() -> void:
	print("=== OBSTACLE MANAGER DEBUG ===")
	print("Total obstacles: ", obstacles.size())
	for pos in obstacles.keys():
		print("  Obstacle at: ", pos)
	print("===============================")
