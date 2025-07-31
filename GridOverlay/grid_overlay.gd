extends Node2D
class_name GridOverlay

# References
@export var tilemap: TileMapLayer
@export var grid_color: Color = Color(1, 0, 0, 0.8)  # Rosso più visibile per debug
@export var grid_width: float = 0  # Più spesso per essere più visibile
@export var hover_color: Color = Color(1, 1, 0, 0.6)  # Giallo per hover
@export var hover_width: float = 3.0  # Più spesso per evidenziare

# Hover state
var hovered_cell: Vector2i = Vector2i(-999, -999)  # Cella attualmente sotto il mouse

func _ready():
	print("GridOverlay: _ready() called")
	
	# Il GridOverlay è figlio di Playground, quindi Playground è il parent
	tilemap = get_parent() as TileMapLayer
	if not tilemap:
		print("GridOverlay: Tilemap not found! Parent type: ", get_parent().get_class())
		return
	else:
		print("GridOverlay: Tilemap found: ", tilemap.name)
	
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
	
	# Ottieni posizione mouse globale
	var mouse_pos = get_global_mouse_position()
	
	# Converti in coordinate griglia
	var local_mouse_pos = tilemap.to_local(mouse_pos)
	var grid_pos = tilemap.local_to_map(local_mouse_pos)
	
	# Controlla se la cella è valida (contiene una tile)
	var tile_data = tilemap.get_cell_tile_data(grid_pos)
	var new_hovered_cell = grid_pos if tile_data != null else Vector2i(-999, -999)
	
	# Se la cella hover è cambiata, ridisegna
	if new_hovered_cell != hovered_cell:
		hovered_cell = new_hovered_cell
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
	
	# Disegna l'hover (diamante giallo più spesso)
	if local_corners.size() == 4:
		draw_line(local_corners[0], local_corners[1], hover_color, hover_width)  # Top -> Right
		draw_line(local_corners[1], local_corners[2], hover_color, hover_width)  # Right -> Bottom  
		draw_line(local_corners[2], local_corners[3], hover_color, hover_width)  # Bottom -> Left
		draw_line(local_corners[3], local_corners[0], hover_color, hover_width)  # Left -> Top

# Forza il ridisegno quando necessario
func refresh_grid():
	queue_redraw()
