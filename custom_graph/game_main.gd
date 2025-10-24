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

@onready var graph_view: CustomGraphView = $CustomGraphView
@onready var token_label: Label = $UILayer/TokenPanel/TokenLabel
@onready var tool_panel: VBoxContainer = $UILayer/ToolPanel

var notification_system: NotificationSystem
var level_complete_screen: LevelCompleteScreen

# Level system
var all_levels: Array = []
var current_level_index: int = 0
var current_level: LevelData = null

# Game state
var tokens: int = 200
var completed_milestone_indices: Array = []
var target_nodes: Array = []
var unlocked_node_types: Array = []

func _ready() -> void:
	# Initialize notification system (add to UILayer for proper z-ordering)
	notification_system = NotificationSystem.new()
	$UILayer.add_child(notification_system)

	# Initialize level complete screen
	level_complete_screen = LevelCompleteScreen.new()
	level_complete_screen.next_level_pressed.connect(_on_next_level_pressed)
	$UILayer.add_child(level_complete_screen)

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

	# Create starting nodes
	var x_offset = -400
	for node_data in current_level.starting_nodes:
		var num_node = NumberNode.new(node_data.value, true)
		num_node.position = Vector2(x_offset, 0)
		graph_view.add_node(num_node)
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
	var next_index = current_level_index + 1
	if next_index < all_levels.size():
		load_level(next_index)
	else:
		print("No more levels! You've completed the game!")

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

func _input(event: InputEvent) -> void:
	if current_level == null:
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
