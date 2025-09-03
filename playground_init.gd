extends Node2D

# Script to initialize the playground with obstacles for testing

@onready var terrain_layer: TileMapLayer
@onready var action_panel: ActionPanel

func _ready():
	# Wait a frame to ensure all nodes are ready
	await get_tree().process_frame
	
	# Get reference to the terrain layer
	terrain_layer = $TerrainLayer
	
	# Find the ObstacleManager
	var obstacle_manager = get_node("ObstacleManager")
	if obstacle_manager:
		# Set the tilemap reference to terrain layer
		obstacle_manager.set_tilemap(terrain_layer)
		
			
		
		# Add test obstacles
		obstacle_manager.add_obstacle_at(Vector2i(6, 3))   # Near center
		obstacle_manager.add_obstacle_at(Vector2i(8, 4))   # Block path
		obstacle_manager.add_obstacle_at(Vector2i(7, 2))   # Force detour
		obstacle_manager.add_obstacle_at(Vector2i(9, 3))   # Another obstacle
		obstacle_manager.add_obstacle_at(Vector2i(5, 5))   # Create barrier
		
	
	# Initialize ActionPanel if it exists
	var ui_layer = get_node_or_null("UI")
	if ui_layer:
		action_panel = ui_layer.get_node_or_null("ActionPanel")
		if action_panel:
			# Set player reference for the action panel
			var player = get_node("Player")
			if player:
				action_panel.set_player_reference(player)
				
				# Connect player to camera for R key reset functionality
				var camera = get_node_or_null("Camera2D")
				if camera and camera.has_method("set_player"):
					camera.set_player(player)
