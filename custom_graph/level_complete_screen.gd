extends Control
class_name LevelCompleteScreen

signal next_level_pressed
signal continue_playing_pressed

var title_label: Label
var message_label: Label
var next_button: Button
var continue_button: Button

func _ready() -> void:
	# Explicitly set anchors to fill parent
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0
	mouse_filter = Control.MOUSE_FILTER_STOP

	# Semi-transparent black background
	var bg_panel = Panel.new()
	bg_panel.anchor_left = 0.0
	bg_panel.anchor_top = 0.0
	bg_panel.anchor_right = 1.0
	bg_panel.anchor_bottom = 1.0
	bg_panel.offset_left = 0
	bg_panel.offset_top = 0
	bg_panel.offset_right = 0
	bg_panel.offset_bottom = 0
	add_child(bg_panel)

	# Use a CenterContainer to handle centering
	var center_container = CenterContainer.new()
	center_container.anchor_left = 0.0
	center_container.anchor_top = 0.0
	center_container.anchor_right = 1.0
	center_container.anchor_bottom = 1.0
	center_container.offset_left = 0
	center_container.offset_top = -50  # Offset to position slightly above center
	center_container.offset_right = 0
	center_container.offset_bottom = 0
	add_child(center_container)

	# Create a styled panel for the content
	var content_panel = PanelContainer.new()
	content_panel.custom_minimum_size = Vector2(500, 300)
	center_container.add_child(content_panel)

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

	# Spacer to push buttons down
	var middle_spacer = Control.new()
	middle_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(middle_spacer)

	# HBox for buttons
	var button_hbox = HBoxContainer.new()
	button_hbox.set_alignment(BoxContainer.ALIGNMENT_CENTER)
	button_hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(button_hbox)

	# Continue Playing button
	continue_button = Button.new()
	continue_button.text = "Continue Playing"
	continue_button.custom_minimum_size = Vector2(200, 50)
	continue_button.add_theme_font_size_override("font_size", 20)
	_apply_button_style(continue_button)
	continue_button.pressed.connect(_on_continue_pressed)
	button_hbox.add_child(continue_button)

	# Next level button
	next_button = Button.new()
	next_button.text = "Next Level"
	next_button.custom_minimum_size = Vector2(200, 50)
	next_button.add_theme_font_size_override("font_size", 20)
	_apply_button_style(next_button)
	next_button.pressed.connect(_on_next_pressed)
	button_hbox.add_child(next_button)

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

func _apply_button_style(button: Button) -> void:
	# Apply bright green on dark background styling
	button.add_theme_color_override("font_color", Color(0, 1, 0, 1))  # Bright green
	button.add_theme_color_override("font_hover_color", Color(0.5, 1, 0.5, 1))  # Lighter green on hover
	button.add_theme_color_override("font_pressed_color", Color(0, 0.8, 0, 1))  # Darker green when pressed

	# Create StyleBox for button background
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.1, 0.1, 0.1, 0.9)  # Dark background
	normal_style.border_color = Color(0, 1, 0, 1)  # Bright green border
	normal_style.border_width_left = 2
	normal_style.border_width_right = 2
	normal_style.border_width_top = 2
	normal_style.border_width_bottom = 2
	normal_style.corner_radius_top_left = 5
	normal_style.corner_radius_top_right = 5
	normal_style.corner_radius_bottom_left = 5
	normal_style.corner_radius_bottom_right = 5

	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0.15, 0.3, 0.15, 0.95)  # Slight green tint on hover
	hover_style.border_color = Color(0.5, 1, 0.5, 1)  # Lighter green border
	hover_style.border_width_left = 2
	hover_style.border_width_right = 2
	hover_style.border_width_top = 2
	hover_style.border_width_bottom = 2
	hover_style.corner_radius_top_left = 5
	hover_style.corner_radius_top_right = 5
	hover_style.corner_radius_bottom_left = 5
	hover_style.corner_radius_bottom_right = 5

	var pressed_style = StyleBoxFlat.new()
	pressed_style.bg_color = Color(0.05, 0.2, 0.05, 1)  # Darker green when pressed
	pressed_style.border_color = Color(0, 0.8, 0, 1)  # Darker green border
	pressed_style.border_width_left = 2
	pressed_style.border_width_right = 2
	pressed_style.border_width_top = 2
	pressed_style.border_width_bottom = 2
	pressed_style.corner_radius_top_left = 5
	pressed_style.corner_radius_top_right = 5
	pressed_style.corner_radius_bottom_left = 5
	pressed_style.corner_radius_bottom_right = 5

	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", pressed_style)

func _on_continue_pressed() -> void:
	continue_playing_pressed.emit()
	hide()

func _on_next_pressed() -> void:
	next_level_pressed.emit()
	hide()
