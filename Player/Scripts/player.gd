class_name Player extends CharacterBody2D

var cardinal_direction: Vector2 = Vector2.DOWN
var direction: Vector2 = Vector2.ZERO

# Character stats
@export var stats: CharacterStats
var is_invulnerable: bool = false

# Movement highlighting
var grid_overlay: GridOverlay
var is_movement_mode: bool = false
var current_grid_position: Vector2i  # Posizione griglia corrente del player

# Movement per turn system
var remaining_movement: int = 0  # Movimento rimanente nel turno corrente
var total_movement_this_turn: int = 0  # Movimento totale utilizzato in questo turno

# Dash/Dodge properties
var dash_direction: Vector2 = Vector2.ZERO
var can_dash: bool = true

# Projectile system
@export var projectile_scene: PackedScene
var projectile_spawn_offset: float = 20.0


@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
@onready var state_machine: PlayerStateMachine = $StateMachine


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Initialize stats if not already set
	if not stats:
		stats = CharacterStats.create_character_stats(4, 250.0, 100.0)  # Player default stats
	
	add_to_group("player")  # Add to group so enemies can find us
	state_machine.Initialize(self)
	# Assicura che il player sia sopra la griglia
	z_index = 100
	
	# Snap il player al centro di una cella all'avvio
	snap_to_grid_center()
	
	print("Player initialized with stats: ", stats.get_stats_info())
	
	# Entra automaticamente in movement mode dopo l'inizializzazione
	call_deferred("enter_movement_mode")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# No automatic keyboard input - movement only via mouse clicks
	direction = Vector2.ZERO
	
	pass


func _physics_process(delta: float) -> void:
	move_and_slide()


func SetDirection() -> bool:
	var new_direction: Vector2 = cardinal_direction
	
	if direction == Vector2.ZERO:
		return false
	
	if direction.y == 0: 
		new_direction = Vector2.LEFT if direction.x < 0 else Vector2.RIGHT
	elif direction.x == 0:
		new_direction = Vector2.UP if direction.y < 0 else Vector2.DOWN
		
	if new_direction == cardinal_direction:
		return false
	
	cardinal_direction = new_direction
	sprite.scale.x = -1 if cardinal_direction == Vector2.LEFT else 1
	return true
	


func UpdateAnimation(state: String) -> void:
	animation_player.play(state + "_" + AnimateDirection())
	pass


func AnimateDirection() -> String:
	if cardinal_direction == Vector2.DOWN:
		return 'down'
	elif cardinal_direction == Vector2.UP:
		return 'up'
	else:
		return "side"


# Damage system for player
func take_damage(damage: float, knockback_vector: Vector2) -> void:
	if is_invulnerable or not stats:
		return
	
	var actual_damage = stats.take_damage(damage)
	print("Player took ", actual_damage, " damage! Health: ", stats.current_health, "/", stats.max_health)
	
	# Apply knockback
	velocity += knockback_vector
	
	# Visual feedback
	flash_damage()
	
	# Brief invulnerability to prevent spam damage
	set_invulnerable(1.0)
	
	if not stats.is_alive():
		die()

func flash_damage() -> void:
	if sprite:
		sprite.modulate = Color.RED
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.3)

func set_invulnerable(duration: float) -> void:
	is_invulnerable = true
	# Create flashing effect during invulnerability
	var tween = create_tween()
	tween.set_loops(int(duration * 10))  # Flash 10 times per second
	tween.tween_property(sprite, "modulate:a", 0.5, 0.05)
	tween.tween_property(sprite, "modulate:a", 1.0, 0.05)
	
	# End invulnerability
	var timer = get_tree().create_timer(duration)
	timer.timeout.connect(_end_invulnerability)

func _end_invulnerability() -> void:
	is_invulnerable = false
	if sprite:
		sprite.modulate = Color.WHITE

func die() -> void:
	print("Player died! Game Over")
	# For now, just restart the scene
	get_tree().reload_current_scene()

func shoot_projectile(target_position: Vector2) -> void:
	if not projectile_scene:
		print("No projectile scene assigned!")
		return
	
	# Calculate direction from player to target
	var shoot_direction = (target_position - global_position).normalized()
	
	# Spawn position slightly in front of player
	var spawn_position = global_position + shoot_direction * projectile_spawn_offset
	
	# Create and configure projectile
	var projectile = projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)
	projectile.initialize(spawn_position, shoot_direction, 1.0)  # 1 damage
	
	print("Player shoots projectile toward ", target_position)

func snap_to_grid_center():
	# Snap il player al centro di una cella all'avvio del gioco
	var tilemap = get_parent() as TileMapLayer
	if not tilemap:
		print("Player: No tilemap found for grid snapping")
		return
	
	# Trova la cella più vicina alla posizione attuale del player
	var player_local_pos = tilemap.to_local(global_position)
	var current_grid_pos = tilemap.local_to_map(player_local_pos)
	
	# Controlla se la cella corrente è valida
	var tile_data = tilemap.get_cell_tile_data(current_grid_pos)
	if tile_data == null:
		# Se la cella corrente non è valida, trova la cella valida più vicina
		current_grid_pos = find_nearest_valid_cell(tilemap, current_grid_pos)
	
	# Calcola il centro della cella e posiziona il player
	var cell_center_local = tilemap.map_to_local(current_grid_pos)
	var cell_center_global = tilemap.to_global(cell_center_local)
	
	# Usa lo stesso offset che usiamo per il movimento
	var adjusted_position = cell_center_global + Vector2(1, -19)
	
	# Posiziona il player
	global_position = adjusted_position
	
	# Memorizza la posizione griglia corretta
	current_grid_position = current_grid_pos
	
	print("Player snapped to grid cell ", current_grid_pos, " at position ", global_position)

