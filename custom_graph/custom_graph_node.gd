extends Node2D
class_name CustomGraphNode

signal node_moved(node: CustomGraphNode)
signal port_clicked(port: GraphPort)
signal rotation_changed(node: CustomGraphNode)

var node_title: String = "Node"
var ports: Array[GraphPort] = []
var node_rotation_degrees: float = 0.0

# Drag state
var is_being_dragged: bool = false
var drag_offset: Vector2 = Vector2.ZERO

# Visual properties
var node_size: Vector2 = Vector2(120, 80)
var background_color: Color = Color(0.1, 0.1, 0.1, 0.9)
var border_color: Color = Color(0, 1, 0, 1)
var border_width: float = 2.0
var title_color: Color = Color(0, 1, 0, 1)
var is_selected: bool = false

func _ready() -> void:
	pass  # Node2D doesn't need mouse_filter or custom_minimum_size

func add_port(port_name: String, port_type: GraphPort.PortType, port_side: GraphPort.PortSide, offset: Vector2 = Vector2.ZERO, max_connections: int = -1) -> GraphPort:
	var port = GraphPort.new(port_name, port_type, port_side, offset)
	port.owner_node = self
	port.max_connections = max_connections

	# Set color based on type
	if port_type == GraphPort.PortType.INPUT:
		port.color = Color(0.3, 0.6, 1.0)  # Blue for inputs
	else:
		port.color = Color(0.3, 1.0, 0.3)  # Green for outputs

	ports.append(port)
	return port

func get_port_at_position(pos: Vector2) -> GraphPort:
	for port in ports:
		if port.is_point_inside(pos):
			return port
	return null

func rotate_node(degrees: float) -> void:
	node_rotation_degrees = fmod(node_rotation_degrees + degrees, 360.0)

	# Rotate all port positions around center
	for port in ports:
		var angle_rad = deg_to_rad(degrees)
		var rotated = port.local_position.rotated(angle_rad)
		port.local_position = rotated

		# Update port side based on new angle
		var total_rotation = deg_to_rad(node_rotation_degrees)
		var angle = atan2(port.local_position.y, port.local_position.x) + total_rotation
		angle = fmod(angle + TAU, TAU)

		# Determine new side based on angle
		if angle >= TAU * 7.0/8.0 or angle < TAU * 1.0/8.0:
			port.port_side = GraphPort.PortSide.RIGHT
		elif angle >= TAU * 1.0/8.0 and angle < TAU * 3.0/8.0:
			port.port_side = GraphPort.PortSide.BOTTOM
		elif angle >= TAU * 3.0/8.0 and angle < TAU * 5.0/8.0:
			port.port_side = GraphPort.PortSide.LEFT
		else:
			port.port_side = GraphPort.PortSide.TOP

	rotation_changed.emit(self)
	queue_redraw()

func start_drag(local_click_pos: Vector2) -> void:
	is_being_dragged = true
	drag_offset = local_click_pos

func stop_drag() -> void:
	is_being_dragged = false

func update_drag(relative_motion: Vector2) -> void:
	if is_being_dragged:
		position += relative_motion
		node_moved.emit(self)
		queue_redraw()

func is_point_inside_node(world_pos: Vector2) -> bool:
	var local_pos = world_pos - position
	return Rect2(Vector2.ZERO, node_size).has_point(local_pos)

func _draw() -> void:
	# Draw node background
	draw_rect(Rect2(Vector2.ZERO, node_size), background_color, true)

	# Draw border
	draw_rect(Rect2(Vector2.ZERO, node_size), border_color, false, border_width)

	# Draw title (centered)
	var font = ThemeDB.fallback_font
	var font_size = 14
	var title_size = font.get_string_size(node_title, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	draw_string(font, Vector2((node_size.x - title_size.x) / 2, 20), node_title, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, title_color)

	# Draw ports and their connection counts
	for port in ports:
		var port_pos = port.local_position + node_size / 2
		var port_color = port.hover_color if port.is_hovered else port.color

		# Dim the color if port is at max connections
		if port.max_connections != -1 and port.connections.size() >= port.max_connections:
			port_color = port_color * Color(0.5, 0.5, 0.5, 1.0)

		draw_circle(port_pos, port.radius, port_color)

		# Draw port outline
		draw_arc(port_pos, port.radius, 0, TAU, 32, Color.WHITE, 1.0)

		# Draw connection count next to the port (inside node bounds)
		if port.max_connections != -1:
			var count_text = port.get_connection_count_text()
			var text_size = font.get_string_size(count_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10)
			var text_offset = Vector2.ZERO

			# Position text based on port side (inside the node)
			match port.port_side:
				GraphPort.PortSide.RIGHT:
					# Place to the left of the port (inside node)
					text_offset = Vector2(-port.radius - text_size.x - 5, 4)
				GraphPort.PortSide.LEFT:
					# Place to the right of the port (inside node)
					text_offset = Vector2(port.radius + 5, 4)
				GraphPort.PortSide.TOP:
					# Place below the port (inside node)
					text_offset = Vector2(-text_size.x / 2, port.radius + 12)
				GraphPort.PortSide.BOTTOM:
					# Place above the port (inside node)
					text_offset = Vector2(-text_size.x / 2, -port.radius - 5)

			draw_string(font, port_pos + text_offset, count_text,
						HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.7, 0.7, 0.7))
