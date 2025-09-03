extends Control
class_name ActionPanel

# References to UI elements
@onready var move_button: Button = $PanelContainer/VBoxContainer/ActionsGrid/MoveButton
@onready var attack_button: Button = $PanelContainer/VBoxContainer/ActionsGrid/AttackButton
@onready var defend_button: Button = $PanelContainer/VBoxContainer/ActionsGrid/DefendButton
@onready var magic_button: Button = $PanelContainer/VBoxContainer/ActionsGrid/MagicButton
@onready var wait_button: Button = $PanelContainer/VBoxContainer/ActionsGrid/WaitButton
@onready var end_turn_button: Button = $PanelContainer/VBoxContainer/EndTurnButton

# Character info display
@onready var character_name: Label = $PanelContainer/VBoxContainer/CharacterInfo/NameLabel
@onready var hp_bar: ProgressBar = $PanelContainer/VBoxContainer/CharacterInfo/HPContainer/HPBar
@onready var hp_value: Label = $PanelContainer/VBoxContainer/CharacterInfo/HPContainer/HPValue
@onready var mp_bar: ProgressBar = $PanelContainer/VBoxContainer/CharacterInfo/MPContainer/MPBar
@onready var mp_value: Label = $PanelContainer/VBoxContainer/CharacterInfo/MPContainer/MPValue
@onready var movement_info: Label = $PanelContainer/VBoxContainer/CharacterInfo/MovementLabel

# References
var player_reference: Player = null
var current_action_mode: ActionMode = ActionMode.NONE

enum ActionMode {
	NONE,
	MOVE,
	ATTACK,
	DEFEND,
	MAGIC,
	TARGETING
}

# Action state tracking
var is_action_selected: bool = false
var pending_action: ActionMode = ActionMode.NONE

func _ready():
	print("ActionPanel: Initializing...")
	
	# Connect button signals
	move_button.pressed.connect(_on_move_pressed)
	attack_button.pressed.connect(_on_attack_pressed)
	defend_button.pressed.connect(_on_defend_pressed)
	magic_button.pressed.connect(_on_magic_pressed)
	wait_button.pressed.connect(_on_wait_pressed)
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	
	# Set initial state
	reset_action_selection()
	
	print("ActionPanel: Ready! Use keys 1-6 or click buttons")

func set_player_reference(player: Player) -> void:
	player_reference = player
	print("ActionPanel: Player reference set")
	update_character_info()
	update_button_states()

func update_character_info() -> void:
	if not player_reference or not player_reference.stats:
		return
	
	# Update character name
	if character_name:
		character_name.text = "Player"
	
	# Update HP bar and value
	var stats = player_reference.stats
	if hp_bar:
		hp_bar.max_value = stats.max_health
		hp_bar.value = stats.current_health
	
	if hp_value:
		hp_value.text = "%d/%d" % [stats.current_health, stats.max_health]
	
	# Update MP bar and value
	if mp_bar:
		mp_bar.max_value = stats.max_mana
		mp_bar.value = stats.current_mana
	
	if mp_value:
		mp_value.text = "%d/%d" % [stats.current_mana, stats.max_mana]
	
	# Movement info
	var remaining = player_reference.get_remaining_movement()
	var total = player_reference.get_movement_range()
	if movement_info:
		movement_info.text = "Movement: %d/%d" % [remaining, total]

func update_button_states() -> void:
	if not player_reference:
		return
	
	# Enable/disable buttons based on character state
	var has_movement = player_reference.has_movement_left()
	var is_alive = player_reference.stats.is_alive() if player_reference.stats else false
	var has_mana = player_reference.stats.has_mana(10.0) if player_reference.stats else false  # Require 10 MP for magic
	
	# Move button only enabled if player has movement left
	move_button.disabled = not has_movement or not is_alive
	
	# Other action buttons are enabled based on conditions
	attack_button.disabled = not is_alive
	defend_button.disabled = not is_alive
	magic_button.disabled = not is_alive or not has_mana  # Requires mana
	wait_button.disabled = not is_alive
	end_turn_button.disabled = not is_alive
	

func reset_action_selection() -> void:
	current_action_mode = ActionMode.NONE
	is_action_selected = false
	pending_action = ActionMode.NONE
	
	# Reset button visual states
	_reset_button_styles()

func _reset_button_styles() -> void:
	# Reset all buttons to default style
	var buttons = [move_button, attack_button, defend_button, magic_button, wait_button]
	for button in buttons:
		if button:
			button.modulate = Color.WHITE

func _highlight_selected_button(selected_button: Button) -> void:
	_reset_button_styles()
	if selected_button:
		selected_button.modulate = Color.YELLOW

# Button press handlers
func _on_move_pressed() -> void:
	# Check if player has movement left
	if player_reference and not player_reference.has_movement_left():
		return
	
	current_action_mode = ActionMode.MOVE
	_highlight_selected_button(move_button)
	
	if player_reference:
		# Enter movement mode
		if not player_reference.is_movement_mode:
			player_reference.enter_movement_mode()

func _on_attack_pressed() -> void:
	print("ActionPanel: Attack action selected")
	current_action_mode = ActionMode.ATTACK
	_highlight_selected_button(attack_button)
	
	# Show attack range/targeting
	_enter_targeting_mode()
	print("ActionPanel: Attack targeting mode activated")

