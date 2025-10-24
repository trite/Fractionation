extends RefCounted
class_name Milestone

var trigger_type: String = ""  # "solve_n_targets", "reach_total_value", "solve_specific_target"
var trigger_params: Dictionary = {}
var rewards: Array = []
var notification_title: String = ""
var notification_message: String = ""

func _init(data: Dictionary):
	trigger_type = data.get("trigger_type", "")
	trigger_params = data.get("trigger_params", {})
	rewards = data.get("rewards", [])

	# Use custom notification or generate default
	notification_title = data.get("notification_title", "Milestone Complete!")
	if data.has("notification_message"):
		notification_message = data["notification_message"]
	else:
		notification_message = generate_default_message()

func generate_default_message() -> String:
	var msg = ""
	for reward in rewards:
		match reward.get("type", ""):
			"tokens":
				msg += "+%d tokens. " % reward.get("amount", 0)
			"starter_node":
				msg += "Node %d unlocked. " % reward.get("value", 0)
			"target_node":
				msg += "New target: %d. " % reward.get("value", 0)
			"unlock_node_type":
				msg += "%s unlocked. " % reward.get("node_type", "").capitalize()
	return msg.strip_edges()

func check_trigger(game_state: Dictionary) -> bool:
	match trigger_type:
		"solve_n_targets":
			var required = trigger_params.get("n", 1)
			var solved = game_state.get("solved_count", 0)
			return solved >= required

		"reach_total_value":
			var required = trigger_params.get("total", 0)
			var actual = game_state.get("total_value", 0)
			return actual >= required

		"solve_specific_target":
			var target_value = trigger_params.get("target_value", 0)
			var solved_targets = game_state.get("solved_targets", [])
			return target_value in solved_targets

	return false
