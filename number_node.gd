extends GraphNode

var value: int = 0

@onready var value_label: Label = $VBoxContainer/ValueLabel

func _ready() -> void:
	# Set up the 10 connection slots
	# Each slot can accept input connections and provide output connections
	for i in range(10):
		# slot_index, enable_left (input), type_left, color_left, enable_right (output), type_right, color_right
		set_slot(i + 1, true, 0, Color.WHITE, true, 0, Color.WHITE)

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
