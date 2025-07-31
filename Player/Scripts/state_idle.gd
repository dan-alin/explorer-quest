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
	
	# Handle mouse click for movement
	if _event is InputEventMouseButton and _event.pressed and _event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
		handle_movement_click(_event.global_position)
	
	return null

func handle_movement_click(mouse_pos: Vector2):
	# Muovi il player al centro della cella cliccata (solo se diversa da quella attuale)
	print("=== GRID MOVEMENT ===")
	print("Mouse clicked at: ", mouse_pos)
	
	var tilemap = player.get_parent() as TileMapLayer
	if tilemap:
		# 1. Converti click del mouse in coordinate griglia
		var local_mouse_pos = tilemap.to_local(mouse_pos)
		var target_grid_pos = tilemap.local_to_map(local_mouse_pos)
		print("Target grid position: ", target_grid_pos)
		
		# 2. Ottieni la posizione griglia attuale del player
		var player_local_pos = tilemap.to_local(player.global_position)
		var current_grid_pos = tilemap.local_to_map(player_local_pos)
		print("Player current grid position: ", current_grid_pos)
		
		# 3. Se il player è già nella cella target, non fare nulla
		if current_grid_pos == target_grid_pos:
			print("Player already in target cell - no movement")
			print("=========================")
			return
		
		# 4. Controlla se la cella target è valida
		var tile_data = tilemap.get_cell_tile_data(target_grid_pos)
		if tile_data == null:
			print("No tile at target position!")
			return
		
		# 5. Calcola il centro della cella target
		var cell_center_local = tilemap.map_to_local(target_grid_pos)
		var cell_center_global = tilemap.to_global(cell_center_local)
		# Offset per centrare perfettamente il personaggio nella cella isometrica
		var adjusted_position = cell_center_global + Vector2(1, -19)
		
		print("Moving from cell ", current_grid_pos, " to cell ", target_grid_pos)
		
		# 6. Muovi il player alla nuova cella
		player.global_position = adjusted_position
		print("Player moved to: ", player.global_position)
		print("=========================")
	else:
		print("Tilemap not found!")
