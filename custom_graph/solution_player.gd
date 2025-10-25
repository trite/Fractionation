extends Node
class_name SolutionPlayer

signal playback_complete

const OperationNode = preload("res://custom_graph/operation_node.gd")
const DuplicatorNode = preload("res://custom_graph/duplicator_node.gd")

var game_main = null  # Reference to game_main for spawning nodes
var graph_view = null  # Reference to graph_view for connections

var steps: Array = []
var current_step_index: int = 0
var node_lookup: Dictionary = {}  # Maps solution IDs to actual node instances
var is_playing: bool = false

var step_delay: float = 0.5  # Seconds between steps

func _ready() -> void:
	pass

func play_solution(solution_data: Dictionary, initial_node_lookup: Dictionary, _game_main, _graph_view) -> void:
	if is_playing:
		print("Solution already playing!")
		return

	game_main = _game_main
	graph_view = _graph_view
	steps = solution_data.get("steps", [])
	current_step_index = 0
	node_lookup = initial_node_lookup.duplicate()
	is_playing = true

	print("Starting solution playback with %d steps" % steps.size())

	# Clean board of conflicting nodes/connections before starting
	_prepare_board_for_solution()

	# Start playing first step
	if steps.size() > 0:
		_execute_next_step()
	else:
		_finish_playback()

func _prepare_board_for_solution() -> void:
	"""Remove only player-created nodes; keep all solution nodes"""
	print("Preparing board for solution...")

	# Build set of node IDs that this solution will spawn
	var this_solution_node_ids = {}
	for step in steps:
		if step.get("action") == "spawn":
			var node_id = step.get("node_id", "")
			if not node_id.is_empty():
				this_solution_node_ids[node_id] = true

	# Remove only player-created spawned nodes (no solution_id metadata)
	var removed_count = 0
	for node in graph_view.nodes.duplicate():
		# Always keep starting nodes and target nodes
		if node.get("is_starting_node") == true:
			continue
		if node is TargetNode:
			continue

		# Check if this is a solution node that we're tracking (starter/target)
		var is_tracked_node = false
		for node_id in node_lookup:
			if node_lookup[node_id] == node:
				is_tracked_node = true
				break

		# If it's a tracked starter/target, keep it
		if is_tracked_node:
			continue

		# This is a spawned node - check if it has a solution_id metadata
		if node.has_meta("solution_id"):
			var solution_id = node.get_meta("solution_id")
			# Keep ALL solution nodes from any solution
			# If this solution needs it, add to lookup for reuse
			if this_solution_node_ids.has(solution_id):
				node_lookup[solution_id] = node
				print("  Reusing existing solution node '%s'" % solution_id)
			else:
				print("  Keeping solution node '%s' from previous solution" % solution_id)
			continue

		# This spawned node has no solution_id - it's player-created, remove it
		print("  Removing player-created spawned node")
		graph_view.remove_node(node)
		removed_count += 1

	print("Board prepared - removed %d player-created nodes" % removed_count)

func _execute_next_step() -> void:
	if current_step_index >= steps.size():
		_finish_playback()
		return

	var step = steps[current_step_index]
	var action = step.get("action", "")

	print("\n▶ Executing step %d: %s" % [current_step_index, action])

	var success = false
	match action:
		"spawn":
			success = _execute_spawn(step)
		"connect":
			success = _execute_connect(step)
		_:
			push_error("SOLUTION FAILED: Unknown solution action: " + action)
			_halt_playback()
			return

	if not success:
		_halt_playback()
		return

	current_step_index += 1

	# Schedule next step
	await get_tree().create_timer(step_delay).timeout
	_execute_next_step()

func _halt_playback() -> void:
	is_playing = false
	print("\n❌ Solution playback HALTED at step %d due to error!" % current_step_index)
	playback_complete.emit()

