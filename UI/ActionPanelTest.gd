extends Control

# Simple test script to verify ActionPanel functionality
# This can be attached to a Control node for standalone testing

var action_panel: ActionPanel
var test_player: Player

func _ready():
	print("🧪 ActionPanel Test: Starting...")
	
	# Try to find ActionPanel in the scene
	action_panel = find_child("ActionPanel") as ActionPanel
	if not action_panel:
		print("❌ ActionPanel Test: ActionPanel not found!")
		return
	
	# Try to find Player in the scene
	test_player = get_tree().get_first_node_in_group("player") as Player
	if not test_player:
		print("❌ ActionPanel Test: Player not found!")
		return
	
	# Set up the connection
	action_panel.set_player_reference(test_player)
	
	print("✅ ActionPanel Test: Setup complete!")
	print("🎯 ActionPanel Test: Try pressing buttons or using keyboard shortcuts")
	print("📝 ActionPanel Test: Watch console for action outputs")
	
	# Test initial state
	test_initial_state()

func test_initial_state():
	print("\n🔍 Testing initial ActionPanel state...")
	
	if action_panel.player_reference:
		print("✅ Player reference: OK")
	else:
		print("❌ Player reference: MISSING")
	
	if action_panel.get_current_action_mode() == ActionPanel.ActionMode.NONE:
		print("✅ Initial action mode: NONE (correct)")
	else:
		print("❌ Initial action mode: Unexpected state")
	
	print("🔍 Initial state test complete\n")

func _input(event: InputEvent):
	# Add some test-specific shortcuts
	if event is InputEventKey and event.pressed:
		var key_event = event as InputEventKey
		
		# Press T to run all tests
		if key_event.keycode == KEY_T:
			run_all_tests()
			get_viewport().set_input_as_handled()
		
		# Press H for help
		elif key_event.keycode == KEY_H:
			show_help()
			get_viewport().set_input_as_handled()

func run_all_tests():
	print("\n🚀 Running all ActionPanel tests...")
	
	if not action_panel or not test_player:
		print("❌ Cannot run tests: Missing references")
		return
	
	# Test each action
	print("🧪 Testing Move action...")
	action_panel._on_move_pressed()
	await get_tree().process_frame
	
	print("🧪 Testing Attack action...")
	action_panel._on_attack_pressed()
	await get_tree().process_frame
	
	print("🧪 Testing Defend action...")
	action_panel._on_defend_pressed()
	await get_tree().process_frame
	
	print("🧪 Testing Magic action...")
	action_panel._on_magic_pressed()
	await get_tree().process_frame
	
	print("🧪 Testing Wait action...")
	action_panel._on_wait_pressed()
	await get_tree().process_frame
	
	print("🧪 Testing End Turn action...")
	action_panel._on_end_turn_pressed()
	await get_tree().process_frame
	
	print("✅ All tests completed!")

func show_help():
	print("\n📚 ActionPanel Test Help:")
	print("  1-6: Action buttons (Move, Attack, Defend, Magic, Wait, End Turn)")
	print("  T: Run all tests automatically")
	print("  H: Show this help")
	print("  Watch console for output from each action\n")
