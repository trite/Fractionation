extends Control

# Preload all custom node types
const NumberNode = preload("res://custom_graph/number_node.gd")
const OperationNode = preload("res://custom_graph/operation_node.gd")
const TargetNode = preload("res://custom_graph/target_node.gd")
const DuplicatorNode = preload("res://custom_graph/duplicator_node.gd")
const NotificationSystem = preload("res://custom_graph/notification_system.gd")

@onready var graph_view: CustomGraphView = $CustomGraphView
@onready var token_label: Label = $UILayer/TokenPanel/TokenLabel
@onready var tool_panel: VBoxContainer = $UILayer/ToolPanel

var notification_system: NotificationSystem

# Token system
const OPERATION_COST: int = 100
const DUPLICATOR_COST: int = 200
var tokens: int = 200

# Milestone tracking
var milestones_completed: int = 0
var duplicator_unlocked: bool = false

# Track target nodes for win condition
var target_nodes: Array[TargetNode] = []

func _ready() -> void:
	# Initialize notification system (add to UILayer for proper z-ordering)
	notification_system = NotificationSystem.new()
	$UILayer.add_child(notification_system)

	create_starting_nodes()
	setup_ui()
	update_token_display()

	# Connect signals
	graph_view.connection_created.connect(_on_connection_created)
	graph_view.connection_removed.connect(_on_connection_removed)

func create_starting_nodes() -> void:
	# Position nodes in world coordinates
	# Camera starts at (0, 0) with zoom 1.0, so position relative to origin

	# Create single starting number node (1) - left side
	var num_node_1 = NumberNode.new(1, true)
	num_node_1.position = Vector2(-400, 0)
	graph_view.add_node(num_node_1)

	# Create single target node (3) - right side
	create_target_node(3, Vector2(400, 0))

func create_target_node(value: int, pos: Vector2) -> void:
	var target = TargetNode.new(value)
	target.position = pos
	target_nodes.append(target)
	graph_view.add_node(target)

func setup_ui() -> void:
	# Create buttons for spawning nodes
	create_spawn_button("Add [A] (-100)", OperationNode.Operation.ADD, OPERATION_COST)
	create_spawn_button("Subtract [S] (-100)", OperationNode.Operation.SUBTRACT, OPERATION_COST)
	create_spawn_button("Multiply [Q] (-100)", OperationNode.Operation.MULTIPLY, OPERATION_COST)
	create_spawn_button("Divide [W] (-100)", OperationNode.Operation.DIVIDE, OPERATION_COST)

func create_spawn_button(button_text: String, operation: OperationNode.Operation, cost: int) -> void:
	var button = Button.new()
	button.text = button_text
	button.pressed.connect(func(): spawn_operation_node(operation, cost))
	tool_panel.add_child(button)

func spawn_operation_node(operation: OperationNode.Operation, cost: int) -> void:
	if tokens < cost:
		print("Not enough tokens!")
		return

	tokens -= cost
	update_token_display()

	var op_node = OperationNode.new(operation)
	op_node.position = get_spawn_position()
	graph_view.add_node(op_node)

	# Start node in drag mode so it follows cursor
	graph_view.start_node_drag(op_node)

	print("Created operation node. Tokens remaining: ", tokens)

func spawn_duplicator_node() -> void:
	if not duplicator_unlocked:
		print("Duplicator not unlocked yet!")
		return

	if tokens < DUPLICATOR_COST:
		print("Not enough tokens!")
		return

	tokens -= DUPLICATOR_COST
	update_token_display()

	var dup_node = DuplicatorNode.new()
	dup_node.position = get_spawn_position()
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
	check_win_condition()

func _on_connection_removed(connection: GraphConnection) -> void:
	print("Connection removed")
	check_win_condition()

func check_milestones() -> void:
	# First milestone - completing target 3
	if milestones_completed == 0:
		var solved_count = count_solved_targets()
		if solved_count >= 1:
			complete_first_milestone()

	# Second milestone - completing both target 3 and target 37
	elif milestones_completed == 1:
		var solved_count = count_solved_targets()
		if solved_count >= 2:
			complete_second_milestone()

	# Third milestone - completing all three targets (3, 37, 42)
	elif milestones_completed == 2:
		var solved_count = count_solved_targets()
		if solved_count >= 3:
			complete_third_milestone()

func complete_first_milestone() -> void:
	milestones_completed = 1

	# Award tokens
	tokens += 500
	update_token_display()

	# Show notification
	notification_system.show_notification(
		"Milestone Complete!",
		"First target solved! +500 tokens. Node 5 unlocked. New target: 37"
	)

	# Spawn node 5 at a smart location
	var spawn_pos = find_smart_spawn_position()
	var num_node_5 = NumberNode.new(5, true)
	num_node_5.position = spawn_pos
	graph_view.add_node(num_node_5)

	# Add new target: 37 (above first target)
	create_target_node(37, Vector2(400, -200))

	print("First milestone complete! +500 tokens, Node 5 spawned, target 37 added.")

func complete_second_milestone() -> void:
	milestones_completed = 2
	duplicator_unlocked = true

	# Award tokens
	tokens += 300
	update_token_display()

	# Show notification
	notification_system.show_notification(
		"Milestone Complete!",
		"Both targets solved! +300 tokens. Duplicator unlocked. New target: 42"
	)

	# Add duplicator button to UI
	var button = Button.new()
	button.text = "Duplicator [D] (-200)"
	button.pressed.connect(spawn_duplicator_node)
	tool_panel.add_child(button)

	# Add new target: 42 (below first target)
	create_target_node(42, Vector2(400, 200))

	print("Second milestone complete! +300 tokens, Duplicator unlocked, target 42 added.")

func complete_third_milestone() -> void:
	milestones_completed = 3

	# Award tokens
	tokens += 600
	update_token_display()

	# Show notification
	notification_system.show_notification(
		"Milestone Complete!",
		"Three targets solved! +600 tokens. New target: 512"
	)

	# Add new target: 512 (further below)
	create_target_node(512, Vector2(400, 400))

	print("Third milestone complete! +600 tokens, target 512 added.")

func count_solved_targets() -> int:
	var count = 0
	for target in target_nodes:
		if target.is_correct:
			count += 1
	return count

func check_win_condition() -> void:
	# Milestones handle progression now, no need for win screen
	pass

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
	# Keyboard shortcuts for spawning nodes
	if event.is_action_pressed("spawn_add"):
		spawn_operation_node(OperationNode.Operation.ADD, OPERATION_COST)
	elif event.is_action_pressed("spawn_subtract"):
		spawn_operation_node(OperationNode.Operation.SUBTRACT, OPERATION_COST)
	elif event.is_action_pressed("spawn_multiply"):
		spawn_operation_node(OperationNode.Operation.MULTIPLY, OPERATION_COST)
	elif event.is_action_pressed("spawn_divide"):
		spawn_operation_node(OperationNode.Operation.DIVIDE, OPERATION_COST)
	elif event.is_action_pressed("spawn_duplicator"):
		if duplicator_unlocked:
			spawn_duplicator_node()
