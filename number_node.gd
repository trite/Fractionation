extends GraphNode

var value: int = 0

@onready var value_label: Label = $ValueLabel

func _ready() -> void:
	# Set up the 10 connection slots (output only on right side)
	# Slot 0 is the ValueLabel (no connection)
	# Slots 1-10 are the output slots
	for i in range(10):
		# slot_index, enable_left (input), type_left, color_left, enable_right (output), type_right, color_right
		set_slot_enabled_left(i + 1, false)
		set_slot_enabled_right(i + 1, true)
		set_slot_type_right(i + 1, 0)
		set_slot_color_right(i + 1, Color.LIGHT_GREEN)

	print("NumberNode setup complete. Child count: ", get_child_count())
	for i in range(get_child_count()):
		print("  Child ", i, ": ", get_child(i).name if get_child(i) else "null")

	update_display()

func set_value(new_value: int) -> void:
	value = new_value
	if value_label:
		update_display()

func get_value() -> int:
	return value

func update_display() -> void:
	value_label.text = str(value)
	title = "Number: " + str(value)
