class_name State_Idle extends State

@onready var walk: State = $"../Walk"
@onready var dash: State = $"../Dash"
@onready var attack: State = $"../Attack"
@onready var ranged_attack: State = $"../RangedAttack"




## what hapens when the player enters this state?
func Enter() -> void:
	player.UpdateAnimation("idle")
	pass
	
func Exit() -> void:
	pass

func Process(_delta: float) -> State:
	# Player is always immobile in idle - no automatic transition to walk
	player.velocity = Vector2.ZERO
	return null
	

func Physics(_delta: float) -> State:
	return null 


func HandleInput(_event: InputEvent) -> State:
	if _event.is_action_pressed("dash") and player.can_dash:
		return dash
	# Removed click attack - now click is used for movement
	if _event.is_action_pressed("ranged_attack"):
		return ranged_attack
	
	# Handle mouse click for movement (movement mode sempre attivo)
	if _event is InputEventMouseButton and _event.pressed and _event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
		handle_movement_click(_event.global_position)
	
	# Tasto R per iniziare un nuovo turno (debug/test)
	if _event is InputEventKey and _event.pressed and _event.keycode == KEY_R:
		player.start_new_turn()
	
	return null

func handle_movement_click(mouse_pos: Vector2):
	# Muovi il player attraverso le celle fino alla destinazione
	print("=== GRID MOVEMENT ===")
	print("Mouse clicked at: ", mouse_pos)
	
	# Convert to camera-aware position if camera is active
	var world_mouse_pos = get_camera_aware_mouse_position(mouse_pos)
	print("Camera-aware position: ", world_mouse_pos)
	
	var tilemap = player.get_parent() as TileMapLayer
	if tilemap:
		# 1. Converti click del mouse in coordinate griglia (usa camera-aware position)
		var local_mouse_pos = tilemap.to_local(world_mouse_pos)
		var target_grid_pos = tilemap.local_to_map(local_mouse_pos)
		print("Target grid position: ", target_grid_pos)
		
		# 2. Ottieni la posizione griglia attuale del player (usa la posizione memorizzata)
		var current_grid_pos = player.current_grid_position
		print("Player current grid position: ", current_grid_pos)
		
		# 3. Se il player è già nella cella target, non fare nulla
		if current_grid_pos == target_grid_pos:
			print("Player already in target cell - no movement")
			print("=========================")
			return
		
		# 4. Controlla se la cella è un ostacolo
		if MovementCalculator.is_obstacle(tilemap, target_grid_pos):
			print("Target cell is an obstacle - movement denied!")
			print("=========================")
			return
		
		# 5. Controlla se la cella è evidenziata (raggiungibile)
		if not player.is_cell_reachable(target_grid_pos):
			print("Cell not reachable or highlighted - movement denied!")
			print("=========================")
			return
		
		# 6. Calcola il percorso attraverso le celle PRIMA di calcolare il costo
		var path = calculate_path(current_grid_pos, target_grid_pos)
		print("Path calculated: ", path)
		
		# 7. Controlla che ci sia un percorso valido e che non attraversi ostacoli
		if path.is_empty():
			print("No valid path found - movement denied!")
			print("=========================")
			return
		
		# 8. Valida che il percorso non attraversi ostacoli
		if not validate_path_clear(path, tilemap):
			print("Path goes through obstacles - movement denied!")
			print("=========================")
			return
		
		# 9. Calcola il costo di movimento basato sulla lunghezza effettiva del percorso
		var actual_movement_cost = path.size()
		var manhattan_distance = abs(current_grid_pos.x - target_grid_pos.x) + abs(current_grid_pos.y - target_grid_pos.y)
		print("Manhattan distance: ", manhattan_distance)
		print("Actual path length: ", actual_movement_cost)
		
		# 10. Verifica se il movimento è possibile con il costo effettivo
		if not player.can_afford_movement(actual_movement_cost):
			print("Not enough movement for actual path! Required: ", actual_movement_cost, ", Available: ", player.get_remaining_movement())
			print("=========================")
			return
		
		# 11. SOLO ORA consuma il movimento effettivo (dopo aver validato tutto)
		player.consume_movement(actual_movement_cost)
		
		# 11. Pulisci il path preview prima di iniziare l'animazione
		if player.grid_overlay:
			player.grid_overlay.clear_path_preview()
		
		# 12. Anima il player attraverso le celle del percorso
		animate_through_path(path, tilemap)
		
		# 12. Aggiorna la posizione griglia del player
		player.current_grid_position = target_grid_pos
		
		# 13. Aggiorna le evidenziazioni dalla nuova posizione (dopo un breve delay)
		get_tree().create_timer(0.1).timeout.connect(func(): player.enter_movement_mode())
		
		print("Player moved along path to: ", target_grid_pos)
		print("Remaining movement: ", player.get_remaining_movement())
		print("=========================")
	else:
		print("Tilemap not found!")

func validate_path_clear(path: Array[Vector2i], tilemap: TileMapLayer) -> bool:
	# Verifica che ogni cella del percorso non sia un ostacolo
	for cell in path:
		if MovementCalculator.is_obstacle(tilemap, cell):
			print("  Path blocked at cell: ", cell)
			return false
	return true

func calculate_path(start: Vector2i, end: Vector2i) -> Array[Vector2i]:
	# Usa A* pathfinding per evitare ostacoli con limite di movimento
	var tilemap = player.get_parent() as TileMapLayer
	if not tilemap:
		return []
	
	# Ottieni il movimento rimanente del player
	var movement_limit = player.get_remaining_movement()
	var path = MovementCalculator.find_path_avoiding_obstacles(tilemap, start, end, movement_limit)
	
	# Se A* non trova un percorso, prova il percorso lineare come fallback
	if path.is_empty():
		path = calculate_linear_path(start, end, tilemap)
	
	return path

func calculate_linear_path(start: Vector2i, end: Vector2i, tilemap: TileMapLayer) -> Array[Vector2i]:
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

func animate_through_path(path: Array[Vector2i], tilemap: TileMapLayer):
	# Usa un tween per muovere il player attraverso il percorso
	var tween = create_tween()
	var duration_per_tile = 0.2  # Durata movimento per cella
	
	for tile in path:
		var cell_center_local = tilemap.map_to_local(tile)
		var cell_center_global = tilemap.to_global(cell_center_local)
		var adjusted_position = cell_center_global + Vector2(1, -19)
		
		tween.tween_property(player, "global_position", adjusted_position, duration_per_tile)

# Camera-aware mouse position function (CRITICAL for camera compatibility)
func get_camera_aware_mouse_position(screen_pos: Vector2) -> Vector2:
	# Get the current camera
	var camera = get_viewport().get_camera_2d()
	if camera:
		# Camera is active - use camera-aware mouse position
		return camera.get_global_mouse_position()
	else:
		# No camera - use the screen position as world position
		return screen_pos
