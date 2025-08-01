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
	# Muovi il player al centro della cella cliccata (solo se raggiungibile)
	print("=== GRID MOVEMENT ===")
	print("Mouse clicked at: ", mouse_pos)
	
	var tilemap = player.get_parent() as TileMapLayer
	if tilemap:
		# 1. Converti click del mouse in coordinate griglia
		var local_mouse_pos = tilemap.to_local(mouse_pos)
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
		
		# 4. Controlla se la cella è evidenziata (raggiungibile)
		if not player.is_cell_reachable(target_grid_pos):
			print("Cell not reachable or highlighted - movement denied!")
			print("=========================")
			return
		
		# 5. Calcola la distanza di movimento (Manhattan distance)
		var movement_distance = abs(current_grid_pos.x - target_grid_pos.x) + abs(current_grid_pos.y - target_grid_pos.y)
		print("Movement distance calculated: ", movement_distance)
		
		# Verifica se il movimento è possibile
		if not player.can_afford_movement(movement_distance):
			print("Not enough movement to reach the target cell!")
			print("=========================")
			return
		
		# 6. Consuma il movimento
		player.consume_movement(movement_distance)
		
		# 7. Calcola il centro della cella target
		var cell_center_local = tilemap.map_to_local(target_grid_pos)
		var cell_center_global = tilemap.to_global(cell_center_local)
		# Offset per centrare perfettamente il personaggio nella cella isometrica
		var adjusted_position = cell_center_global + Vector2(1, -19)
		
		print("Moving from cell ", current_grid_pos, " to cell ", target_grid_pos)
		
		# 8. Muovi il player alla nuova cella
		player.global_position = adjusted_position
		
		# 9. Aggiorna la posizione griglia del player
		player.current_grid_position = target_grid_pos
		
		# 10. Aggiorna le evidenziazioni dalla nuova posizione
		player.enter_movement_mode()  # Ricalcola le celle raggiungibili
		
		print("Player moved to: ", player.global_position)
		print("Remaining movement: ", player.get_remaining_movement())
		print("=========================")
	else:
		print("Tilemap not found!")
