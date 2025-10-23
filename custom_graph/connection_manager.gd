extends RefCounted
class_name ConnectionManager

signal connection_created(connection: GraphConnection)
signal connection_removed(connection: GraphConnection)

# Connection storage
var connections: Array[GraphConnection] = []
var connection_id_counter: int = 0

# Validation settings
var allow_circular_references: bool = false
var allow_nil_outputs: bool = false

func create_connection(from_port: GraphPort, to_port: GraphPort) -> GraphConnection:
	# Validate the connection request
	var validation_result = validate_connection(from_port, to_port)
	if not validation_result.valid:
		print("Connection rejected: ", validation_result.reason)
		return null

	# Ensure correct direction (output -> input)
	var output_port = from_port if from_port.port_type == GraphPort.PortType.OUTPUT else to_port
	var input_port = to_port if from_port.port_type == GraphPort.PortType.OUTPUT else from_port

	# Create the connection
	var connection = GraphConnection.new(output_port, input_port, connection_id_counter)
	connection_id_counter += 1
	connections.append(connection)

	# Propagate value through the new connection
	propagate_value(output_port, input_port)

	connection_created.emit(connection)
	return connection

func validate_connection(from_port: GraphPort, to_port: GraphPort) -> Dictionary:
	# Returns {valid: bool, reason: String}

	# Basic validation - use existing port logic
	if not from_port.can_connect_to(to_port):
		return {
			"valid": false,
			"reason": "Ports cannot connect (check port compatibility, max connections, or nil output)"
		}

	# Ensure correct direction
	var output_port = from_port if from_port.port_type == GraphPort.PortType.OUTPUT else to_port
	var input_port = to_port if from_port.port_type == GraphPort.PortType.OUTPUT else from_port

	# Check for circular references
	if not allow_circular_references:
		if would_create_cycle(output_port, input_port):
			return {
				"valid": false,
				"reason": "Connection would create a circular reference"
			}

	return {"valid": true, "reason": ""}

func would_create_cycle(output_port: GraphPort, input_port: GraphPort) -> bool:
	# Check if connecting output_port to input_port would create a cycle
	# This happens if there's already a path from input_port's node to output_port's node

	var input_node = input_port.owner_node
	var output_node = output_port.owner_node

	# If they're the same node, it's definitely a cycle (though port validation should catch this)
	if input_node == output_node:
		return true

	# Use BFS to check if there's a path from input_node to output_node
	var visited_nodes = {}
	var queue: Array = [input_node]

	while not queue.is_empty():
		var current_node = queue.pop_front()

		# Skip if already visited
		if current_node in visited_nodes:
			continue

		visited_nodes[current_node] = true

		# If we reached the output node, there's a path (cycle would be created)
		if current_node == output_node:
			return true

		# Add all downstream nodes to the queue
		for port in current_node.ports:
			if port.port_type == GraphPort.PortType.OUTPUT:
				for connected_port in port.get_connected_ports():
					var next_node = connected_port.owner_node
					if not next_node in visited_nodes:
						queue.append(next_node)

	return false

func remove_connection(connection: GraphConnection) -> void:
	if connection not in connections:
		print("Warning: Trying to remove connection that doesn't exist")
		return

	# Clear the value at the input before disconnecting
	clear_input_value(connection.to_port, connection.from_port)

	# Disconnect from ports
	connection.disconnect_ports()

	# Remove from our list
	connections.erase(connection)

	connection_removed.emit(connection)

func propagate_value(output_port: GraphPort, input_port: GraphPort) -> void:
	# Get the value from the output node
	var output_node = output_port.owner_node
	var value: Variant = null

	if output_node.has_method("get_value"):
		value = output_node.get_value()
	elif output_node.has_method("get_result"):
		value = output_node.get_result()

	# Set the value at the input node
	set_input_value(input_port, value, output_port)

func set_input_value(input_port: GraphPort, value: Variant, from_port: GraphPort) -> void:
	var input_node = input_port.owner_node

	# Try new method first (for operation nodes with source port tracking)
	if input_node.has_method("set_input_from"):
		input_node.set_input_from(from_port, value)
		# Propagate to downstream connections
		for port in input_node.ports:
			if port.port_type == GraphPort.PortType.OUTPUT:
				for connected_port in port.get_connected_ports():
					propagate_value(port, connected_port)

	# Fall back to old methods for backward compatibility
	elif input_port.port_name == "input_a" and input_node.has_method("set_input_a"):
		input_node.set_input_a(value)
		for port in input_node.ports:
			if port.port_type == GraphPort.PortType.OUTPUT:
				for connected_port in port.get_connected_ports():
					propagate_value(port, connected_port)

	elif input_port.port_name == "input_b" and input_node.has_method("set_input_b"):
		input_node.set_input_b(value)
		for port in input_node.ports:
			if port.port_type == GraphPort.PortType.OUTPUT:
				for connected_port in port.get_connected_ports():
					propagate_value(port, connected_port)

	elif input_node.has_method("set_input_value"):
		input_node.set_input_value(value)
		for port in input_node.ports:
			if port.port_type == GraphPort.PortType.OUTPUT:
				for connected_port in port.get_connected_ports():
					propagate_value(port, connected_port)

func clear_input_value(input_port: GraphPort, from_port: GraphPort) -> void:
	var input_node = input_port.owner_node

	# Try new method first (for operation nodes with source port tracking)
	if input_node.has_method("clear_input_from"):
		input_node.clear_input_from(from_port)
		for port in input_node.ports:
			if port.port_type == GraphPort.PortType.OUTPUT:
				for connected_port in port.get_connected_ports():
					propagate_value(port, connected_port)

	# Fall back to old methods for backward compatibility
	elif input_port.port_name == "input_a" and input_node.has_method("clear_input_a"):
		input_node.clear_input_a()
		for port in input_node.ports:
			if port.port_type == GraphPort.PortType.OUTPUT:
				for connected_port in port.get_connected_ports():
					propagate_value(port, connected_port)

	elif input_port.port_name == "input_b" and input_node.has_method("clear_input_b"):
		input_node.clear_input_b()
		for port in input_node.ports:
			if port.port_type == GraphPort.PortType.OUTPUT:
				for connected_port in port.get_connected_ports():
					propagate_value(port, connected_port)

	elif input_node.has_method("clear_input_value"):
		input_node.clear_input_value()
		for port in input_node.ports:
			if port.port_type == GraphPort.PortType.OUTPUT:
				for connected_port in port.get_connected_ports():
					propagate_value(port, connected_port)

func get_connection_at_position(pos: Vector2, threshold: float = 10.0) -> GraphConnection:
	# Check in reverse order so topmost connections are checked first
	for i in range(connections.size() - 1, -1, -1):
		if connections[i].is_point_near_curve(pos, threshold):
			return connections[i]
	return null

func remove_all_connections_to_node(node: CustomGraphNode) -> void:
	# Remove all connections involving this node
	var connections_to_remove: Array[GraphConnection] = []

	for connection in connections:
		if connection.from_port.owner_node == node or connection.to_port.owner_node == node:
			connections_to_remove.append(connection)

	for connection in connections_to_remove:
		remove_connection(connection)

func get_connection_count() -> int:
	return connections.size()

func clear_all_connections() -> void:
	var all_connections = connections.duplicate()
	for connection in all_connections:
		remove_connection(connection)
