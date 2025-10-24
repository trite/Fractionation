extends Control
class_name LevelCompleteScreen

signal next_level_pressed

var title_label: Label
var message_label: Label
var next_button: Button

func _ready() -> void:
	# Take up full screen
	set_anchors_preset(Control.PRESET_FULL_RECT)

	# Semi-transparent black background
	var bg_panel = Panel.new()
	bg_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg_panel)

	# Create a styled panel for the content
	var content_panel = PanelContainer.new()
	content_panel.custom_minimum_size = Vector2(500, 300)
	content_panel.set_anchors_preset(Control.PRESET_CENTER)
	content_panel.offset_left = -250
	content_panel.offset_right = 250
	content_panel.offset_top = -150
	content_panel.offset_bottom = 150
	add_child(content_panel)

	# VBox for content
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 20)
	content_panel.add_child(vbox)

	# Add some padding
	var top_spacer = Control.new()
	top_spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(top_spacer)

	# Title label
	title_label = Label.new()
	title_label.text = "Level Complete!"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 32)
	title_label.add_theme_color_override("font_color", Color(0, 1, 0, 1))
	vbox.add_child(title_label)

	# Message label
	message_label = Label.new()
	message_label.text = "Great job!"
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 18)
	message_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	message_label.custom_minimum_size = Vector2(450, 0)
	vbox.add_child(message_label)

	# Spacer to push button down
	var middle_spacer = Control.new()
	middle_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(middle_spacer)

	# Next level button
	next_button = Button.new()
	next_button.text = "Next Level"
	next_button.custom_minimum_size = Vector2(200, 50)
	next_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	next_button.add_theme_font_size_override("font_size", 20)
	next_button.pressed.connect(_on_next_pressed)
	vbox.add_child(next_button)

	# Bottom spacer
	var bottom_spacer = Control.new()
	bottom_spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(bottom_spacer)

	# Start hidden
	hide()

func show_level_complete(title: String = "Level Complete!", message: String = "Great job!") -> void:
	title_label.text = title
	message_label.text = message
	show()

func _on_next_pressed() -> void:
	next_level_pressed.emit()
	hide()
