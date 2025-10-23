extends GraphNode

var input_value: Variant = null

@onready var value_label: Label = $ValueLabel

func _ready() -> void:
	# Set up slots: 1 input (left), 2 outputs (right)
	# Slot 0: Input (left only)
	set_slot_enabled_left(0, true)
	set_slot_enabled_right(0, false)
	set_slot_type_left(0, 0)
	set_slot_color_left(0, Color.LIGHT_BLUE)

	# Slot 1: Output 1 (right only)
	set_slot_enabled_left(1, false)
	set_slot_enabled_right(1, true)
	set_slot_type_right(1, 0)
	set_slot_color_right(1, Color.LIGHT_GREEN)

	# Slot 2: Output 2 (right only)
	set_slot_enabled_left(2, false)
	set_slot_enabled_right(2, true)
	set_slot_type_right(2, 0)
	set_slot_color_right(2, Color.LIGHT_GREEN)

	update_display()

func set_input(value: Variant) -> void:
	input_value = value
	update_display()

func clear_input() -> void:
	input_value = null
	update_display()

func get_result() -> Variant:
	return input_value

func update_display() -> void:
	if not value_label:
		return

	var value_str := "__"
	if input_value != null:
		if input_value is float:
			value_str = "%.2f" % input_value
		else:
			value_str = str(input_value)

	value_label.text = value_str + " → " + value_str + " " + value_str
