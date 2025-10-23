extends CustomGraphNode
class_name DuplicatorNode

var input_value: Variant = null

func _init():
	node_title = "Duplicate"
	node_size = Vector2(120, 100)
	title_color = Color(1, 0.5, 0, 1)  # Orange title
	border_color = Color(1, 0.5, 0, 1)
	setup_ports()

func setup_ports() -> void:
	# Add single input port on the left side (max 1 connection)
	add_port("input", GraphPort.PortType.INPUT, GraphPort.PortSide.LEFT, Vector2(-60, 0), 1)

	# Add two output ports on the right side (1 connection each = 2 total)
	add_port("output_1", GraphPort.PortType.OUTPUT, GraphPort.PortSide.RIGHT, Vector2(60, -15), 1)
	add_port("output_2", GraphPort.PortType.OUTPUT, GraphPort.PortSide.RIGHT, Vector2(60, 15), 1)

func set_input_value(value: Variant) -> void:
	input_value = value
	queue_redraw()

func clear_input_value() -> void:
	input_value = null
	queue_redraw()

func get_result() -> Variant:
	return input_value

func _draw() -> void:
	super._draw()

	# Draw the current value
	var font = ThemeDB.fallback_font
	var font_size = 14

	var value_str = ""
	if input_value != null:
		if input_value is float:
			value_str = "%.1f" % input_value
		else:
			value_str = str(input_value)
	else:
		value_str = "__"

	# Center the value
	var string_size = font.get_string_size(value_str, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	draw_string(font, Vector2((node_size.x - string_size.x) / 2, node_size.y / 2 + 8),
				value_str, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(1, 0.7, 0.3))
