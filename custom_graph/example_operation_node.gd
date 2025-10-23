extends CustomGraphNode
class_name ExampleOperationNode

enum Operation {
	ADD,
	SUBTRACT,
	MULTIPLY,
	DIVIDE
}

var operation: Operation = Operation.ADD
var input_a: Variant = null
var input_b: Variant = null
var result: Variant = null

func _init(op: Operation = Operation.ADD):
	operation = op
	update_title()
	node_size = Vector2(100, 100)
	setup_ports()

func setup_ports() -> void:
	# Add input ports on the left side (max 1 connection each)
	add_port("input_a", GraphPort.PortType.INPUT, GraphPort.PortSide.LEFT, Vector2(-50, -15), 1)
	add_port("input_b", GraphPort.PortType.INPUT, GraphPort.PortSide.LEFT, Vector2(-50, 15), 1)

	# Add output port on the right side (max 2 connections)
	add_port("output", GraphPort.PortType.OUTPUT, GraphPort.PortSide.RIGHT, Vector2(50, 0), 2)

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

func set_input_a(value: Variant) -> void:
	input_a = value
	calculate()
	queue_redraw()

func set_input_b(value: Variant) -> void:
	input_b = value
	calculate()
	queue_redraw()

func calculate() -> void:
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

	# Draw the operation and result
	var font = ThemeDB.fallback_font
	var font_size = 12

	# Show inputs
	var a_str = str(input_a) if input_a != null else "__"
	var b_str = str(input_b) if input_b != null else "__"

	draw_string(font, Vector2(10, 40), "A: " + a_str, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.7, 0.7, 1))
	draw_string(font, Vector2(10, 55), "B: " + b_str, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.7, 0.7, 1))

	# Show result
	var result_str = ""
	if result != null:
		if result is float:
			result_str = "%.1f" % result
		else:
			result_str = str(result)
	else:
		result_str = "__"

	draw_string(font, Vector2(10, 75), "= " + result_str, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.3, 1, 0.3))
