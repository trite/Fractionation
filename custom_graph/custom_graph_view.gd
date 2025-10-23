extends Control
class_name CustomGraphView

const ConnectionManager = preload("res://custom_graph/connection_manager.gd")

signal connection_created(connection: GraphConnection)
signal connection_removed(connection: GraphConnection)
signal node_selected(node: CustomGraphNode)

# Collections
var nodes: Array[CustomGraphNode] = []
var connection_manager: ConnectionManager = null

# Camera controls
var min_zoom: float = 0.25
var max_zoom: float = 2.0
var pan_speed: float = 1.0

# Connection dragging state
var is_dragging_connection: bool = false
var dragged_port: GraphPort = null
var drag_end_position: Vector2 = Vector2.ZERO
var sticky_connection_mode: bool = false

# Grid rendering
var show_grid: bool = true
var grid_size: int = 20
var grid_color_major: Color = Color(0, 0.5, 0, 0.3)
var grid_color_minor: Color = Color(0, 0.3, 0, 0.15)

# Background
var background_color: Color = Color(0.02, 0.02, 0.02, 1)

# Node being dragged
var dragged_node: CustomGraphNode = null
var node_drag_start_pos: Vector2 = Vector2.ZERO

# Panning state
var is_panning: bool = false
var pan_start_pos: Vector2 = Vector2.ZERO

# Scene structure
var world: Node2D
var camera: Camera2D
var viewport: SubViewport
var viewport_container: SubViewportContainer

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process_input(true)
	clip_contents = true

	# Initialize connection manager
	connection_manager = ConnectionManager.new()
	connection_manager.connection_created.connect(_on_connection_manager_created)
	connection_manager.connection_removed.connect(_on_connection_manager_removed)

	# Create viewport structure
	setup_viewport()

func setup_viewport() -> void:
	# Create SubViewportContainer to hold everything
	viewport_container = SubViewportContainer.new()
	viewport_container.stretch = true
	viewport_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(viewport_container)

	# Create SubViewport
	viewport = SubViewport.new()
	viewport.size = size
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = true
	viewport_container.add_child(viewport)

	# Create world Node2D
	world = Node2D.new()
	world.name = "World"
	viewport.add_child(world)

	# Create Camera2D
	camera = Camera2D.new()
	camera.name = "Camera"
	camera.zoom = Vector2(1.0, 1.0)
	camera.position = Vector2.ZERO
	world.add_child(camera)

	# Connect to resize to update viewport
	resized.connect(_on_resized)

func _on_resized() -> void:
	if viewport:
		viewport.size = size

func add_node(node: CustomGraphNode) -> void:
	nodes.append(node)
	world.add_child(node)

	# Connect signals
	node.port_clicked.connect(_on_port_clicked)
	node.node_moved.connect(_on_node_moved)
	node.rotation_changed.connect(_on_node_rotated)

	queue_redraw()

func remove_node(node: CustomGraphNode) -> void:
	# Remove all connections involving this node
	connection_manager.remove_all_connections_to_node(node)

	nodes.erase(node)
	node.queue_free()
	queue_redraw()

func create_connection(from_port: GraphPort, to_port: GraphPort) -> GraphConnection:
	# Delegate to connection manager
	var connection = connection_manager.create_connection(from_port, to_port)

	if connection:
		queue_redraw()

	return connection

func remove_connection(connection: GraphConnection) -> void:
	# Delegate to connection manager
	connection_manager.remove_connection(connection)
	queue_redraw()

func _on_connection_manager_created(connection: GraphConnection) -> void:
	# Forward the signal from connection manager
	connection_created.emit(connection)

func _on_connection_manager_removed(connection: GraphConnection) -> void:
	# Forward the signal from connection manager
	connection_removed.emit(connection)

func get_connection_at_position(pos: Vector2) -> GraphConnection:
	var world_pos = screen_to_world(pos)
	return connection_manager.get_connection_at_position(world_pos)

func _on_port_clicked(port: GraphPort) -> void:
	if is_dragging_connection:
		if dragged_port and dragged_port.can_connect_to(port):
			create_connection(dragged_port, port)

		is_dragging_connection = false
		dragged_port = null
		sticky_connection_mode = false
		queue_redraw()
	else:
		is_dragging_connection = true
		dragged_port = port
		drag_end_position = screen_to_world(get_local_mouse_position())
		sticky_connection_mode = false
		queue_redraw()

func _on_node_moved(node: CustomGraphNode) -> void:
	queue_redraw()

func _on_node_rotated(node: CustomGraphNode) -> void:
	queue_redraw()

func get_port_at_position(pos: Vector2) -> GraphPort:
	var world_pos = screen_to_world(pos)
	for node in nodes:
		for port in node.ports:
			if port.is_point_inside(world_pos):
				return port
	return null

