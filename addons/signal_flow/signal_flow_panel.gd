@tool
extends VBoxContainer

const EventResource = preload("res://addons/signal_flow/core/event_resource.gd")
const EmitEventPopupScene = preload("res://addons/signal_flow/ui/EmitEventPopup.tscn")

var emit_event_button: Button
var subscribe_button: Button
var new_event_dialog: ConfirmationDialog
var event_name_edit: LineEdit
var file_dialog: FileDialog
var select_existing_event_dialog: ConfirmationDialog
var event_resource_picker: EditorResourcePicker

var inspected_node: Node
var editor_interface: EditorInterface
var main_plugin: EditorPlugin
var _selection_mode: String = ""
var _emit_event_popup: PopupPanel # We will now instantiate this lazily

func _ready():
	# Get node references manually to make initialization order robust
	emit_event_button = $HBoxContainer/EmitEventButton
	subscribe_button = $HBoxContainer/SubscribeButton
	new_event_dialog = $NewEventDialog
	event_name_edit = $NewEventDialog/VBoxContainer/EventNameEdit
	file_dialog = $FileDialog
	select_existing_event_dialog = $SelectExistingEventDialog
	event_resource_picker = $SelectExistingEventDialog/VBoxContainer/EventResourcePicker
	event_resource_picker.base_type = "EventResource"

	# Connect signals synchronously. This is now safe because we removed await.
	emit_event_button.pressed.connect(Callable(self, "_on_emit_button_pressed"))
	subscribe_button.pressed.connect(Callable(self, "_on_subscribe_pressed"))
	new_event_dialog.confirmed.connect(Callable(self, "_on_new_event_dialog_confirmed"))
	select_existing_event_dialog.confirmed.connect(Callable(self, "_on_select_existing_event_confirmed"))

	# Set icons if the interface is already available, otherwise it will be set by the setter.
	_set_default_icon(emit_event_button)
	_set_default_icon(subscribe_button)

func _on_subscribe_pressed():
	_selection_mode = "subscribe"
	select_existing_event_dialog.popup_centered()

func _on_emit_button_pressed():
	# Lazy initialization: create the popup only if it doesn't exist yet.
	if not is_instance_valid(_emit_event_popup):
		_emit_event_popup = EmitEventPopupScene.instantiate()
		add_child(_emit_event_popup)
		# Configure immediately after adding. We don't need to wait for ready.
		_emit_event_popup.set_editor_interface(editor_interface)
		_emit_event_popup.set_inspected_node(inspected_node)
		_emit_event_popup.event_selected.connect(Callable(self, "_on_emit_event_selected"))
		_emit_event_popup.new_event_requested.connect(Callable(self, "_on_emit_new_event_requested"))

	var popup_panel_instance: PopupPanel = _emit_event_popup as PopupPanel
	if popup_panel_instance:
		var button_global_pos: Vector2 = emit_event_button.get_screen_position()
		var button_size: Vector2 = emit_event_button.size

		# Calculate the desired global position for the popup
		var popup_global_pos = button_global_pos + Vector2(0, button_size.y)

		# Show the popup at the calculated global position
		popup_panel_instance.popup(Rect2(popup_global_pos, popup_panel_instance.size))
	else:
		push_error("SignalFlow: _emit_event_popup is not a PopupPanel instance.")

func _on_emit_event_selected(resource_path: String):
	_add_export_var_to_script(_get_script_path_of_inspected_node(), resource_path.get_file().get_basename().to_snake_case(), resource_path)

func _on_emit_new_event_requested():
	new_event_dialog.popup_centered()

func _on_select_existing_event_confirmed():
	var selected_resource: Resource = event_resource_picker.get_edited_resource()
	if not selected_resource:
		push_error("SignalFlow: No event resource selected.")
		return

	if not selected_resource is EventResource:
		push_error("SignalFlow: Selected resource is not an EventResource.")
		return

	var resource_path: String = selected_resource.resource_path
	if resource_path.is_empty():
		push_error("SignalFlow: Selected EventResource has no path.")
		return

	if _selection_mode == "subscribe":
		_add_on_event_to_script(_get_script_path_of_inspected_node(), resource_path)


