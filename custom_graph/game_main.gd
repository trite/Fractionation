extends Control

# Preload all custom node types
const NumberNode = preload("res://custom_graph/number_node.gd")
const OperationNode = preload("res://custom_graph/operation_node.gd")
const TargetNode = preload("res://custom_graph/target_node.gd")
const DuplicatorNode = preload("res://custom_graph/duplicator_node.gd")
const NotificationSystem = preload("res://custom_graph/notification_system.gd")
const LevelData = preload("res://custom_graph/level_data.gd")
const Milestone = preload("res://custom_graph/milestone.gd")
const LevelLoader = preload("res://custom_graph/level_loader.gd")
const LevelCompleteScreen = preload("res://custom_graph/level_complete_screen.gd")
const SolutionLoader = preload("res://custom_graph/solution_loader.gd")
const SolutionPlayer = preload("res://custom_graph/solution_player.gd")

@onready var graph_view: CustomGraphView = $CustomGraphView
@onready var token_label: Label = $UILayer/TokenPanel/TokenLabel
@onready var tool_panel: VBoxContainer = $UILayer/ToolPanel

var notification_system: NotificationSystem
var level_complete_screen: LevelCompleteScreen
var solution_player: SolutionPlayer
var persistent_next_level_button: Button  # Shown when user continues playing after level complete

# Level system
var all_levels: Array = []
var current_level_index: int = 0
var current_level: LevelData = null

# Game state
var tokens: int = 200
var completed_milestone_indices: Array = []
var target_nodes: Array = []
var unlocked_node_types: Array = []

# Node ID tracking for solutions
var starter_nodes: Array = []  # Track starting nodes in order
var spawned_node_count: int = 0  # For positioning spawned solution nodes

func _ready() -> void:
	# Initialize notification system (add to UILayer for proper z-ordering)
	notification_system = NotificationSystem.new()
	$UILayer.add_child(notification_system)

	# Initialize level complete screen
	level_complete_screen = LevelCompleteScreen.new()
	level_complete_screen.next_level_pressed.connect(_on_next_level_pressed)
	level_complete_screen.continue_playing_pressed.connect(_on_continue_playing_pressed)
	$UILayer.add_child(level_complete_screen)

	# Initialize solution player
	solution_player = SolutionPlayer.new()
	add_child(solution_player)

	# Create persistent next level button (hidden initially)
	persistent_next_level_button = Button.new()
	persistent_next_level_button.text = "Next Level >>"
	persistent_next_level_button.custom_minimum_size = Vector2(150, 40)
	persistent_next_level_button.position = Vector2(10, 10)  # Top-left corner
	persistent_next_level_button.pressed.connect(_on_persistent_next_level_pressed)
	apply_button_style(persistent_next_level_button)
	persistent_next_level_button.hide()
	$UILayer.add_child(persistent_next_level_button)

	# Connect signals
	graph_view.connection_created.connect(_on_connection_created)
	graph_view.connection_removed.connect(_on_connection_removed)
	graph_view.node_deleted.connect(_on_node_deleted)

	# Load all levels
	var loader = LevelLoader.new()
	all_levels = loader.load_all_levels()

	if all_levels.is_empty():
		push_error("No levels found! Create JSON files in res://Levels/")
		return

	# Load first level
	load_level(0)

func load_level(level_index: int) -> void:
	if level_index < 0 or level_index >= all_levels.size():
		print("Level index out of range: ", level_index)
		return

	# Clear current level state
	clear_level()

	# Set new level
	current_level_index = level_index
	current_level = all_levels[level_index]
	completed_milestone_indices.clear()

	# Initialize game state from level data
	tokens = current_level.starting_tokens
	unlocked_node_types = current_level.available_node_types.duplicate()
	starter_nodes.clear()
	spawned_node_count = 0

	# Create starting nodes
	var x_offset = -400
	for node_data in current_level.starting_nodes:
		var num_node = NumberNode.new(node_data.value, true)
		num_node.position = Vector2(x_offset, 0)
		graph_view.add_node(num_node)
		starter_nodes.append(num_node)  # Track for solution playback
		x_offset += 150  # Space them out

	# Create target nodes
	var y_offset = -200
	for node_data in current_level.target_nodes:
		create_target_node(node_data.value, Vector2(400, y_offset))
		y_offset += 200  # Stack vertically

	# Set up UI buttons
	setup_ui()
	update_token_display()

	print("Loaded level: ", current_level.level_name)

