class_name MovementHighlighter extends Node2D

# Colori per l'evidenziazione
@export var highlight_color: Color = Color(0.2, 0.8, 0.2, 0.6)  # Verde semi-trasparente per celle raggiungibili
@export var highlight_border_color: Color = Color(0.0, 1.0, 0.0, 0.8)  # Verde bordo per celle raggiungibili
@export var obstacle_color: Color = Color(0.8, 0.2, 0.2, 0.6)  # Rosso semi-trasparente per ostacoli
@export var obstacle_border_color: Color = Color(1.0, 0.0, 0.0, 0.8)  # Rosso bordo per ostacoli
@export var highlight_border_width: float = 2.0

# Riferimenti
var tilemap: TileMapLayer
var highlighted_cells: Array[Vector2i] = []
var obstacle_cells: Array[Vector2i] = []  # Celle ostacolo da evidenziare
var highlight_sprites: Array[Node2D] = []

func _ready():
	# Imposta z_index per essere sopra la tilemap ma sotto il player
	z_index = 50

# Imposta il riferimento alla tilemap
func set_tilemap(tm: TileMapLayer) -> void:
	tilemap = tm

# Evidenzia le celle raggiungibili da una posizione
func highlight_reachable_cells(start_position: Vector2i, movement_range: int) -> void:
	# Prima pulisci le evidenziazioni precedenti
	clear_highlights()
	
	if not tilemap:
		print("MovementHighlighter: No tilemap reference set!")
		return
	
	# Calcola le celle raggiungibili
	highlighted_cells = MovementCalculator.get_reachable_cells(tilemap, start_position, movement_range)
	
	# Trova gli ostacoli nel range di movimento per evidenziarli in rosso
	find_obstacles_in_range(start_position, movement_range)
	
	print("Highlighting ", highlighted_cells.size(), " reachable cells and ", obstacle_cells.size(), " obstacles")
	
	# Crea gli sprite di evidenziazione per le celle raggiungibili (verdi)
	for cell_pos in highlighted_cells:
		create_highlight_sprite(cell_pos, false)
	
	# Crea gli sprite di evidenziazione per gli ostacoli (rossi)
	for cell_pos in obstacle_cells:
		create_highlight_sprite(cell_pos, true)

# Crea uno sprite di evidenziazione per una cella specifica
func create_highlight_sprite(cell_pos: Vector2i, is_obstacle: bool = false) -> void:
	if not tilemap:
		return
	
	# Controlla se siamo nell'albero della scena
	if not get_tree():
		print("MovementHighlighter: Not in scene tree yet!")
		return
	
	# Converti posizione griglia in posizione mondo
	var cell_center_local = tilemap.map_to_local(cell_pos)
	var cell_center_global = tilemap.to_global(cell_center_local)
	
	# Crea un nodo per l'evidenziazione
	var highlight_node = Node2D.new()
	highlight_node.position = cell_center_global
	highlight_node.z_index = z_index
	
	# Aggiungi il nodo come figlio di questo highlighter invece che alla scena
	add_child(highlight_node)
	highlight_sprites.append(highlight_node)
	
	# Collega il segnale di disegno con informazione se è un ostacolo
	highlight_node.draw.connect(_draw_highlight_cell.bind(highlight_node, is_obstacle))
	
	# Forza il ridisegno
	highlight_node.queue_redraw()

# Disegna l'evidenziazione di una cella
func _draw_highlight_cell(node: Node2D, is_obstacle: bool = false) -> void:
	if not tilemap:
		return
	
	# Ottieni le dimensioni di una cella della tilemap
	var tile_size = tilemap.tile_set.tile_size
	
	# Per tilemap isometriche, crea una forma a diamante
	var half_width = tile_size.x / 2
	var quarter_height = tile_size.y / 4  # Proporzioni isometriche 2:1
	
	# Punti per la forma a diamante isometrica
	var points = PackedVector2Array([
		Vector2(0, -quarter_height),     # Top
		Vector2(half_width, 0),          # Right
		Vector2(0, quarter_height),      # Bottom
		Vector2(-half_width, 0)          # Left
	])
	
	# Scegli colori in base al tipo di cella
	var fill_color = obstacle_color if is_obstacle else highlight_color
	var border_color = obstacle_border_color if is_obstacle else highlight_border_color
	
	# Disegna il riempimento del diamante
	node.draw_colored_polygon(points, fill_color)
	
	# Disegna il bordo del diamante
	var closed_points = points
	closed_points.append(points[0])  # Chiudi il poligono
	node.draw_polyline(closed_points, border_color, highlight_border_width)

# Trova gli ostacoli nel range di movimento
func find_obstacles_in_range(start_position: Vector2i, movement_range: int) -> void:
	obstacle_cells.clear()
	
	if not tilemap:
		print("MovementHighlighter: No tilemap for obstacle detection")
		return
	
	# Cerca l'ObstacleManager nella scena
	var obstacle_manager = MovementCalculator.find_obstacle_manager(tilemap)
	if not obstacle_manager:
		print("MovementHighlighter: No ObstacleManager found")
		return
	
	print("MovementHighlighter: Found ObstacleManager, checking for obstacles...")
	
	# Ottieni tutte le celle della tilemap
	var used_cells = tilemap.get_used_cells()
	var total_obstacles = 0
	
	# Controlla ogni cella per vedere se è un ostacolo nel range
	for cell in used_cells:
		# Salta se è la posizione di partenza
		if cell == start_position:
			continue
		
		# Controlla se è un ostacolo
		if obstacle_manager.has_obstacle_at(cell):
			total_obstacles += 1
			# Controlla se è nel range di movimento (usando distanza Manhattan come filtro)
			var distance = MovementCalculator.get_manhattan_distance(start_position, cell)
			print("  Found obstacle at ", cell, " distance: ", distance)
			if distance <= movement_range:
				obstacle_cells.append(cell)
				print("    Added to highlight list")
			else:
				print("    Too far (distance ", distance, " > range ", movement_range, ")")
	
	print("MovementHighlighter: Found ", total_obstacles, " total obstacles, ", obstacle_cells.size(), " in range")

# Pulisce tutte le evidenziazioni
func clear_highlights() -> void:
	for sprite in highlight_sprites:
		if is_instance_valid(sprite):
			sprite.queue_free()
	
	highlight_sprites.clear()
	highlighted_cells.clear()
	obstacle_cells.clear()
	print("Cleared movement highlights")

# Controlla se una cella è attualmente evidenziata
func is_cell_highlighted(cell_pos: Vector2i) -> bool:
	return cell_pos in highlighted_cells

# Ottieni tutte le celle attualmente evidenziate
func get_highlighted_cells() -> Array[Vector2i]:
	return highlighted_cells.duplicate()

# Debug: stampa info sulle celle evidenziate
func debug_highlighted_cells() -> void:
	print("=== HIGHLIGHTED CELLS DEBUG ===")
	print("Total highlighted cells: ", highlighted_cells.size())
	for cell in highlighted_cells:
		print("  Highlighted cell: ", cell)
	print("===============================")
