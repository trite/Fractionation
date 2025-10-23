extends Control

@onready var graph_view: CustomGraphView = $CustomGraphView
@onready var instructions_label: Label = $InstructionsPanel/InstructionsLabel
@onready var add_number_button: Button = $ToolPanel/AddNumberButton
@onready var add_operation_button: Button = $ToolPanel/AddOperationButton

var next_number_value: int = 10

func _ready() -> void:
	# Create some initial example nodes
	create_initial_nodes()

	# Update instructions
	instructions_label.text = """CUSTOM GRAPH TEST SCENE

CONNECTIONS:
• Click/drag ports to connect
• Click connections to break them

NODE MANIPULATION:
• Left-click drag to move nodes
• Press F while dragging to auto-connect
  to nearest compatible port
• Press G while dragging to auto-disconnect
  (reverse order from F)
• Press R while dragging to rotate
  node 45° (ports stay connected)

CAMERA:
• Mouse wheel to zoom

Buttons spawn nodes at center"""

func create_initial_nodes() -> void:
	# Create two number nodes
	var num_node_1 = ExampleNumberNode.new(5)
	num_node_1.position = Vector2(200, 200)
	graph_view.add_node(num_node_1)

	var num_node_2 = ExampleNumberNode.new(10)
	num_node_2.position = Vector2(200, 400)
	graph_view.add_node(num_node_2)

	# Create an operation node
	var add_node = ExampleOperationNode.new(ExampleOperationNode.Operation.ADD)
	add_node.position = Vector2(500, 300)
	graph_view.add_node(add_node)

	# Create another operation node
	var multiply_node = ExampleOperationNode.new(ExampleOperationNode.Operation.MULTIPLY)
	multiply_node.position = Vector2(800, 300)
	graph_view.add_node(multiply_node)

func _on_add_number_button_pressed() -> void:
	var num_node = ExampleNumberNode.new(next_number_value)
	num_node.position = graph_view.size / 2 + graph_view.pan_offset
	graph_view.add_node(num_node)
	next_number_value += 5

func _on_add_operation_button_pressed() -> void:
	# Cycle through operation types
	var operations = [
		ExampleOperationNode.Operation.ADD,
		ExampleOperationNode.Operation.SUBTRACT,
		ExampleOperationNode.Operation.MULTIPLY,
		ExampleOperationNode.Operation.DIVIDE
	]
	var random_op = operations[randi() % operations.size()]

	var op_node = ExampleOperationNode.new(random_op)
	op_node.position = graph_view.size / 2 + graph_view.pan_offset
	graph_view.add_node(op_node)

func _on_connection_created(connection: GraphConnection) -> void:
	print("Connection created: ", connection.from_port.port_name, " -> ", connection.to_port.port_name)

func _on_connection_removed(connection: GraphConnection) -> void:
	print("Connection removed: ", connection.from_port.port_name, " -> ", connection.to_port.port_name)