func clear_level() -> void:
	# Remove all nodes from graph
	for node in graph_view.nodes.duplicate():
		graph_view.remove_node(node)

	# Clear target tracking
	target_nodes.clear()

	# Clear UI buttons
	for child in tool_panel.get_children():
		child.queue_free()

func reset_board() -> void:
	"""Reset the current level to its initial state, removing spawned nodes and refunding tokens"""
	if current_level == null:
		return

	print("Resetting board...")

	# Remove all spawned nodes (not starters or targets)
	for node in graph_view.nodes.duplicate():
		# Skip starting nodes and target nodes
		if node.get("is_starting_node") == true:
			continue
		if node is TargetNode:
			continue

		# Remove spawned node
		graph_view.remove_node(node)

	# Reset game state to initial level state
	tokens = current_level.starting_tokens
	completed_milestone_indices.clear()
	unlocked_node_types = current_level.available_node_types.duplicate()
	spawned_node_count = 0

	# Recreate UI to match initial state
	for child in tool_panel.get_children():
		child.queue_free()
	setup_ui()
	update_token_display()

	print("Board reset complete. Tokens: %d" % tokens)

func create_target_node(value: int, pos: Vector2) -> void:
	var target = TargetNode.new(value)
	target.position = pos
	target_nodes.append(target)
	graph_view.add_node(target)

func setup_ui() -> void:
	# Create buttons based on available node types
	if "add" in unlocked_node_types:
		var cost = current_level.node_costs.get("add", 100)
		create_spawn_button("Add [A] (-%d)" % cost, OperationNode.Operation.ADD, cost)

	if "subtract" in unlocked_node_types:
		var cost = current_level.node_costs.get("subtract", 100)
		create_spawn_button("Subtract [S] (-%d)" % cost, OperationNode.Operation.SUBTRACT, cost)

	if "multiply" in unlocked_node_types:
		var cost = current_level.node_costs.get("multiply", 100)
		create_spawn_button("Multiply [Q] (-%d)" % cost, OperationNode.Operation.MULTIPLY, cost)

	if "divide" in unlocked_node_types:
		var cost = current_level.node_costs.get("divide", 100)
		create_spawn_button("Divide [W] (-%d)" % cost, OperationNode.Operation.DIVIDE, cost)

	if "duplicator" in unlocked_node_types:
		var cost = current_level.node_costs.get("duplicator", 200)
		var button = Button.new()
		button.text = "Duplicator [D] (-%d)" % cost
		button.pressed.connect(func(): spawn_duplicator_node(cost))
		apply_button_style(button)
		tool_panel.add_child(button)

func create_spawn_button(button_text: String, operation: OperationNode.Operation, cost: int) -> void:
	var button = Button.new()
	button.text = button_text
	button.pressed.connect(func(): spawn_operation_node(operation, cost))
	apply_button_style(button)
	tool_panel.add_child(button)

func apply_button_style(button: Button) -> void:
	# Apply bright green on dark background styling
	button.add_theme_color_override("font_color", Color(0, 1, 0, 1))  # Bright green
	button.add_theme_color_override("font_hover_color", Color(0.5, 1, 0.5, 1))  # Lighter green on hover
	button.add_theme_color_override("font_pressed_color", Color(0, 0.8, 0, 1))  # Darker green when pressed

	# Create StyleBox for button background
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.1, 0.1, 0.1, 0.9)  # Dark background
	normal_style.border_color = Color(0, 1, 0, 1)  # Bright green border
	normal_style.border_width_left = 2
	normal_style.border_width_right = 2
	normal_style.border_width_top = 2
	normal_style.border_width_bottom = 2
	normal_style.corner_radius_top_left = 5
	normal_style.corner_radius_top_right = 5
	normal_style.corner_radius_bottom_left = 5
	normal_style.corner_radius_bottom_right = 5

	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0.15, 0.3, 0.15, 0.95)  # Slight green tint on hover
	hover_style.border_color = Color(0.5, 1, 0.5, 1)  # Lighter green border
	hover_style.border_width_left = 2
	hover_style.border_width_right = 2
	hover_style.border_width_top = 2
	hover_style.border_width_bottom = 2
	hover_style.corner_radius_top_left = 5
	hover_style.corner_radius_top_right = 5
	hover_style.corner_radius_bottom_left = 5
	hover_style.corner_radius_bottom_right = 5

	var pressed_style = StyleBoxFlat.new()
	pressed_style.bg_color = Color(0.05, 0.2, 0.05, 1)  # Darker green when pressed
	pressed_style.border_color = Color(0, 0.8, 0, 1)  # Darker green border
	pressed_style.border_width_left = 2
	pressed_style.border_width_right = 2
	pressed_style.border_width_top = 2
	pressed_style.border_width_bottom = 2
	pressed_style.corner_radius_top_left = 5
	pressed_style.corner_radius_top_right = 5
	pressed_style.corner_radius_bottom_left = 5
	pressed_style.corner_radius_bottom_right = 5

	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", pressed_style)

