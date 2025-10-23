extends Control

@onready var graph_edit: GraphEdit = $GraphEdit
@onready var add_button: Button = $ToolPanel/MarginContainer/HBoxContainer/AddButton
@onready var subtract_button: Button = $ToolPanel/MarginContainer/HBoxContainer/SubtractButton
@onready var multiply_button: Button = $ToolPanel/MarginContainer/HBoxContainer/MultiplyButton
@onready var divide_button: Button = $ToolPanel/MarginContainer/HBoxContainer/DivideButton
@onready var duplicator_button: Button = $ToolPanel/MarginContainer/HBoxContainer/DuplicatorButton
@onready var token_label: Label = $ToolPanel/MarginContainer/HBoxContainer/TokenLabel
@onready var win_screen: ColorRect = $WinScreen

# Track which nodes are starting nodes (cannot be deleted)
var starting_nodes: Array[String] = []
var target_nodes: Array[String] = []
var node_counter: int = 0

# Token system
const OPERATION_COST: int = 100
const DUPLICATOR_COST: int = 200
var tokens: int = 500

# Milestone system
var milestones: Array[Milestone] = []
var unlocked_nodes: Array[String] = ["add", "subtract", "multiply", "divide"]

# Connection dragging state
var is_connection_grabbed: bool = false
var grabbed_from_node: StringName = ""
var grabbed_from_port: int = -1
var grabbed_is_output: bool = false
var grabbed_connection_was_existing: bool = false
var grabbed_original_target: StringName = ""
var grabbed_original_target_port: int = -1

func _ready() -> void:
	# Connect GraphEdit signals
	graph_edit.connection_request.connect(_on_connection_request)
	graph_edit.disconnection_request.connect(_on_disconnection_request)
	graph_edit.delete_nodes_request.connect(_on_delete_nodes_request)
	graph_edit.connection_drag_started.connect(_on_connection_drag_started)
	graph_edit.connection_drag_ended.connect(_on_connection_drag_ended)
	graph_edit.popup_request.connect(_on_popup_request)
	graph_edit.connection_to_empty.connect(_on_connection_to_empty)
	graph_edit.connection_from_empty.connect(_on_connection_from_empty)

	# Connect button signals
	add_button.pressed.connect(_on_add_button_pressed)
	subtract_button.pressed.connect(_on_subtract_button_pressed)
	multiply_button.pressed.connect(_on_multiply_button_pressed)
	divide_button.pressed.connect(_on_divide_button_pressed)
	duplicator_button.pressed.connect(_on_duplicator_button_pressed)

	# Setup milestones
	setup_milestones()

	# Create the two starting nodes
	create_starting_nodes()

	# Create target nodes
	create_target_nodes()

	# Update token display
	update_token_display()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_A:
				_on_add_button_pressed()
			KEY_S:
				_on_subtract_button_pressed()
			KEY_M:
				_on_multiply_button_pressed()
			KEY_D:
				_on_divide_button_pressed()
			KEY_U:
				if "duplicator" in unlocked_nodes:
					_on_duplicator_button_pressed()

func create_starting_nodes() -> void:
	# Calculate positions based on viewport size
	var viewport_size = get_viewport_rect().size
	var left_x = viewport_size.x * 0.20  # 20% from left
	var top_y = viewport_size.y * 0.33   # 33% from top
	var bottom_y = viewport_size.y * 0.66  # 66% from top

	# Create node with value 5 (top left)
	var node5 = create_number_node("node_5", 5, Vector2(left_x, top_y))
	starting_nodes.append("node_5")

	# Create node with value 1 (bottom left)
	var node1 = create_number_node("node_1", 1, Vector2(left_x, bottom_y))
	starting_nodes.append("node_1")

func create_number_node(node_name: String, value: int, position: Vector2) -> GraphNode:
	var node = preload("res://number_node.tscn").instantiate()
	node.name = node_name
	node.position_offset = position
	node.set_value(value)
	graph_edit.add_child(node)
	return node

