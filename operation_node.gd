extends GraphNode

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

@onready var equation_label: Label = $Equation

func _ready() -> void:
	# Set up slots: 2 inputs (left side) and 1 output (right side)
	print("OperationNode setup. Child count: ", get_child_count())
	for i in range(get_child_count()):
		print("  Child ", i, ": ", get_child(i).name if get_child(i) else "null")

	# Slot 0: Input A (left only)
	set_slot_enabled_left(0, true)
	set_slot_enabled_right(0, false)
	set_slot_type_left(0, 0)
	set_slot_color_left(0, Color.LIGHT_BLUE)

	# Slot 1: Input B (left only)
	set_slot_enabled_left(1, true)
	set_slot_enabled_right(1, false)
	set_slot_type_left(1, 0)
	set_slot_color_left(1, Color.LIGHT_BLUE)

	# Slot 2: Result/Output (right only)
	set_slot_enabled_left(2, false)
	set_slot_enabled_right(2, true)
	set_slot_type_right(2, 0)
	set_slot_color_right(2, Color.LIGHT_GREEN)

	update_display()

func set_operation(op: Operation) -> void:
	operation = op
	update_display()

func set_input_a(value: Variant) -> void:
	input_a = value
	calculate()
	update_display()

func set_input_b(value: Variant) -> void:
	input_b = value
	calculate()
	update_display()

func clear_input_a() -> void:
	input_a = null
	calculate()
	update_display()

func clear_input_b() -> void:
	input_b = null
	calculate()
	update_display()

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
				result = null  # Division by zero

func get_result() -> Variant:
	return result

func update_display() -> void:
	# Don't update if label isn't ready yet
	if not equation_label:
		return

	var op_symbol := ""
	var op_name := ""

	match operation:
		Operation.ADD:
			op_symbol = "+"
			op_name = "Add"
		Operation.SUBTRACT:
			op_symbol = "-"
			op_name = "Subtract"
		Operation.MULTIPLY:
			op_symbol = "×"
			op_name = "Multiply"
		Operation.DIVIDE:
			op_symbol = "÷"
			op_name = "Divide"

	title = op_name

	# Format input A
	var input_a_str := "__"
	if input_a != null:
		if input_a is float:
			input_a_str = "%.2f" % input_a
		else:
			input_a_str = str(input_a)

	# Format input B
	var input_b_str := "__"
	if input_b != null:
		if input_b is float:
			input_b_str = "%.2f" % input_b
		else:
			input_b_str = str(input_b)

	# Format output - only show if both inputs are connected
	var output_str := "__"
	if result != null:
		if result is float:
			output_str = "%.2f" % result
		else:
			output_str = str(result)
	elif input_a != null and input_b != null and operation == Operation.DIVIDE and input_b == 0:
		output_str = "ERR"

	# Build the equation string
	equation_label.text = input_a_str + " " + op_symbol + " " + input_b_str + " = " + output_str