func spawn_operation_node(operation: OperationNode.Operation, cost: int) -> void:
	if tokens < cost:
		print("Not enough tokens!")
		return

	tokens -= cost
	update_token_display()

	var op_node = OperationNode.new(operation)
	op_node.position = get_spawn_position()
	op_node.set_meta("node_cost", cost)  # Store cost for refund
	graph_view.add_node(op_node)

	# Start node in drag mode so it follows cursor
	graph_view.start_node_drag(op_node)

	print("Created operation node. Tokens remaining: ", tokens)

func spawn_duplicator_node(cost: int) -> void:
	if tokens < cost:
		print("Not enough tokens!")
		return

	tokens -= cost
	update_token_display()

	var dup_node = DuplicatorNode.new()
	dup_node.position = get_spawn_position()
	dup_node.set_meta("node_cost", cost)  # Store cost for refund
	graph_view.add_node(dup_node)

	# Start node in drag mode so it follows cursor
	graph_view.start_node_drag(dup_node)

	print("Created duplicator node. Tokens remaining: ", tokens)

func get_spawn_position() -> Vector2:
	# Spawn at mouse cursor position (convert to world space)
	var mouse_pos = graph_view.get_local_mouse_position()
	return graph_view.screen_to_world(mouse_pos)

# Solution playback spawn methods (deducts tokens like regular gameplay)
func spawn_operation_node_for_solution(operation: OperationNode.Operation) -> OperationNode:
	var cost = current_level.node_costs.get(_operation_to_string(operation), 100)

	# Deduct tokens just like a player would
	if tokens < cost:
		push_error("Solution playback: not enough tokens (%d needed, %d available)" % [cost, tokens])
		return null

	tokens -= cost
	update_token_display()

	var op_node = OperationNode.new(operation)
	op_node.position = get_solution_spawn_position()
	op_node.set_meta("node_cost", cost)
	graph_view.add_node(op_node)

	spawned_node_count += 1
	return op_node

func spawn_duplicator_node_for_solution() -> DuplicatorNode:
	var cost = current_level.node_costs.get("duplicator", 200)

	# Deduct tokens just like a player would
	if tokens < cost:
		push_error("Solution playback: not enough tokens (%d needed, %d available)" % [cost, tokens])
		return null

	tokens -= cost
	update_token_display()

	var dup_node = DuplicatorNode.new()
	dup_node.position = get_solution_spawn_position()
	dup_node.set_meta("node_cost", cost)
	graph_view.add_node(dup_node)

	spawned_node_count += 1
	return dup_node

func get_solution_spawn_position() -> Vector2:
	# Place nodes in a grid layout in the center area
	var grid_cols = 5
	var spacing = 150

	var row = spawned_node_count / grid_cols
	var col = spawned_node_count % grid_cols

	var x = -200 + col * spacing
	var y = 100 + row * spacing

	return Vector2(x, y)

func _operation_to_string(operation: OperationNode.Operation) -> String:
	match operation:
		OperationNode.Operation.ADD:
			return "add"
		OperationNode.Operation.SUBTRACT:
			return "subtract"
		OperationNode.Operation.MULTIPLY:
			return "multiply"
		OperationNode.Operation.DIVIDE:
			return "divide"
	return ""

func update_token_display() -> void:
	token_label.text = "Tokens: " + str(tokens)

func _on_connection_created(connection: GraphConnection) -> void:
	print("Connection created")
	check_milestones()

func _on_connection_removed(connection: GraphConnection) -> void:
	print("Connection removed")
	check_milestones()

