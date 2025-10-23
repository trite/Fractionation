extends CustomGraphNode
class_name OperationNode

enum Operation {
	ADD,
	SUBTRACT,
	MULTIPLY,
	DIVIDE
}

var operation: Operation = Operation.ADD
var result: Variant = null
var input_port: GraphPort = null  # Reference to our input port

func _init(op: Operation = Operation.ADD):
	operation = op
	update_title()
	node_size = Vector2(120, 100)
	setup_ports()

func setup_ports() -> void:
	# Add single input port on the left side (max 2 connections)
	input_port = add_port("input", GraphPort.PortType.INPUT, GraphPort.PortSide.LEFT, Vector2(-60, 0), 2)

	# Add output port on the right side with 1 connection max
	add_port("output", GraphPort.PortType.OUTPUT, GraphPort.PortSide.RIGHT, Vector2(60, 0), 1)

func update_title() -> void:
	match operation:
		Operation.ADD:
			node_title = "Add"
		Operation.SUBTRACT:
			node_title = "Subtract"
		Operation.MULTIPLY:
			node_title = "Multiply"
		Operation.DIVIDE:
			node_title = "Divide"

func set_input_from(from_port: GraphPort, value: Variant) -> void:
	# Just recalculate - we read directly from connections now
	calculate()
	queue_redraw()

func clear_input_from(from_port: GraphPort) -> void:
	# Just recalculate - we read directly from connections now
	calculate()
	queue_redraw()

# Legacy methods for backwards compatibility
func set_input_a(value: Variant) -> void:
	calculate()
	queue_redraw()

func set_input_b(value: Variant) -> void:
	calculate()
	queue_redraw()

func clear_input_a() -> void:
	calculate()
	queue_redraw()

func clear_input_b() -> void:
	calculate()
	queue_redraw()

func calculate() -> void:
	# Get values directly from input port connections
	if not input_port or input_port.connections.size() < 2:
		result = null
		return

	var values: Array = []

	# Get value from each connection
	for connection in input_port.connections:
		var output_port = connection.from_port
		var output_node = output_port.owner_node
		var value = null

		if output_node.has_method("get_value"):
			value = output_node.get_value()
		elif output_node.has_method("get_result"):
			value = output_node.get_result()

		values.append(value)

	if values.size() < 2:
		result = null
		return

	var input_a = values[0]
	var input_b = values[1]

	# Check for nil inputs - can't calculate with nil values
	if input_a == null or input_b == null:
		result = null
		return

	match operation:
		Operation.ADD:
			result = input_a + input_b
		Operation.SUBTRACT:
			result = input_a - input_b
		Operation.MULTIPLY:
			result = input_a * input_b
		Operation.DIVIDE:
			if input_b != 0:
				result = float(input_a) / float(input_b)
			else:
				result = null

func get_result() -> Variant:
	return result

func _draw() -> void:
	super._draw()

	# Draw the operation equation (centered)
	var font = ThemeDB.fallback_font
	var font_size = 12

	# Get input values directly from connections
	var values: Array = []
	if input_port:
		for connection in input_port.connections:
			var output_port = connection.from_port
			var output_node = output_port.owner_node
			var value = null

			if output_node.has_method("get_value"):
				value = output_node.get_value()
			elif output_node.has_method("get_result"):
				value = output_node.get_result()

			values.append(value)

	var a_str = str(values[0]) if values.size() > 0 else "__"
	var b_str = str(values[1]) if values.size() > 1 else "__"

	# Center the text lines
	var x_line = "X: " + a_str
	var y_line = "Y: " + b_str
	var x_size = font.get_string_size(x_line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var y_size = font.get_string_size(y_line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)

	draw_string(font, Vector2((node_size.x - x_size.x) / 2, 45), x_line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.7, 0.7, 1))
	draw_string(font, Vector2((node_size.x - y_size.x) / 2, 60), y_line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.7, 0.7, 1))

	# Draw horizontal line
	draw_line(Vector2(5, 65), Vector2(node_size.x - 5, 65), Color(0, 1, 0, 0.5), 1.0)

	# Show result (centered)
	var result_str = ""
	if result != null:
		if result is float:
			result_str = "%.1f" % result
		else:
			result_str = str(result)
	else:
		result_str = "__"

	var result_line = "= " + result_str
	var result_size = font.get_string_size(result_line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	draw_string(font, Vector2((node_size.x - result_size.x) / 2, 80), result_line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.3, 1, 0.3))
