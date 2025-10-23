extends Control

@onready var graph_edit: GraphEdit = $GraphEdit

# Track which nodes are starting nodes (cannot be deleted)
var starting_nodes: Array[String] = []

func _ready() -> void:
	# Connect GraphEdit signals
	graph_edit.connection_request.connect(_on_connection_request)
	graph_edit.disconnection_request.connect(_on_disconnection_request)
	graph_edit.delete_nodes_request.connect(_on_delete_nodes_request)

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
	# Check if the target port already has a connection
	var existing_connections = graph_edit.get_connection_list()

	for connection in existing_connections:
		# If there's already a connection to this input port, disconnect it first
		if connection["to_node"] == to_node and connection["to_port"] == to_port:
			graph_edit.disconnect_node(connection["from_node"], connection["from_port"],
									   connection["to_node"], connection["to_port"])

	# Create the new connection
	graph_edit.connect_node(from_node, from_port, to_node, to_port)

func _on_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	graph_edit.disconnect_node(from_node, from_port, to_node, to_port)

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