func _on_node_deleted(node: CustomGraphNode) -> void:
	if current_level == null:
		return

	# Check if node has cost metadata (spawned nodes have this)
	if node.has_meta("node_cost"):
		var node_cost = node.get_meta("node_cost")
		var refund_amount = int(node_cost * current_level.refund_percentage)

		if refund_amount > 0:
			tokens += refund_amount
			update_token_display()
			print("Node deleted. Refunded %d tokens (%.0f%% of %d)" % [refund_amount, current_level.refund_percentage * 100, node_cost])
		else:
			print("Node deleted. No refund.")

func check_milestones() -> void:
	if current_level == null:
		return

	# Build current game state for milestone checking
	var game_state = get_game_state()

	# Check each milestone that hasn't been completed yet
	for i in range(current_level.milestones.size()):
		if i in completed_milestone_indices:
			continue  # Already completed

		var milestone = current_level.milestones[i]
		if milestone.check_trigger(game_state):
			complete_milestone(i, milestone)

func get_game_state() -> Dictionary:
	var solved_count = 0
	var total_value = 0
	var solved_targets = []

	for target in target_nodes:
		if target.is_correct:
			solved_count += 1
			total_value += target.target_value
			solved_targets.append(target.target_value)

	return {
		"solved_count": solved_count,
		"total_value": total_value,
		"solved_targets": solved_targets
	}

func complete_milestone(index: int, milestone: Milestone) -> void:
	completed_milestone_indices.append(index)

	# Apply rewards
	for reward in milestone.rewards:
		apply_reward(reward)

	# Show notification
	notification_system.show_notification(
		milestone.notification_title,
		milestone.notification_message
	)

	print("Milestone %d complete: %s" % [index, milestone.notification_title])

	# Check if this was the final milestone
	if completed_milestone_indices.size() >= current_level.milestones.size():
		show_level_complete()

func apply_reward(reward: Dictionary) -> void:
	match reward.get("type", ""):
		"tokens":
			tokens += reward.get("amount", 0)
			update_token_display()

		"starter_node":
			var value = reward.get("value", 0)
			var spawn_pos = find_smart_spawn_position()
			var num_node = NumberNode.new(value, true)
			num_node.position = spawn_pos
			graph_view.add_node(num_node)

		"target_node":
			var value = reward.get("value", 0)
			var spawn_pos = find_smart_spawn_position()
			create_target_node(value, spawn_pos)

		"unlock_node_type":
			var node_type = reward.get("node_type", "")
			if not node_type in unlocked_node_types:
				unlocked_node_types.append(node_type)
				# Recreate UI to show new button
				for child in tool_panel.get_children():
					child.queue_free()
				setup_ui()

func show_level_complete() -> void:
	var final_milestone = current_level.milestones[current_level.milestones.size() - 1]
	level_complete_screen.show_level_complete(
		final_milestone.notification_title,
		final_milestone.notification_message
	)

func _on_next_level_pressed() -> void:
	persistent_next_level_button.hide()  # Hide persistent button when moving to next level
	var next_index = current_level_index + 1
	if next_index < all_levels.size():
		load_level(next_index)
	else:
		print("No more levels! You've completed the game!")

func _on_continue_playing_pressed() -> void:
	"""Called when user clicks 'Continue Playing' on level complete screen"""
	# Show persistent next level button so they can progress when ready
	persistent_next_level_button.show()

func _on_persistent_next_level_pressed() -> void:
	"""Called when user clicks the persistent next level button"""
	persistent_next_level_button.hide()
	_on_next_level_pressed()

func find_smart_spawn_position() -> Vector2:
	# Smart placement algorithm - finds a good spot with clearance from other nodes
	# This uses a grid-based sampling approach common in video game AI

	# Define world space search area (camera starts at 0,0)
	var search_min = Vector2(-600, -400)
	var search_max = Vector2(600, 400)
	var search_size = search_max - search_min

	# Define search grid - sample positions across world space
	var candidates: Array[Dictionary] = []
	var grid_divisions = 8  # 8x8 grid of candidate positions

	for x in range(1, grid_divisions):
		for y in range(1, grid_divisions):
			var pos = search_min + Vector2(
				search_size.x * (float(x) / grid_divisions),
				search_size.y * (float(y) / grid_divisions)
			)

			# Skip center area (middle of world)
			var dist_from_center = pos.distance_to(Vector2.ZERO)
			if dist_from_center < 150:
				continue

			# Calculate minimum distance to any existing node
			var min_dist = INF
			for node in graph_view.nodes:
				var dist = pos.distance_to(node.position)
				min_dist = min(min_dist, dist)

			# Store candidate with its clearance score (higher is better)
			candidates.append({
				"position": pos,
				"clearance": min_dist
			})

	# Sort by clearance (descending) and pick the best
	candidates.sort_custom(func(a, b): return a.clearance > b.clearance)

	if candidates.size() > 0:
		return candidates[0].position

	# Fallback: return a safe position on the left side
	return Vector2(-300, 0)