func _execute_spawn(step: Dictionary) -> bool:
	var node_type = step.get("node_type", "")
	var node_id = step.get("node_id", "")

	if node_id.is_empty():
		push_error("SOLUTION FAILED: Spawn step missing node_id")
		return false

	# Check if this node already exists in our lookup (from previous solution runs)
	if node_lookup.has(node_id):
		print("✓ Node '%s' already exists, skipping spawn" % node_id)
		return true

	var spawned_node = null

	match node_type:
		"add":
			spawned_node = game_main.spawn_operation_node_for_solution(OperationNode.Operation.ADD)
		"subtract":
			spawned_node = game_main.spawn_operation_node_for_solution(OperationNode.Operation.SUBTRACT)
		"multiply":
			spawned_node = game_main.spawn_operation_node_for_solution(OperationNode.Operation.MULTIPLY)
		"divide":
			spawned_node = game_main.spawn_operation_node_for_solution(OperationNode.Operation.DIVIDE)
		"duplicator":
			spawned_node = game_main.spawn_duplicator_node_for_solution()
		_:
			push_error("SOLUTION FAILED: Unknown node type: " + node_type)
			return false

	if spawned_node:
		# Tag the node with its solution ID so it can be reused/tracked
		spawned_node.set_meta("solution_id", node_id)
		node_lookup[node_id] = spawned_node
		print("✓ Spawned %s node with ID '%s'" % [node_type, node_id])
		return true
	else:
		push_error("SOLUTION FAILED: Failed to spawn %s node" % node_type)
		return false

func _execute_connect(step: Dictionary) -> bool:
	var from_id = step.get("from", "")
	var to_id = step.get("to", "")
	var from_port_index = step.get("from_port", 0)
	var to_port_index = step.get("to_port", 0)

	if not node_lookup.has(from_id):
		push_error("SOLUTION FAILED: from node not found: " + from_id)
		return false

	if not node_lookup.has(to_id):
		push_error("SOLUTION FAILED: to node not found: " + to_id)
		return false

	var from_node = node_lookup[from_id]
	var to_node = node_lookup[to_id]

	# Debug: print node port information
	print("  From node '%s' (%s):" % [from_id, from_node.get_class()])
	for i in range(from_node.ports.size()):
		var port = from_node.ports[i]
		var port_type_str = "INPUT" if port.port_type == GraphPort.PortType.INPUT else "OUTPUT"
		print("    Port[%d]: %s, max_connections=%d, current_connections=%d" %
			[i, port_type_str, port.max_connections, port.connections.size()])

	print("  To node '%s' (%s):" % [to_id, to_node.get_class()])
	for i in range(to_node.ports.size()):
		var port = to_node.ports[i]
		var port_type_str = "INPUT" if port.port_type == GraphPort.PortType.INPUT else "OUTPUT"
		print("    Port[%d]: %s, max_connections=%d, current_connections=%d" %
			[i, port_type_str, port.max_connections, port.connections.size()])

	# Get ports
	if from_port_index >= from_node.ports.size():
		push_error("SOLUTION FAILED: from_port index %d out of range (node has %d ports)" %
			[from_port_index, from_node.ports.size()])
		return false

	if to_port_index >= to_node.ports.size():
		push_error("SOLUTION FAILED: to_port index %d out of range (node has %d ports)" %
			[to_port_index, to_node.ports.size()])
		return false

	var from_port = from_node.ports[from_port_index]
	var to_port = to_node.ports[to_port_index]

	# Try to create connection (connection manager will validate if it's allowed)
	var connection = graph_view.create_connection(from_port, to_port)

	if connection:
		print("✓ Connected %s[%d] to %s[%d]" % [from_id, from_port_index, to_id, to_port_index])
		return true
	else:
		# Connection was rejected - check if we should treat this as an error or skip
		# If the port is already at max connections, that's okay (solution might be idempotent)
		if to_port.connections.size() >= to_port.max_connections:
			print("⊘ Connection %s[%d] -> %s[%d] skipped (port at max connections)" %
				[from_id, from_port_index, to_id, to_port_index])
			return true
		else:
			push_error("SOLUTION FAILED: Failed to create connection from %s[%d] to %s[%d]" %
				[from_id, from_port_index, to_id, to_port_index])
			return false

func _finish_playback() -> void:
	is_playing = false
	print("\n✅ Solution playback completed successfully!")
	playback_complete.emit()

func stop_playback() -> void:
	is_playing = false
	current_step_index = 0
	steps.clear()
	node_lookup.clear()
