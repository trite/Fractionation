extends GraphNode

var target_value: int = 0
var current_value: Variant = null
var is_correct: bool = false

@onready var target_label: Label = $TargetLabel

func _ready() -> void:
	# Set up single input slot (left side only)
	set_slot_enabled_left(0, true)
	set_slot_enabled_right(0, false)
	set_slot_type_left(0, 0)
	set_slot_color_left(0, Color.YELLOW)

	update_display()

func set_target(value: int) -> void:
	target_value = value
	update_display()

func set_input(value: Variant) -> void:
	current_value = value
	check_correctness()
	update_display()

func clear_input() -> void:
	current_value = null
	is_correct = false
	update_display()

func check_correctness() -> void:
	if current_value == null:
		is_correct = false
		return

	# Check if the value matches (with some tolerance for floats)
	if current_value is float and target_value is int:
		is_correct = abs(current_value - target_value) < 0.01
	elif current_value is int and target_value is int:
		is_correct = (current_value == target_value)
	else:
		is_correct = false

func is_solved() -> bool:
	return is_correct

func update_display() -> void:
	if not target_label:
		return

	title = "Target: " + str(target_value)

	if current_value != null:
		var value_str := ""
		if current_value is float:
			value_str = "%.2f" % current_value
		else:
			value_str = str(current_value)

		if is_correct:
			target_label.text = "✓ " + value_str + " ✓"
			# Set green color for correct
			modulate = Color(0.5, 1.0, 0.5)
		else:
			target_label.text = "✗ " + value_str + " ✗"
			# Set red color for incorrect
			modulate = Color(1.0, 0.5, 0.5)
	else:
		target_label.text = "Connect input"
		# Set neutral color
		modulate = Color(1.0, 1.0, 1.0)