func find_nearest_valid_cell(tilemap: TileMapLayer, start_pos: Vector2i) -> Vector2i:
	# Trova la cella valida (con tile) più vicina alla posizione di partenza
	var used_cells = tilemap.get_used_cells()
	
	if used_cells.is_empty():
		return start_pos  # Fallback
	
	# Trova la cella più vicina
	var nearest_cell = used_cells[0]
	var min_distance = abs(start_pos.x - nearest_cell.x) + abs(start_pos.y - nearest_cell.y)
	
	for cell in used_cells:
		var distance = abs(start_pos.x - cell.x) + abs(start_pos.y - cell.y)
		if distance < min_distance:
			min_distance = distance
			nearest_cell = cell
	
	return nearest_cell

# Movement utility functions based on stats
func get_movement_range() -> int:
	if not stats:
		return 0
	return stats.get_movement_range()

func can_move_to_distance(distance: int) -> bool:
	if not stats:
		return false
	return stats.can_move_to_distance(distance)

# Movement highlighting functions
func initialize_grid_overlay() -> void:
	# Trova il GridOverlay nella scena
	if not grid_overlay:
		var tilemap = get_parent() as TileMapLayer
		if tilemap:
			# Cerca il GridOverlay come figlio della tilemap
			for child in tilemap.get_children():
				if child is GridOverlay:
					grid_overlay = child
					print("Found GridOverlay: ", grid_overlay.name)
					# Imposta il riferimento al player nel GridOverlay
					grid_overlay.set_player_reference(self)
					break
		
		if not grid_overlay:
			print("Warning: Could not find GridOverlay!")

func enter_movement_mode() -> void:
	# Entra in modalità movimento
	is_movement_mode = true
	
	# Inizializza il grid overlay se necessario
	initialize_grid_overlay()
	
	# Calcola e evidenzia le celle raggiungibili
	if grid_overlay:
		var tilemap = get_parent() as TileMapLayer
		if tilemap:
			# Se non è stato inizializzato il sistema di turni, inizializzalo
			if remaining_movement == 0 and total_movement_this_turn == 0:
				start_new_turn()
			
			print("=== PLAYER MOVEMENT MODE DEBUG ===")
			print("Player starting grid position: ", current_grid_position)
			print("Remaining movement: ", remaining_movement)
			print("Max movement range: ", get_movement_range())
			print("======================================")
			
			# Evidenzia le celle raggiungibili basate sul movimento residuo
			if has_movement_left():
				grid_overlay.highlight_reachable_cells(current_grid_position, remaining_movement)
			else:
				grid_overlay.clear_highlights()
				print("No movement left - no cells highlighted")
			print("Entered movement mode - highlighting reachable cells")

func exit_movement_mode() -> void:
	# Esci dalla modalità movimento
	is_movement_mode = false
	
	# Pulisci le evidenziazioni
	if grid_overlay:
		grid_overlay.clear_highlights()
		print("Exited movement mode - cleared highlights")

func is_cell_reachable(target_cell: Vector2i) -> bool:
	# Controlla se una cella è raggiungibile e evidenziata
	if not grid_overlay or not is_movement_mode:
		return false
	
	return grid_overlay.is_cell_highlighted(target_cell)

# Turn-based movement system
func start_new_turn() -> void:
	# Inizia un nuovo turno - ripristina il movimento completo
	remaining_movement = get_movement_range()
	total_movement_this_turn = 0
	print("=== NEW TURN STARTED ===")
	print("Movement available: ", remaining_movement)
	print("=========================")
	
	# Ricalcola le evidenziazioni per il nuovo turno
	if is_movement_mode:
		enter_movement_mode()

func consume_movement(distance: int) -> bool:
	# Consuma movimento per una certa distanza
	if distance > remaining_movement:
		print("Not enough movement! Required: ", distance, ", Available: ", remaining_movement)
		return false
	
	remaining_movement -= distance
	total_movement_this_turn += distance
	
	print("Movement consumed: ", distance)
	print("Remaining movement: ", remaining_movement)
	
	# Se non c'è più movimento, termina il turno
	if remaining_movement <= 0:
		end_turn()
	
	return true

func get_remaining_movement() -> int:
	return remaining_movement

func can_afford_movement(distance: int) -> bool:
	return distance <= remaining_movement

func end_turn() -> void:
	# Termina il turno - nessun movimento rimasto
	print("=== TURN ENDED ===")
	print("Total movement used: ", total_movement_this_turn)
	print("No more movement available!")
	print("===================")
	
	# Disabilita le evidenziazioni
	if grid_overlay:
		grid_overlay.clear_highlights()
	# Ma mantieni movement mode attivo per permettere azioni future

func has_movement_left() -> bool:
	return remaining_movement > 0