func create_target_nodes() -> void:
	# Calculate positions based on viewport size
	var viewport_size = get_viewport_rect().size
	var right_x = viewport_size.x * 0.80  # 80% from left
	var top_y = viewport_size.y * 0.33   # 33% from top
	var bottom_y = viewport_size.y * 0.66  # 66% from top

	# Create target node for 42 (top right)
	var target1 = create_target_node("target_42", 42, Vector2(right_x, top_y))
	target_nodes.append("target_42")
	starting_nodes.append("target_42")  # Prevent deletion

	# Create target node for 37 (bottom right)
	var target2 = create_target_node("target_37", 37, Vector2(right_x, bottom_y))
	target_nodes.append("target_37")
	starting_nodes.append("target_37")  # Prevent deletion

func create_target_node(node_name: String, target: int, position: Vector2) -> GraphNode:
	var node = preload("res://target_node.tscn").instantiate()
	node.name = node_name
	node.position_offset = position
	node.set_target(target)
	graph_edit.add_child(node)
	return node

func update_token_display() -> void:
	token_label.text = "Tokens: " + str(tokens)

func setup_milestones() -> void:
	# First connection milestone - unlocks duplicator
	var first_connection = Milestone.new(
		"First Connection",
		Milestone.TriggerType.FIRST_CONNECTION,
		null,
		300,
		["duplicator"]
	)
	milestones.append(first_connection)

func _on_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	var existing_connections = graph_edit.get_connection_list()

	for connection in existing_connections:
		# If there's already a connection FROM this output port, disconnect it first
		if connection["from_node"] == from_node and connection["from_port"] == from_port:
			graph_edit.disconnect_node(connection["from_node"], connection["from_port"],
									   connection["to_node"], connection["to_port"])
			# Clear the input on the old target node
			update_node_input(connection["to_node"], connection["to_port"], null)

		# If there's already a connection TO this input port, disconnect it first
		if connection["to_node"] == to_node and connection["to_port"] == to_port:
			graph_edit.disconnect_node(connection["from_node"], connection["from_port"],
									   connection["to_node"], connection["to_port"])
			# Clear the input on the target node
			update_node_input(to_node, to_port, null)

	# Create the new connection
	graph_edit.connect_node(from_node, from_port, to_node, to_port)

	# Update the value on the connected node
	var source_node = graph_edit.get_node(NodePath(from_node))
	var target_node = graph_edit.get_node(NodePath(to_node))

	if source_node and target_node:
		var value = get_node_output_value(source_node)
		update_node_input(to_node, to_port, value)

	# Check win condition after connection
	check_win_condition()

func _on_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	print("Disconnection requested: ", from_node, ":", from_port, " -> ", to_node, ":", to_port)
	graph_edit.disconnect_node(from_node, from_port, to_node, to_port)
	# Clear the input on the target node
	update_node_input(to_node, to_port, null)

func _on_delete_nodes_request(nodes: Array[StringName]) -> void:
	for node_name in nodes:
		# Prevent deletion of starting nodes
		if node_name in starting_nodes:
			print("Cannot delete starting node: ", node_name)
			continue

		# Disconnect all connections from/to this node first
		var connections = graph_edit.get_connection_list()
		for connection in connections:
			if connection["from_node"] == node_name or connection["to_node"] == node_name:
				graph_edit.disconnect_node(connection["from_node"], connection["from_port"],
										   connection["to_node"], connection["to_port"])
				# Clear inputs on target nodes
				if connection["to_node"] != node_name:
					update_node_input(connection["to_node"], connection["to_port"], null)

		# Refund tokens if it's an operation or duplicator node
		var node = graph_edit.get_node(NodePath(node_name))
		if node:
			if node.has_method("set_input_a") and node.has_method("set_input_b"):
				# It's an operation node
				tokens += OPERATION_COST
				update_token_display()
			elif node.has_method("set_input") and node.has_method("get_result"):
				# It's a duplicator node
				tokens += DUPLICATOR_COST
				update_token_display()

		# Get the node and remove it
		if node:
			node.queue_free()

func get_spawn_position() -> Vector2:
	# Get mouse position relative to GraphEdit
	var mouse_pos = graph_edit.get_local_mouse_position()
	# Convert to graph coordinates
	var graph_pos = (mouse_pos + graph_edit.scroll_offset) / graph_edit.zoom
	return graph_pos

