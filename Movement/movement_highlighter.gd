class_name MovementHighlighter extends Node2D

# Colori per l'evidenziazione
@export var highlight_color: Color = Color(0.2, 0.8, 0.2, 0.6)  # Verde semi-trasparente
@export var highlight_border_color: Color = Color(0.0, 1.0, 0.0, 0.8)  # Verde bordo
@export var highlight_border_width: float = 2.0

# Riferimenti
var tilemap: TileMapLayer
var highlighted_cells: Array[Vector2i] = []
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
	
	print("Highlighting ", highlighted_cells.size(), " reachable cells")
	
	# Crea gli sprite di evidenziazione per ogni cella
	for cell_pos in highlighted_cells:
		create_highlight_sprite(cell_pos)

# Crea uno sprite di evidenziazione per una cella specifica
func create_highlight_sprite(cell_pos: Vector2i) -> void:
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
	
	# Collega il segnale di disegno
	highlight_node.draw.connect(_draw_highlight_cell.bind(highlight_node))
	
	# Forza il ridisegno
	highlight_node.queue_redraw()

# Disegna l'evidenziazione di una cella
func _draw_highlight_cell(node: Node2D) -> void:
	if not tilemap:
		return
	
	# Ottieni le dimensioni di una cella della tilemap
	var tile_size = tilemap.tile_set.tile_size
	
	# Per tilemap isometriche, adatta le dimensioni
	var cell_width = tile_size.x * 0.5
	var cell_height = tile_size.y * 0.5
	
	# Crea un rettangolo centrato
	var rect = Rect2(-cell_width * 0.5, -cell_height * 0.5, cell_width, cell_height)
	
	# Disegna il riempimento
	node.draw_rect(rect, highlight_color)
	
	# Disegna il bordo
	node.draw_rect(rect, highlight_border_color, false, highlight_border_width)

# Pulisce tutte le evidenziazioni
func clear_highlights() -> void:
	for sprite in highlight_sprites:
		if is_instance_valid(sprite):
			sprite.queue_free()
	
	highlight_sprites.clear()
	highlighted_cells.clear()
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
