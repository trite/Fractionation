extends RefCounted
class_name LevelData

const Milestone = preload("res://custom_graph/milestone.gd")

# Level metadata
var level_name: String = ""
var level_description: String = ""

# Initial state
var starting_tokens: int = 200
var starting_nodes: Array = []  # [{value: int, type: String}]
var target_nodes: Array = []     # [{value: int, type: String}]
var available_node_types: Array = ["add", "subtract", "multiply", "divide"]
var node_costs: Dictionary = {
	"add": 100,
	"subtract": 100,
	"multiply": 100,
	"divide": 100,
	"duplicator": 200
}
var refund_percentage: float = 1.0  # 0.0 to 1.0, where 1.0 = 100% refund

# Milestones
var milestones: Array = []  # Array of Milestone objects

func _init(data: Dictionary = {}):
	if data.is_empty():
		return

	level_name = data.get("name", "")
	level_description = data.get("description", "")
	starting_tokens = data.get("starting_tokens", 200)

	# Parse starting nodes
	if data.has("starting_nodes"):
		for node_data in data["starting_nodes"]:
			starting_nodes.append(node_data)

	# Parse target nodes
	if data.has("target_nodes"):
		for node_data in data["target_nodes"]:
			target_nodes.append(node_data)

	# Parse available node types
	if data.has("available_node_types"):
		available_node_types = data["available_node_types"].duplicate()

	# Parse node costs
	if data.has("node_costs"):
		node_costs = data["node_costs"].duplicate()

	# Parse refund percentage
	if data.has("refund_percentage"):
		refund_percentage = data["refund_percentage"]

	# Parse milestones
	if data.has("milestones"):
		for milestone_data in data["milestones"]:
			milestones.append(Milestone.new(milestone_data))