func _on_new_event_dialog_confirmed():
	var event_name: String = event_name_edit.text
	if event_name.is_empty():
		push_error("SignalFlow: Event name cannot be empty.")
		return

	var resource_dir: String = "res://events/"
	var resource_path: String = resource_dir + event_name.to_snake_case() + ".tres"

	if FileAccess.file_exists(resource_path):
		push_error("SignalFlow: Event resource '%s' already exists." % resource_path)
		return

	# Ensure the directory exists
	if not DirAccess.dir_exists_absolute(resource_dir):
		var error: int = DirAccess.make_dir_absolute(resource_dir)
		if error != OK:
			push_error("SignalFlow: Failed to create directory '%s': %s" % [resource_dir, error])
			return

	var new_event: EventResource = EventResource.new()
	new_event.domain = "default" # Placeholder domain
	var save_error: int = ResourceSaver.save(new_event, resource_path)
	if save_error != OK:
		push_error("SignalFlow: Failed to save new event resource: %s" % save_error)
		return

	_add_export_var_to_script(_get_script_path_of_inspected_node(), event_name.to_snake_case(), resource_path)


# Helper function to add @export var to the script
func _add_export_var_to_script(script_path: String, base_var_name: String, resource_path: String):
	if not inspected_node or not inspected_node.get_script():
		push_error("SignalFlow: No script attached to the inspected node.")
		return

	var script_code: String = ""
	var script_file: FileAccess = FileAccess.open(script_path, FileAccess.READ)
	if not script_file:
		push_error("SignalFlow: Failed to open script for modification: %s" % script_path)
		return
	script_code = script_file.get_as_text()
	script_file.close()

	var var_name: String = base_var_name
	var counter: int = 0
	while script_code.find("var %s:" % var_name) != -1: # Check if var name already exists
		counter += 1
		var_name = "%s_%d" % [base_var_name, counter]

	var new_line: String = "\n@export var %s: EventResource = preload(\"%s\") # SignalFlow Generated\n" % [var_name, resource_path]

	# Find insertion point: after extends or at top if no extends, but after class_name
	var insert_pos: int = -1
	var extends_pos: int = script_code.find("extends")
	if extends_pos != -1:
		insert_pos = script_code.find("\n", extends_pos) + 1
	else:
		var class_name_pos: int = script_code.find("class_name")
		if class_name_pos != -1:
			insert_pos = script_code.find("\n", class_name_pos) + 1
		else:
			insert_pos = 0 # Prepend if no class_name or extends

	if insert_pos != -1:
		script_code = script_code.insert(insert_pos, new_line)
	else:
		script_code += new_line # Append if insertion point not found

	script_file = FileAccess.open(script_path, FileAccess.WRITE)
	if not script_file:
		push_error("SignalFlow: Failed to save modified script: %s" % script_path)
		return
	script_file.store_string(script_code)
	script_file.close()


# Helper function to add @on_event to the script
func _add_on_event_to_script(script_path: String, event_resource_path: String):
	if not inspected_node or not inspected_node.get_script():
		push_error("SignalFlow: No script attached to the inspected node.")
		return

	var script_code: String = ""
	var script_file: FileAccess = FileAccess.open(script_path, FileAccess.READ)
	if not script_file:
		push_error("SignalFlow: Failed to open script for modification: %s" % script_path)
		return
	script_code = script_file.get_as_text()
	script_file.close()

	var event_id: String = event_resource_path.get_file().get_basename().to_snake_case() # simplified event ID for now
	var handler_name: String = "_on_%s_event" % event_id

	# Check if handler function already exists
	if script_code.find("func %s(" % handler_name) != -1:
		push_error("SignalFlow: Function '%s' already exists in script." % handler_name)
		return

	var new_content_to_add: String = "\n\n@on_event(\"%s\") # SignalFlow Generated\nfunc %s(event_data: Dictionary):\n\tpass # Event handler for %s\n" % [event_id, handler_name, event_id]

	# Find insertion point: At the end of the script.
	script_code += new_content_to_add

	script_file = FileAccess.open(script_path, FileAccess.WRITE)
	if not script_file:
		push_error("SignalFlow: Failed to save modified script: %s" % script_path)
		return
	script_file.store_string(script_code)
	script_file.close()


func _get_script_path_of_inspected_node() -> String:
	if inspected_node and inspected_node.get_script():
		return inspected_node.get_script().resource_path
	return ""


func _set_default_icon(button: Button):
	if editor_interface and button:
		var editor_theme = editor_interface.get_editor_theme()
		if editor_theme:
			var add_icon = editor_theme.get_icon("Add", "EditorIcons")
			if add_icon:
				button.icon = add_icon

func set_inspected_node(node: Node):
	inspected_node = node
	if is_instance_valid(_emit_event_popup):
		_emit_event_popup.set_inspected_node(node)

func set_editor_interface(interface: EditorInterface):
	editor_interface = interface
	if is_instance_valid(_emit_event_popup):
		_emit_event_popup.set_editor_interface(interface)
	# The panel might be ready before the interface is set.
	if is_inside_tree() and emit_event_button:
		_set_default_icon(emit_event_button)
		_set_default_icon(subscribe_button)

func set_main_plugin(plugin: EditorPlugin):
	main_plugin = plugin