func _on_defend_pressed() -> void:
	print("ActionPanel: Defend action selected")
	current_action_mode = ActionMode.DEFEND
	_highlight_selected_button(defend_button)
	
	# Execute defend immediately
	_execute_defend_action()

func _on_magic_pressed() -> void:
	print("✨ ActionPanel: Magic action selected")
	
	# Check if player has enough mana
	if player_reference and player_reference.stats:
		if not player_reference.stats.has_mana(10.0):
			print("⚠️ ActionPanel: Not enough mana! Need 10 MP for magic.")
			return
		
		# Consume mana and cast spell
		if player_reference.consume_mana(10.0):
			print("✨ ActionPanel: Player casts MAGIC! Consumed 10 MP (Console output only)")
		else:
			print("❌ ActionPanel: Failed to consume mana!")
			return
	
	current_action_mode = ActionMode.MAGIC
	_highlight_selected_button(magic_button)
	
	# Execute immediately for console output
	_finish_action()

func _on_wait_pressed() -> void:
	print("ActionPanel: Wait action selected")
	current_action_mode = ActionMode.NONE
	
	# End character's turn but don't advance to next character yet
	_execute_wait_action()

func _on_end_turn_pressed() -> void:
	print("ActionPanel: End Turn selected")
	current_action_mode = ActionMode.NONE
	
	# End turn and advance to next character
	_execute_end_turn_action()

# Action execution methods
func _enter_targeting_mode() -> void:
	# For now, we'll use a simple approach - right click for attack
	# In a more complex system, this would show attack range and allow target selection
	print("ActionPanel: Right-click to attack target")
	# Could highlight attackable enemies here

func _execute_defend_action() -> void:
	if not player_reference:
		return
	
	# Simple console output for now
	print("🛡️ ActionPanel: Player DEFENDS! (Console output only)")
	
	# End the character's action for this turn
	_finish_action()

func _execute_wait_action() -> void:
	if not player_reference:
		return
	
	print("⏸️ ActionPanel: Player WAITS! (Console output only)")
	
	_finish_action()

func _execute_end_turn_action() -> void:
	if not player_reference:
		return
	
	print("🔄 ActionPanel: Player ENDS TURN! (Console output only)")
	
	_finish_action()

# Removed _start_new_player_turn for simplified version

func _finish_action() -> void:
	# Reset action selection
	reset_action_selection()
	
	# Update UI state
	update_character_info()
	update_button_states()

# Handle input for targeting modes and keyboard shortcuts
func _unhandled_input(event: InputEvent) -> void:
	# Attack targeting with right-click
	if current_action_mode == ActionMode.ATTACK and event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		
		# Right-click to execute attack
		if mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed:
			_execute_ranged_attack(mouse_event.global_position)
			get_viewport().set_input_as_handled()
	
	# Keyboard shortcuts for quick testing (only for testing purposes)
	if event is InputEventKey and event.pressed:
		var key_event = event as InputEventKey
		if key_event.keycode == KEY_1:  # Press '1' for Move
			_on_move_pressed()
			get_viewport().set_input_as_handled()
		elif key_event.keycode == KEY_2:  # Press '2' for Attack
			_on_attack_pressed()
			get_viewport().set_input_as_handled()
		elif key_event.keycode == KEY_3:  # Press '3' for Defend
			_on_defend_pressed()
			get_viewport().set_input_as_handled()
		elif key_event.keycode == KEY_4:  # Press '4' for Magic
			_on_magic_pressed()
			get_viewport().set_input_as_handled()
		elif key_event.keycode == KEY_5:  # Press '5' for Wait
			_on_wait_pressed()
			get_viewport().set_input_as_handled()
		elif key_event.keycode == KEY_6:  # Press '6' for End Turn
			_on_end_turn_pressed()
			get_viewport().set_input_as_handled()

func _execute_ranged_attack(target_position: Vector2) -> void:
	if not player_reference:
		return
	
	print("⚔️ ActionPanel: Player ATTACKS at position ", target_position, "! (Console output only)")
	
	# Finish the action
	_finish_action()

# Called by external systems to update the panel
func on_player_action_changed() -> void:
	update_character_info()
	update_button_states()

func on_movement_changed() -> void:
	update_character_info()
	update_button_states()
	
	# Check if movement just ran out and notify
	if player_reference and not player_reference.has_movement_left():
		print("🛑 ActionPanel: Movement exhausted! Turn will end automatically.")
		# Reset current action if it was movement
		if current_action_mode == ActionMode.MOVE:
			reset_action_selection()

# Called when HP changes
func on_hp_changed() -> void:
	update_character_info()
	update_button_states()

# Called when MP changes
func on_mp_changed() -> void:
	update_character_info()
	update_button_states()

# Public methods for external systems
func get_current_action_mode() -> ActionMode:
	return current_action_mode

func is_in_targeting_mode() -> bool:
	return current_action_mode == ActionMode.ATTACK or current_action_mode == ActionMode.MAGIC

func cancel_current_action() -> void:
	if current_action_mode == ActionMode.MOVE and player_reference:
		player_reference.exit_movement_mode()
	
	reset_action_selection()