func play_level_solution() -> void:
	"""Load and play the solution for the current level"""
	if current_level == null:
		print("No level loaded")
		return

	if solution_player.is_playing:
		print("Solution already playing")
		return

	# Load solutions for this level
	var loader = SolutionLoader.new()
	var solutions = loader.load_solutions_for_level(current_level.level_name)

	if solutions.is_empty():
		print("No solution found for level: %s" % current_level.level_name)
		return

	# Select solution based on which milestone we should solve next
	var solution = select_solution_for_current_state(solutions)

	if solution.is_empty():
		print("No appropriate solution found for current state")
		return

	print("Playing solution %d for: %s" % [solution.get("milestone_index", 0), current_level.level_name])

	# Build node lookup dictionary (includes all current starters and targets)
	var node_lookup = build_node_lookup()

	# Start playback (will clean up conflicting nodes internally)
	solution_player.play_solution(solution, node_lookup, self, graph_view)

func select_solution_for_current_state(solutions: Array) -> Dictionary:
	"""Select the appropriate solution based on completed milestones"""
	# Find the next uncompleted milestone
	var next_milestone_index = completed_milestone_indices.size()

	# Find solution for this milestone index
	for solution in solutions:
		if solution.get("milestone_index", -1) == next_milestone_index:
			return solution

	# Fallback to first solution if no match found
	if solutions.size() > 0:
		print("Warning: No solution found for milestone %d, using first solution" % next_milestone_index)
		return solutions[0]

	# Return empty Dictionary instead of null
	return {}

func build_node_lookup() -> Dictionary:
	"""Build a dictionary mapping solution IDs to actual node instances"""
	var lookup = {}

	# Find all starting nodes on the board (including milestone rewards)
	var all_starters = []
	for node in graph_view.nodes:
		if node.get("is_starting_node") == true:
			all_starters.append(node)

	# Map starter nodes by index
	for i in range(all_starters.size()):
		var node_id = "starter_%d" % i
		lookup[node_id] = all_starters[i]

	# Map all target nodes
	for i in range(target_nodes.size()):
		var node_id = "target_%d" % i
		lookup[node_id] = target_nodes[i]

	print("Node lookup built: %d starters, %d targets" % [all_starters.size(), target_nodes.size()])
	return lookup

func _input(event: InputEvent) -> void:
	if current_level == null:
		return

	# Solution playback shortcut (F5)
	if event is InputEventKey and event.pressed and event.keycode == KEY_F5:
		play_level_solution()
		return

	# Keyboard shortcuts for spawning nodes
	if event.is_action_pressed("spawn_add") and "add" in unlocked_node_types:
		var cost = current_level.node_costs.get("add", 100)
		spawn_operation_node(OperationNode.Operation.ADD, cost)
	elif event.is_action_pressed("spawn_subtract") and "subtract" in unlocked_node_types:
		var cost = current_level.node_costs.get("subtract", 100)
		spawn_operation_node(OperationNode.Operation.SUBTRACT, cost)
	elif event.is_action_pressed("spawn_multiply") and "multiply" in unlocked_node_types:
		var cost = current_level.node_costs.get("multiply", 100)
		spawn_operation_node(OperationNode.Operation.MULTIPLY, cost)
	elif event.is_action_pressed("spawn_divide") and "divide" in unlocked_node_types:
		var cost = current_level.node_costs.get("divide", 100)
		spawn_operation_node(OperationNode.Operation.DIVIDE, cost)
	elif event.is_action_pressed("spawn_duplicator") and "duplicator" in unlocked_node_types:
		var cost = current_level.node_costs.get("duplicator", 200)
		spawn_duplicator_node(cost)
