extends RefCounted
class_name GraphConnection

var from_port: GraphPort
var to_port: GraphPort
var connection_id: int

# Visual properties
var color: Color = Color(0, 1, 0, 1)
var hover_color: Color = Color(1, 1, 1, 1)
var thickness: float = 3.0
var is_hovered: bool = false

# Bezier curve parameters
var curve_strength: float = 80.0

func _init(from: GraphPort, to: GraphPort, id: int):
	from_port = from
	to_port = to
	connection_id = id

	# Establish bidirectional connection by adding this connection object to both ports
	from_port.add_connection(self)
	to_port.add_connection(self)

func disconnect_ports() -> void:
	from_port.remove_connection(self)
	to_port.remove_connection(self)

func get_bezier_points() -> PackedVector2Array:
	var from_pos = from_port.get_world_position()
	var to_pos = to_port.get_world_position()

	# Find all connections between the same two ports
	var sibling_connections: Array = []
	for conn in from_port.connections:
		if (conn.from_port == from_port and conn.to_port == to_port) or \
		   (conn.from_port == to_port and conn.to_port == from_port):
			sibling_connections.append(conn)

	# Calculate offset if there are multiple connections
	var offset = Vector2.ZERO
	if sibling_connections.size() > 1:
		# Find this connection's index
		var my_index = sibling_connections.find(self)

		# Calculate perpendicular offset
		var direction = (to_pos - from_pos).normalized()
		var perpendicular = Vector2(-direction.y, direction.x)

		# Spread connections evenly, centered around the main line
		var spacing = 15.0  # pixels between connections
		var total_width = (sibling_connections.size() - 1) * spacing
		var my_offset = (my_index * spacing) - (total_width / 2.0)
		offset = perpendicular * my_offset

	# Apply offset to start and end positions
	from_pos += offset
	to_pos += offset

	# Calculate control points based on port sides
	var from_tangent = _get_tangent_direction(from_port)
	var to_tangent = _get_tangent_direction(to_port)

	var from_control = from_pos + from_tangent * curve_strength
	var to_control = to_pos + to_tangent * curve_strength

	# Generate bezier curve points
	var points: PackedVector2Array = []
	var steps = 50

	for i in range(steps + 1):
		var t = float(i) / float(steps)
		var point = _cubic_bezier(from_pos, from_control, to_control, to_pos, t)
		points.append(point)

	return points

func _get_tangent_direction(port: GraphPort) -> Vector2:
	# Return direction based on which side of the node the port is on
	match port.port_side:
		GraphPort.PortSide.LEFT:
			return Vector2(-1, 0)
		GraphPort.PortSide.RIGHT:
			return Vector2(1, 0)
		GraphPort.PortSide.TOP:
			return Vector2(0, -1)
		GraphPort.PortSide.BOTTOM:
			return Vector2(0, 1)
	return Vector2(1, 0)  # Default

func _cubic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var q0 = p0.lerp(p1, t)
	var q1 = p1.lerp(p2, t)
	var q2 = p2.lerp(p3, t)

	var r0 = q0.lerp(q1, t)
	var r1 = q1.lerp(q2, t)

	return r0.lerp(r1, t)

func is_point_near_curve(point: Vector2, threshold: float = 10.0) -> bool:
	var curve_points = get_bezier_points()

	for i in range(curve_points.size() - 1):
		var segment_start = curve_points[i]
		var segment_end = curve_points[i + 1]

		# Check distance to line segment
		var distance = _point_to_segment_distance(point, segment_start, segment_end)
		if distance <= threshold:
			return true

	return false

func _point_to_segment_distance(point: Vector2, seg_start: Vector2, seg_end: Vector2) -> float:
	var segment = seg_end - seg_start
	var length_squared = segment.length_squared()

	if length_squared == 0:
		return point.distance_to(seg_start)

	var t = ((point - seg_start).dot(segment)) / length_squared
	t = clamp(t, 0.0, 1.0)

	var projection = seg_start + t * segment
	return point.distance_to(projection)

func draw_on_canvas(canvas: CanvasItem) -> void:
	var points = get_bezier_points()
	var draw_color = hover_color if is_hovered else color

	# Draw the bezier curve
	for i in range(points.size() - 1):
		canvas.draw_line(points[i], points[i + 1], draw_color, thickness, true)
