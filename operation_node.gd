extends GraphNode

enum Operation {
	ADD,
	SUBTRACT,
	MULTIPLY,
	DIVIDE
}

# Port configuration - defines logical port mapping
const PORT_INPUT_A: int = 0
const PORT_INPUT_B: int = 1
const PORT_OUTPUT: int = 3

var operation: Operation = Operation.ADD
var input_a: Variant = null
var input_b: Variant = null
var result: Variant = null

@onready var input_x_label: Label = $InputX
@onready var input_y_label: Label = $InputY
@onready var output_label: Label = $Output

func _ready() -> void:
	# Slot 0: Input X (left only)
	set_slot_enabled_left(PORT_INPUT_A, true)
	set_slot_enabled_right(PORT_INPUT_A, false)
	set_slot_type_left(PORT_INPUT_A, 0)
	set_slot_color_left(PORT_INPUT_A, Color.LIGHT_BLUE)

	# Slot 1: Input Y (left only)
	set_slot_enabled_left(PORT_INPUT_B, true)
	set_slot_enabled_right(PORT_INPUT_B, false)
	set_slot_type_left(PORT_INPUT_B, 0)
	set_slot_color_left(PORT_INPUT_B, Color.LIGHT_BLUE)

	# Slot 2: HSeparator (no connections)
	set_slot_enabled_left(2, false)
	set_slot_enabled_right(2, false)

	# Slot 3: Output (right only)
	set_slot_enabled_left(PORT_OUTPUT, false)
	set_slot_enabled_right(PORT_OUTPUT, true)
	set_slot_type_right(PORT_OUTPUT, 0)
	set_slot_color_right(PORT_OUTPUT, Color.LIGHT_GREEN)

	update_display()

# Helper method to handle input updates by port
func handle_input_update(port: int, value: Variant) -> void:
	if port == PORT_INPUT_A:
		if value != null:
			set_input_a(value)
		else:
			clear_input_a()
	elif port == PORT_INPUT_B:
		if value != null:
			set_input_b(value)
		else:
			clear_input_b()

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
	if not input_x_label or not input_y_label or not output_label:
		return

	var op_name := ""

	match operation:
		Operation.ADD:
			op_name = "Add"
		Operation.SUBTRACT:
			op_name = "Subtract"
		Operation.MULTIPLY:
			op_name = "Multiply"
		Operation.DIVIDE:
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

	# Update labels
	input_x_label.text = "X: " + input_a_str
	input_y_label.text = "Y: " + input_b_str
	output_label.text = output_str
