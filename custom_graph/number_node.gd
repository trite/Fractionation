extends CustomGraphNode
class_name NumberNode

var value: int = 0
var is_starting_node: bool = false  # Starting nodes can't be deleted

func _init(num_value: int = 0, is_starter: bool = false):
	value = num_value
	is_starting_node = is_starter
	node_title = str(value)
	node_size = Vector2(100, 80)

	# Set colors for starting nodes
	if is_starting_node:
		border_color = Color(0, 1, 0, 1)
		title_color = Color(0, 1, 0, 1)

	setup_ports()

func setup_ports() -> void:
	# Add single output port on the right side with 10 connections max
	add_port("output", GraphPort.PortType.OUTPUT, GraphPort.PortSide.RIGHT, Vector2(50, 0), 10)

func get_value() -> int:
	return value

func _draw() -> void:
	super._draw()

	# Draw the value in the center
	var font = ThemeDB.fallback_font
	var font_size = 32
	var value_str = str(value)
	var string_size = font.get_string_size(value_str, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)

	draw_string(font, Vector2((node_size.x - string_size.x) / 2, node_size.y / 2 + 12),
				value_str, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0, 1, 0, 1))