func get_node_at_position(pos: Vector2) -> CustomGraphNode:
	var world_pos = screen_to_world(pos)
	for i in range(nodes.size() - 1, -1, -1):
		if nodes[i].is_point_inside_node(world_pos):
			return nodes[i]
	return null

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				var mouse_pos = event.position

				if dragged_node:
					dragged_node.stop_drag()
					dragged_node = null
					return

				var port = get_port_at_position(mouse_pos)
				if port:
					_on_port_clicked(port)
					return

				var connection = get_connection_at_position(mouse_pos)
				if connection:
					remove_connection(connection)
					print("Disconnected connection")
					return

				var node = get_node_at_position(mouse_pos)
				if node:
					dragged_node = node
					node_drag_start_pos = mouse_pos
					node.start_drag(screen_to_world(mouse_pos) - node.position)
					return

				if is_dragging_connection and sticky_connection_mode:
					is_dragging_connection = false
					dragged_port = null
					sticky_connection_mode = false
					queue_redraw()
					return

			else:  # Mouse released
				if dragged_node and dragged_node.is_being_dragged:
					dragged_node.stop_drag()
					dragged_node = null

				if is_dragging_connection and dragged_port:
					if not sticky_connection_mode:
						var port = get_port_at_position(event.position)
						if port and dragged_port.can_connect_to(port):
							create_connection(dragged_port, port)
							is_dragging_connection = false
							dragged_port = null
							queue_redraw()
						else:
							sticky_connection_mode = true
							print("Sticky connection mode activated")

		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				var mouse_pos = event.position
				var node = get_node_at_position(mouse_pos)
				if node:
					start_node_drag(node)
					print("Picked up node")
					return

		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				is_panning = true
				pan_start_pos = event.position
			else:
				is_panning = false

		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_at_point(event.position, 1.1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_at_point(event.position, 0.9)

	elif event is InputEventMouseMotion:
		if is_panning:
			var delta = Vector2(event.position - pan_start_pos)
			camera.position -= delta / camera.zoom
			pan_start_pos = event.position
			queue_redraw()

		if dragged_node:
			var world_pos = screen_to_world(event.position)
			dragged_node.position = world_pos
			_on_node_moved(dragged_node)
			queue_redraw()

		if is_dragging_connection:
			drag_end_position = screen_to_world(event.position)
			queue_redraw()

		var hovered_connection = get_connection_at_position(event.position)
		for connection in connection_manager.connections:
			connection.is_hovered = (connection == hovered_connection)
		queue_redraw()

func zoom_at_point(screen_point: Vector2, zoom_factor: float) -> void:
	# Get world position under mouse
	var world_point = screen_to_world(screen_point)

	# Update zoom
	var new_zoom = clamp(camera.zoom.x * zoom_factor, min_zoom, max_zoom)
	camera.zoom = Vector2(new_zoom, new_zoom)

	# Adjust camera position to keep world_point under mouse
	var new_world_point = screen_to_world(screen_point)
	camera.position += world_point - new_world_point

	queue_redraw()

func screen_to_world(screen_pos: Vector2) -> Vector2:
	# Convert screen position to world position accounting for camera
	return (screen_pos - Vector2(viewport.size) / 2.0) / camera.zoom + camera.position

func world_to_screen(world_pos: Vector2) -> Vector2:
	# Convert world position to screen position
	return (world_pos - camera.position) * camera.zoom + Vector2(viewport.size) / 2.0

func start_node_drag(node: CustomGraphNode) -> void:
	dragged_node = node
	node_drag_start_pos = node.position

func auto_connect_node(node: CustomGraphNode) -> bool:
	var available_port: GraphPort = null

	for port in node.ports:
		if port.port_type == GraphPort.PortType.INPUT:
			if port.has_available_connection_slot():
				available_port = port
				break

	if not available_port:
		for port in node.ports:
			if port.port_type == GraphPort.PortType.OUTPUT:
				if port.has_available_connection_slot():
					available_port = port
					break

	if not available_port:
		print("No available port slots on this node")
		return false

	var closest_node: CustomGraphNode = null
	var closest_distance: float = INF
	var closest_compatible_port: GraphPort = null

	for other_node in nodes:
		if other_node == node:
			continue

		var distance = node.position.distance_to(other_node.position)

		for other_port in other_node.ports:
			if available_port.can_connect_to(other_port):
				if distance < closest_distance:
					closest_distance = distance
					closest_node = other_node
					closest_compatible_port = other_port

	if closest_compatible_port:
		create_connection(available_port, closest_compatible_port)
		print("Auto-connected to nearest compatible port")
		return true
	else:
		print("No compatible ports with available slots found nearby")
		return false

func auto_disconnect_node(node: CustomGraphNode) -> bool:
	var port_to_disconnect: GraphPort = null

	for i in range(node.ports.size() - 1, -1, -1):
		var port = node.ports[i]
		if port.port_type == GraphPort.PortType.OUTPUT:
			if not port.connections.is_empty():
				port_to_disconnect = port
				break

	if not port_to_disconnect:
		for i in range(node.ports.size() - 1, -1, -1):
			var port = node.ports[i]
			if port.port_type == GraphPort.PortType.INPUT:
				if not port.connections.is_empty():
					port_to_disconnect = port
					break

	if not port_to_disconnect:
		print("No connections to disconnect on this node")
		return false

	# Get the last connection on this port and remove it
	var connection_to_remove = port_to_disconnect.connections[port_to_disconnect.connections.size() - 1]
	remove_connection(connection_to_remove)
	print("Auto-disconnected port")
	return true

func delete_node(node: CustomGraphNode) -> void:
	# Check if it's a starting node (NumberNode with is_starting_node flag)
	if node.get("is_starting_node") == true:
		print("Cannot delete starting node")
		return

	# Check if it's a target node - those can't be deleted
	if node is TargetNode:
		print("Cannot delete target node")
		return

	print("Deleting node")
	# Clear the dragged node reference
	if dragged_node == node:
		dragged_node = null

	# Remove the node (connections will be cleaned up automatically)
	remove_node(node)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("node_auto_connect"):
		if dragged_node:
			auto_connect_node(dragged_node)
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("node_auto_disconnect"):
		if dragged_node:
			auto_disconnect_node(dragged_node)
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("node_rotate"):
		if dragged_node:
			dragged_node.rotate_node(45.0)
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("node_delete"):
		if dragged_node:
			delete_node(dragged_node)
			get_viewport().set_input_as_handled()

func _draw() -> void:
	# Background drawing is now handled in world
	pass

func _process(_delta: float) -> void:
	# Draw connections and background in world space
	world.queue_redraw()
	if not world.is_connected("draw", _draw_world):
		world.draw.connect(_draw_world)

func _draw_world() -> void:
	# Draw background
	var cam_pos = camera.position
	var screen_size = Vector2(viewport.size) / camera.zoom
	var rect_pos = cam_pos - screen_size / 2.0
	world.draw_rect(Rect2(rect_pos, screen_size), background_color, true)

	# Draw grid
	if show_grid:
		_draw_grid_world()

	# Draw all connections
	for connection in connection_manager.connections:
		connection.draw_on_canvas(world)

	# Draw connection being dragged
	if is_dragging_connection and dragged_port:
		_draw_dragging_connection()

func _draw_grid_world() -> void:
	var cam_pos = camera.position
	var screen_size = Vector2(viewport.size) / camera.zoom
	var rect_pos = cam_pos - screen_size / 2.0
	var rect_end = cam_pos + screen_size / 2.0

	# Calculate grid start positions
	var start_x = floor(rect_pos.x / grid_size) * grid_size
	var start_y = floor(rect_pos.y / grid_size) * grid_size

	# Draw minor grid lines
	var x = start_x
	while x <= rect_end.x:
		world.draw_line(Vector2(x, rect_pos.y), Vector2(x, rect_end.y), grid_color_minor, 1.0 / camera.zoom.x)
		x += grid_size

	var y = start_y
	while y <= rect_end.y:
		world.draw_line(Vector2(rect_pos.x, y), Vector2(rect_end.x, y), grid_color_minor, 1.0 / camera.zoom.y)
		y += grid_size

	# Draw major grid lines every 5 units
	x = floor(rect_pos.x / (grid_size * 5)) * (grid_size * 5)
	while x <= rect_end.x:
		world.draw_line(Vector2(x, rect_pos.y), Vector2(x, rect_end.y), grid_color_major, 2.0 / camera.zoom.x)
		x += grid_size * 5

	y = floor(rect_pos.y / (grid_size * 5)) * (grid_size * 5)
	while y <= rect_end.y:
		world.draw_line(Vector2(rect_pos.x, y), Vector2(rect_end.x, y), grid_color_major, 2.0 / camera.zoom.y)
		y += grid_size * 5

func _draw_dragging_connection() -> void:
	var from_pos = dragged_port.get_world_position()
	var to_pos = drag_end_position

	var control_offset = (to_pos - from_pos) * 0.5
	var points = 20

	for i in range(points):
		var t1 = float(i) / float(points)
		var t2 = float(i + 1) / float(points)

		var p1 = from_pos.lerp(to_pos, t1) + Vector2(0, -abs(sin(t1 * PI)) * control_offset.length() * 0.3)
		var p2 = from_pos.lerp(to_pos, t2) + Vector2(0, -abs(sin(t2 * PI)) * control_offset.length() * 0.3)

		world.draw_line(p1, p2, Color(1, 1, 1, 0.7), 3.0 / camera.zoom.x, true)
