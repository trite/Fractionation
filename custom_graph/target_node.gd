extends CustomGraphNode
class_name TargetNode

var target_value: Variant = 0
var current_value: Variant = null
var is_correct: bool = false

func _init(target_val: Variant = 0):
	target_value = target_val
	node_title = "Target"
	node_size = Vector2(120, 80)
	title_color = Color(1, 1, 0, 1)  # Yellow title
	border_color = Color(1, 1, 0, 1)
	setup_ports()

func setup_ports() -> void:
	# Add single input port on the left side (max 1 connection)
	add_port("input", GraphPort.PortType.INPUT, GraphPort.PortSide.LEFT, Vector2(-60, 0), 1)

func set_input_value(value: Variant) -> void:
	current_value = value
	check_correctness()
	queue_redraw()

func clear_input_value() -> void:
	current_value = null
	is_correct = false
	queue_redraw()

func check_correctness() -> void:
	if current_value == null:
		is_correct = false
		return

	# Handle float to int comparison
	if current_value is float and target_value is int:
		is_correct = abs(current_value - target_value) < 0.01
	elif current_value is int and target_value is int:
		is_correct = (current_value == target_value)
	else:
		is_correct = (current_value == target_value)

func _draw() -> void:
	super._draw()

	# Draw the target value and status (centered)
	var font = ThemeDB.fallback_font
	var font_size = 14

	var value_str = ""
	if current_value != null:
		if current_value is float:
			value_str = "%.1f" % current_value
		else:
			value_str = str(current_value)
	else:
		value_str = "__"

	# Change color and text based on correctness
	var display_color: Color
	var status_symbol: String

	if is_correct:
		display_color = Color(0.5, 1.0, 0.5)
		status_symbol = "✓"
		# Tint the whole node green
		modulate = Color(0.7, 1.0, 0.7)
	elif current_value != null:
		display_color = Color(1.0, 0.5, 0.5)
		status_symbol = "✗"
		# Tint the whole node red
		modulate = Color(1.0, 0.7, 0.7)
	else:
		display_color = Color(0.7, 0.7, 0.7)
		status_symbol = ""
		# Default color
		modulate = Color(1.0, 1.0, 1.0)

	# Draw current value (centered)
	var value_size = font.get_string_size(value_str, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	draw_string(font, Vector2((node_size.x - value_size.x) / 2, 45), value_str, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, display_color)

	# Draw target value (centered)
	var target_line = "Target: " + str(target_value)
	var target_size = font.get_string_size(target_line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	draw_string(font, Vector2((node_size.x - target_size.x) / 2, 65), target_line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(1, 1, 0))

	# Draw status symbol if applicable (right side)
	if status_symbol != "":
		draw_string(font, Vector2(node_size.x - 25, 45), status_symbol, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, display_color)
