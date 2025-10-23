extends RefCounted
class_name Milestone

enum TriggerType {
	FIRST_CONNECTION,      # Triggered when first target is solved
	TARGET_COUNT,          # Triggered when X targets are solved
	SPECIFIC_TARGET,       # Triggered when a specific target is solved
	TOTAL_VALUE            # Triggered when sum of all solved targets reaches X
}

var milestone_name: String
var trigger_type: TriggerType
var trigger_value: Variant  # For TARGET_COUNT, SPECIFIC_TARGET, or TOTAL_VALUE
var token_reward: int
var unlocks: Array[String]  # List of node types to unlock
var is_completed: bool = false

func _init(name: String, type: TriggerType, value: Variant = null, reward: int = 0, unlock_list: Array[String] = []):
	milestone_name = name
	trigger_type = type
	trigger_value = value
	token_reward = reward
	unlocks = unlock_list

func check_trigger(solved_count: int, solved_targets: Array, total_value: int) -> bool:
	if is_completed:
		return false

	match trigger_type:
		TriggerType.FIRST_CONNECTION:
			return solved_count >= 1
		TriggerType.TARGET_COUNT:
			return solved_count >= trigger_value
		TriggerType.SPECIFIC_TARGET:
			return trigger_value in solved_targets
		TriggerType.TOTAL_VALUE:
			return total_value >= trigger_value

	return false

func complete() -> void:
	is_completed = true