func create_operation_node(operation: int) -> void:
	# Check if we have enough tokens
	if tokens < OPERATION_COST:
		print("Not enough tokens! Need ", OPERATION_COST, ", have ", tokens)
		return

	# Deduct tokens
	tokens -= OPERATION_COST
	update_token_display()

	var node = preload("res://operation_node.tscn").instantiate()
	node.name = "operation_" + str(node_counter)
	node_counter += 1

	# Position at mouse cursor
	node.position_offset = get_spawn_position()
	node.set_operation(operation)
	graph_edit.add_child(node)

func _on_add_button_pressed() -> void:
	create_operation_node(0)  # Operation.ADD

func _on_subtract_button_pressed() -> void:
	create_operation_node(1)  # Operation.SUBTRACT

func _on_multiply_button_pressed() -> void:
	create_operation_node(2)  # Operation.MULTIPLY

func _on_divide_button_pressed() -> void:
	create_operation_node(3)  # Operation.DIVIDE

func _on_duplicator_button_pressed() -> void:
	create_duplicator_node()

func create_duplicator_node() -> void:
	# Check if duplicator is unlocked
	if not "duplicator" in unlocked_nodes:
		print("Duplicator not yet unlocked!")
		return

	# Check if we have enough tokens
	if tokens < DUPLICATOR_COST:
		print("Not enough tokens! Need ", DUPLICATOR_COST, ", have ", tokens)
		return

	# Deduct tokens
	tokens -= DUPLICATOR_COST
	update_token_display()

	var node = preload("res://duplicator_node.tscn").instantiate()
	node.name = "duplicator_" + str(node_counter)
	node_counter += 1

	# Position at mouse cursor
	node.position_offset = get_spawn_position()
	graph_edit.add_child(node)

func get_node_output_value(node: Node) -> Variant:
	# Get the output value from a node
	if node.has_method("get_value"):
		return node.get_value()
	elif node.has_method("get_result"):
		return node.get_result()
	return null

func update_node_input(node_name: StringName, port: int, value: Variant) -> void:
	var node = graph_edit.get_node(NodePath(node_name))
	if not node:
		return

	# Handle nodes with simple set_input (target nodes and duplicators)
	if node.has_method("set_input") and not node.has_method("set_input_a"):
		if value != null:
			node.set_input(value)
		else:
			node.clear_input()

		# Propagate if it's a duplicator (has output)
		if node.has_method("get_result"):
			propagate_value_changes(node_name)
		return

	# Update the appropriate input based on the port for operation nodes
	if node.has_method("handle_input_update"):
		# Operation nodes handle their own port mapping
		node.handle_input_update(port, value)
		# Propagate changes downstream
		propagate_value_changes(node_name)

func propagate_value_changes(source_node_name: StringName) -> void:
	# Find all connections from this node and update downstream nodes
	var connections = graph_edit.get_connection_list()
	var source_node = graph_edit.get_node(NodePath(source_node_name))

	if not source_node:
		return

	var output_value = get_node_output_value(source_node)

	for connection in connections:
		if connection["from_node"] == source_node_name:
			# This node is the source, update the target
			update_node_input(connection["to_node"], connection["to_port"], output_value)

func check_win_condition() -> void:
	# Gather stats about solved targets
	var solved_count := 0
	var solved_targets: Array = []
	var total_value := 0

	for target_name in target_nodes:
		var target_node = graph_edit.get_node(NodePath(target_name))
		if target_node and target_node.has_method("is_solved"):
			if target_node.is_solved():
				solved_count += 1
				solved_targets.append(target_name)
				if target_node.has_method("get_target"):
					total_value += target_node.target_value

	# Check milestones
	check_milestones(solved_count, solved_targets, total_value)

	# Check if all target nodes are solved
	var all_solved := (solved_count == target_nodes.size())
	if all_solved:
		show_win_screen()

func check_milestones(solved_count: int, solved_targets: Array, total_value: int) -> void:
	for milestone in milestones:
		if milestone.check_trigger(solved_count, solved_targets, total_value):
			milestone.complete()
			on_milestone_achieved(milestone)

