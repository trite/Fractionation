extends RefCounted
class_name GraphPort

enum PortType {
	INPUT,
	OUTPUT
}

enum PortSide {
	LEFT,
	TOP,
	RIGHT,
	BOTTOM
}

var port_name: String
var port_type: PortType
var port_side: PortSide
var local_position: Vector2  # Position relative to node center
var data_type: int = 0  # For type checking (0 = any)
var connections: Array = []  # Array of GraphConnection objects
var owner_node: CustomGraphNode = null
var max_connections: int = -1  # -1 = unlimited, otherwise max number of connections

# Visual properties
var radius: float = 10.0  # Visual size of the port circle
var click_radius: float = 16.0  # Larger hit area for easier clicking
var color: Color = Color.WHITE
var hover_color: Color = Color(1, 1, 1, 0.8)
var is_hovered: bool = false

func _init(name: String, type: PortType, side: PortSide, pos: Vector2):
	port_name = name
	port_type = type
	port_side = side
	local_position = pos

func get_world_position() -> Vector2:
	if owner_node:
		# local_position is relative to node center, so add node_size/2 to get world position
		return owner_node.position + owner_node.node_size / 2 + local_position
	return local_position

func can_connect_to(other: GraphPort) -> bool:
	# Can't connect to self
	if other == self:
		return false

	# Can't connect same type (input to input, output to output)
	if port_type == other.port_type:
		return false

	# Can't connect to same node
	if owner_node == other.owner_node:
		return false

	# Check data type compatibility (0 = any type)
	if data_type != 0 and other.data_type != 0 and data_type != other.data_type:
		return false

	# Check if this port has reached max connections
	if max_connections != -1 and connections.size() >= max_connections:
		return false

	# Check if other port has reached max connections
	if other.max_connections != -1 and other.connections.size() >= other.max_connections:
		return false

	# Validate that output port has a valid value (not nil)
	var output_port = self if port_type == PortType.OUTPUT else other
	var output_node = output_port.owner_node
	var output_value = null

	if output_node.has_method("get_value"):
		output_value = output_node.get_value()
	elif output_node.has_method("get_result"):
		output_value = output_node.get_result()

	# Reject connection if output is nil
	if output_value == null:
		return false

	return true

func has_available_connection_slot() -> bool:
	if max_connections == -1:
		return true
	return connections.size() < max_connections

func get_connection_count_text() -> String:
	if max_connections == -1:
		return ""
	return str(connections.size()) + "/" + str(max_connections)

func is_point_inside(point: Vector2) -> bool:
	return get_world_position().distance_to(point) <= click_radius

func add_connection(connection) -> void:  # Takes GraphConnection
	connections.append(connection)
	# Trigger redraw of owner node to update connection count display
	if owner_node:
		owner_node.queue_redraw()

func remove_connection(connection) -> void:  # Takes GraphConnection
	connections.erase(connection)
	# Trigger redraw of owner node to update connection count display
	if owner_node:
		owner_node.queue_redraw()

func clear_connections() -> void:
	connections.clear()

func get_connected_ports() -> Array[GraphPort]:
	# Get unique list of ports this port is connected to (for value propagation)
	var ports: Array[GraphPort] = []
	for conn in connections:
		var other_port = conn.to_port if conn.from_port == self else conn.from_port
		if not other_port in ports:
			ports.append(other_port)
	return ports
