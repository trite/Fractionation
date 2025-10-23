extends CustomGraphNode
class_name ExampleNumberNode

var value: int = 0

func _init(num_value: int = 0):
	value = num_value
	node_title = "Number: " + str(value)
	node_size = Vector2(100, 80)
	setup_ports()

func setup_ports() -> void:
	# Add output ports on the right side with 2 connections each
	for i in range(3):
		var y_offset = -20 + (i * 20)  # Spread ports vertically
		add_port("out_" + str(i), GraphPort.PortType.OUTPUT, GraphPort.PortSide.RIGHT, Vector2(50, y_offset), 2)

func get_value() -> int:
	return value

func _draw() -> void:
	super._draw()

	# Draw the value in the center
	var font = ThemeDB.fallback_font
	var font_size = 24
	var value_str = str(value)
	var string_size = font.get_string_size(value_str, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)

	draw_string(font, Vector2((node_size.x - string_size.x) / 2, node_size.y / 2 + 8),
				value_str, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0, 1, 0, 1))