func on_milestone_achieved(milestone: Milestone) -> void:
	print("Milestone achieved: ", milestone.milestone_name)

	# Award tokens
	if milestone.token_reward > 0:
		tokens += milestone.token_reward
		update_token_display()
		print("  Awarded ", milestone.token_reward, " tokens!")

	# Unlock nodes
	for node_type in milestone.unlocks:
		if not node_type in unlocked_nodes:
			unlocked_nodes.append(node_type)
			print("  Unlocked: ", node_type)

			# Show UI buttons for unlocked nodes
			if node_type == "duplicator":
				duplicator_button.visible = true

	# TODO: Show visual notification to player

func _on_connection_drag_started(from_node: StringName, from_port: int, is_output: bool) -> void:
	# Store info about what's being dragged
	grabbed_from_node = from_node
	grabbed_from_port = from_port
	grabbed_is_output = is_output

	print("Dragging connection from ", from_node, " port ", from_port, " (is_output: ", is_output, ")")

	# Track if this is starting from an existing connection
	grabbed_connection_was_existing = false
	var connections = graph_edit.get_connection_list()
	for connection in connections:
		if is_output and connection["from_node"] == from_node and connection["from_port"] == from_port:
			# Dragging from an output that already has a connection
			grabbed_connection_was_existing = true
			grabbed_original_target = connection["to_node"]
			grabbed_original_target_port = connection["to_port"]
			# Disconnect the old connection immediately so it can be redrawn
			graph_edit.disconnect_node(connection["from_node"], connection["from_port"],
									   connection["to_node"], connection["to_port"])
			update_node_input(connection["to_node"], connection["to_port"], null)
			break
		elif not is_output and connection["to_node"] == from_node and connection["to_port"] == from_port:
			# Dragging from an input that already has a connection
			grabbed_connection_was_existing = true
			grabbed_original_target = connection["from_node"]
			grabbed_original_target_port = connection["from_port"]
			# Disconnect the old connection immediately so it can be redrawn
			graph_edit.disconnect_node(connection["from_node"], connection["from_port"],
									   connection["to_node"], connection["to_port"])
			update_node_input(from_node, from_port, null)
			break

func _on_connection_drag_ended() -> void:
	# Connection drag ended - either connected to something or released to empty space
	print("Connection drag ended")

	# Reset grabbed state
	grabbed_from_node = ""
	grabbed_from_port = -1
	grabbed_is_output = false
	grabbed_connection_was_existing = false
	grabbed_original_target = ""
	grabbed_original_target_port = -1

func _on_popup_request(position: Vector2) -> void:
	# This is called when right-clicking on empty space
	print("Popup requested at: ", position)

func _on_connection_to_empty(from_node: StringName, from_port: int, release_position: Vector2) -> void:
	# Called when dragging from a port and releasing on empty space
	# This is an alternative way to disconnect - drag the connection away
	print("Connection dragged to empty from ", from_node, ":", from_port)
	# Find and disconnect any connection from this port
	var connections = graph_edit.get_connection_list()
	for connection in connections:
		if connection["from_node"] == from_node and connection["from_port"] == from_port:
			graph_edit.disconnect_node(connection["from_node"], connection["from_port"],
									   connection["to_node"], connection["to_port"])
			update_node_input(connection["to_node"], connection["to_port"], null)
			print("Disconnected: ", from_node, ":", from_port, " -> ", connection["to_node"], ":", connection["to_port"])
			break

func _on_connection_from_empty(to_node: StringName, to_port: int, release_position: Vector2) -> void:
	# Called when dragging from empty space to a port (reverse direction)
	print("Connection dragged from empty to ", to_node, ":", to_port)
	# Find and disconnect any connection to this port
	var connections = graph_edit.get_connection_list()
	for connection in connections:
		if connection["to_node"] == to_node and connection["to_port"] == to_port:
			graph_edit.disconnect_node(connection["from_node"], connection["from_port"],
									   connection["to_node"], connection["to_port"])
			update_node_input(connection["to_node"], connection["to_port"], null)
			print("Disconnected: ", connection["from_node"], ":", connection["from_port"], " -> ", to_node, ":", to_port)
			break

func show_win_screen() -> void:
	win_screen.visible = true
