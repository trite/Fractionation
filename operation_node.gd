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

@onready var input1_label: Label = $Input1
@onready var input2_label: Label = $Input2
@onready var result_label: Label = $Result

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

	# Slot 3: Result/Output (right only)
	set_slot_enabled_left(3, false)
	set_slot_enabled_right(3, true)
	set_slot_type_right(3, 0)
	set_slot_color_right(3, Color.LIGHT_GREEN)

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
	# Don't update if labels aren't ready yet
	if not input1_label or not input2_label or not result_label:
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

	if input_a != null:
		input1_label.text = "Input A: " + str(input_a)
	else:
		input1_label.text = "Input A: -"

	if input_b != null:
		input2_label.text = "Input B: " + str(input_b)
	else:
		input2_label.text = "Input B: -"

	if result != null:
		# Format the result nicely
		if result is float:
			result_label.text = "Result: %.2f" % result
		else:
			result_label.text = "Result: " + str(result)
	else:
		if input_a != null and input_b != null and operation == Operation.DIVIDE and input_b == 0:
			result_label.text = "Result: Error (÷0)"
		else:
			result_label.text = "Result: -"
