extends Control

@onready var graph_edit: GraphEdit = $GraphEdit
@onready var add_button: Button = $ToolPanel/MarginContainer/HBoxContainer/AddButton
@onready var subtract_button: Button = $ToolPanel/MarginContainer/HBoxContainer/SubtractButton
@onready var multiply_button: Button = $ToolPanel/MarginContainer/HBoxContainer/MultiplyButton
@onready var divide_button: Button = $ToolPanel/MarginContainer/HBoxContainer/DivideButton

# Track which nodes are starting nodes (cannot be deleted)
var starting_nodes: Array[String] = []
var node_counter: int = 0

func _ready() -> void:
	# Connect GraphEdit signals
	graph_edit.connection_request.connect(_on_connection_request)
	graph_edit.disconnection_request.connect(_on_disconnection_request)
	graph_edit.delete_nodes_request.connect(_on_delete_nodes_request)

	# Connect button signals
	add_button.pressed.connect(_on_add_button_pressed)
	subtract_button.pressed.connect(_on_subtract_button_pressed)
	multiply_button.pressed.connect(_on_multiply_button_pressed)
	divide_button.pressed.connect(_on_divide_button_pressed)

	# Create the two starting nodes
	create_starting_nodes()

func create_starting_nodes() -> void:
	# Create node with value 1
	var node1 = create_number_node("node_1", 1, Vector2(100, 100))
	starting_nodes.append("node_1")

	# Create node with value 5
	var node5 = create_number_node("node_5", 5, Vector2(400, 100))
	starting_nodes.append("node_5")

func create_number_node(node_name: String, value: int, position: Vector2) -> GraphNode:
	var node = preload("res://number_node.tscn").instantiate()
	node.name = node_name
	node.position_offset = position
	node.set_value(value)
	graph_edit.add_child(node)
	return node

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

func _on_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	graph_edit.disconnect_node(from_node, from_port, to_node, to_port)
	# Clear the input on the target node
	update_node_input(to_node, to_port, null)

func _on_delete_nodes_request(nodes: Array[StringName]) -> void:
	for node_name in nodes:
		# Prevent deletion of starting nodes
		if node_name in starting_nodes:
			print("Cannot delete starting node: ", node_name)
			continue

		# Get the node and remove it
		var node = graph_edit.get_node(NodePath(node_name))
		if node:
			node.queue_free()

func create_operation_node(operation: int) -> void:
	var node = preload("res://operation_node.tscn").instantiate()
	node.name = "operation_" + str(node_counter)
	node_counter += 1

	# Position new nodes in the center of the viewport with some offset
	var scroll_offset = graph_edit.scroll_offset
	var viewport_center = graph_edit.size / 2
	var spawn_position = scroll_offset + viewport_center / graph_edit.zoom
	spawn_position += Vector2(randf_range(-50, 50), randf_range(-50, 50))  # Add random offset

	node.position_offset = spawn_position
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

	# Update the appropriate input based on the port
	if node.has_method("set_input_a") and node.has_method("set_input_b"):
		if port == 0:
			if value != null:
				node.set_input_a(value)
			else:
				node.clear_input_a()
		elif port == 1:
			if value != null:
				node.set_input_b(value)
			else:
				node.clear_input_b()

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
