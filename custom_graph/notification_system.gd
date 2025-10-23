extends Control
class_name NotificationSystem

const MAX_VISIBLE_NOTIFICATIONS = 4
const NOTIFICATION_HEIGHT = 80
const NOTIFICATION_WIDTH = 300
const NOTIFICATION_SPACING = 10
const NOTIFICATION_DURATION = 5.0  # seconds

var active_notifications: Array[Dictionary] = []
var hidden_notifications: Array[Dictionary] = []

func _ready() -> void:
	# Take up full screen space for positioning
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # Don't block mouse input

func show_notification(title: String, message: String) -> void:
	var notification_data = {
		"title": title,
		"message": message,
		"panel": null,
		"timer": 0.0
	}

	# If we're at max capacity, hide the oldest
	if active_notifications.size() >= MAX_VISIBLE_NOTIFICATIONS:
		var oldest = active_notifications.pop_front()
		if oldest.panel:
			oldest.panel.queue_free()
		hidden_notifications.append(oldest)

	# Create the notification panel
	var panel = create_notification_panel(title, message)
	notification_data.panel = panel
	active_notifications.append(notification_data)

	# Position all notifications
	reposition_notifications()

func create_notification_panel(title: String, message: String) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(NOTIFICATION_WIDTH, NOTIFICATION_HEIGHT)

	# Create content
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	# Title label
	var title_label = Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.add_theme_color_override("font_color", Color(0, 1, 0, 1))
	vbox.add_child(title_label)

	# Message label
	var message_label = Label.new()
	message_label.text = message
	message_label.add_theme_font_size_override("font_size", 12)
	message_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1))
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(message_label)

	# Dismiss button
	var dismiss_button = Button.new()
	dismiss_button.text = "Dismiss"
	dismiss_button.pressed.connect(func(): dismiss_notification(panel))
	vbox.add_child(dismiss_button)

	add_child(panel)
	return panel

func dismiss_notification(panel: PanelContainer) -> void:
	# Find and remove this notification
	for i in range(active_notifications.size()):
		if active_notifications[i].panel == panel:
			active_notifications.remove_at(i)
			panel.queue_free()
			break

	# Restore a hidden notification if any exist
	if not hidden_notifications.is_empty():
		var restored = hidden_notifications.pop_front()
		var new_panel = create_notification_panel(restored.title, restored.message)
		restored.panel = new_panel
		active_notifications.append(restored)

	# Reposition remaining notifications
	reposition_notifications()

func reposition_notifications() -> void:
	var viewport_height = get_viewport_rect().size.y
	var y_offset = 0

	# Position from bottom up
	for i in range(active_notifications.size() - 1, -1, -1):
		var notification = active_notifications[i]
		if notification.panel:
			# Position at bottom-left, stacking upward
			var x_pos = 10
			var y_pos = viewport_height - (y_offset + NOTIFICATION_HEIGHT) - 10
			notification.panel.position = Vector2(x_pos, y_pos)
			y_offset += NOTIFICATION_HEIGHT + NOTIFICATION_SPACING

func _process(delta: float) -> void:
	# Auto-dismiss notifications after duration
	for notification in active_notifications:
		notification.timer += delta
		if notification.timer >= NOTIFICATION_DURATION:
			if notification.panel:
				dismiss_notification(notification.panel)
			break  # Only dismiss one per frame
