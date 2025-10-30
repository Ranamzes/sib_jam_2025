@tool
extends VBoxContainer

const EventResource = preload("res://addons/signal_flow/core/event_resource.gd")

@onready var emit_button: MenuButton = $HBoxContainer/EmitButton
@onready var subscribe_button: Button = $HBoxContainer/SubscribeButton
@onready var new_event_dialog = $NewEventDialog
@onready var event_name_edit = $NewEventDialog/VBoxContainer/EventNameEdit
@onready var file_dialog = $FileDialog
@onready var select_existing_event_dialog = $SelectExistingEventDialog
@onready var event_resource_picker = $SelectExistingEventDialog/VBoxContainer/EventResourcePicker

var inspected_node: Node
var editor_interface: EditorInterface
var main_plugin: EditorPlugin
var _selection_mode = "" # Renamed from _file_dialog_mode

func _ready():
	# Copy style from a real button to make the MenuButton look the same
	emit_button.add_theme_stylebox_override("normal", subscribe_button.get_theme_stylebox("normal"))
	emit_button.add_theme_stylebox_override("hover", subscribe_button.get_theme_stylebox("hover"))
	emit_button.add_theme_stylebox_override("pressed", subscribe_button.get_theme_stylebox("pressed"))
	emit_button.add_theme_stylebox_override("disabled", subscribe_button.get_theme_stylebox("disabled"))

	_set_default_icon(emit_button)
	_set_default_icon(subscribe_button)

	subscribe_button.pressed.connect(Callable(self, "_on_subscribe_pressed"))
	# file_dialog.file_selected.connect(_on_file_selected) # No longer used for existing event selection
	new_event_dialog.confirmed.connect(Callable(self, "_on_new_event_dialog_confirmed"))

	select_existing_event_dialog.confirmed.connect(Callable(self, "_on_select_existing_event_confirmed"))

	var emit_popup_menu = emit_button.get_popup()
	emit_popup_menu.clear() # Prevent duplication
	emit_popup_menu.add_item("New Event...", 0)
	emit_popup_menu.add_item("Existing Event...", 1)
	emit_popup_menu.id_pressed.connect(Callable(self, "_on_emit_menu_id_pressed"))


func _on_subscribe_pressed():
	_selection_mode = "subscribe"
	select_existing_event_dialog.popup_centered()

func _on_emit_menu_id_pressed(id):
	match id:
		0: # New Event...
			new_event_dialog.popup_centered()
		1: # Existing Event...
			_selection_mode = "emit"
			select_existing_event_dialog.popup_centered()

# This function is no longer used for existing event selection via FileDialog
# func _on_file_selected(path: String):
# 	if path.is_empty():
# 		print("File selection canceled.")
# 		return

# 	if _selection_mode == "subscribe":
# 		print("Selected event resource for subscription: ", path)
# 		_add_on_event_to_script(_get_script_path_of_inspected_node(), path)
# 	elif _selection_mode == "emit":
# 		print("Selected event resource for emit: ", path)
# 		_add_export_var_to_script(_get_script_path_of_inspected_node(), path.get_file().get_basename().to_snake_case(), path)

func _on_select_existing_event_confirmed():
	var selected_resource = event_resource_picker.get_edited_resource()
	if not selected_resource:
		push_error("SignalFlow: No event resource selected.")
		return

	if not selected_resource is EventResource:
		push_error("SignalFlow: Selected resource is not an EventResource.")
		return

	var resource_path = selected_resource.resource_path
	if resource_path.is_empty():
		push_error("SignalFlow: Selected EventResource has no path.")
		return

	if _selection_mode == "subscribe":
		print("Selected event resource for subscription: ", resource_path)
		_add_on_event_to_script(_get_script_path_of_inspected_node(), resource_path)
	elif _selection_mode == "emit":
		print("Selected event resource for emit: ", resource_path)
		_add_export_var_to_script(_get_script_path_of_inspected_node(), resource_path.get_file().get_basename().to_snake_case(), resource_path)


func _on_new_event_dialog_confirmed():
	var event_name = event_name_edit.text
	if event_name.is_empty():
		push_error("SignalFlow: Event name cannot be empty.")
		return

	var resource_dir = "res://events/"
	var resource_path = resource_dir + event_name.to_snake_case() + ".tres"

	if FileAccess.file_exists(resource_path):
		push_error("SignalFlow: Event resource '%s' already exists." % resource_path)
		return

	# Ensure the directory exists
	if not DirAccess.dir_exists_absolute(resource_dir):
		var error = DirAccess.make_dir_absolute(resource_dir)
		if error != OK:
			push_error("SignalFlow: Failed to create directory '%s': %s" % [resource_dir, error])
			return

	var new_event = EventResource.new()
	new_event.domain = "default" # Placeholder domain
	var save_error = ResourceSaver.save(new_event, resource_path)
	if save_error != OK:
		push_error("SignalFlow: Failed to save new event resource: %s" % save_error)
		return

	print("SignalFlow: Created new event resource: %s" % resource_path)
	_add_export_var_to_script(_get_script_path_of_inspected_node(), event_name.to_snake_case(), resource_path)


# Helper function to add @export var to the script
func _add_export_var_to_script(script_path: String, base_var_name: String, resource_path: String):
	if not inspected_node or not inspected_node.get_script():
		push_error("SignalFlow: No script attached to the inspected node.")
		return

	var script_code = ""
	var script_file = FileAccess.open(script_path, FileAccess.READ)
	if not script_file:
		push_error("SignalFlow: Failed to open script for modification: %s" % script_path)
		return
	script_code = script_file.get_as_text()
	script_file.close()

	var var_name = base_var_name
	var counter = 0
	while script_code.find("var %s:" % var_name) != -1: # Check if var name already exists
		counter += 1
		var_name = "%s_%d" % [base_var_name, counter]

	var new_line = "\n@export var %s: EventResource = preload(\"%s\") # SignalFlow Generated\n" % [var_name, resource_path]

	# Find insertion point: after extends or at top if no extends, but after class_name
	var insert_pos = -1
	var extends_pos = script_code.find("extends")
	if extends_pos != -1:
		insert_pos = script_code.find("\n", extends_pos) + 1
	else:
		var class_name_pos = script_code.find("class_name")
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
	print("SignalFlow: Added export var '%s' to script '%s'." % [var_name, script_path])


# Helper function to add @on_event to the script
func _add_on_event_to_script(script_path: String, event_resource_path: String):
	if not inspected_node or not inspected_node.get_script():
		push_error("SignalFlow: No script attached to the inspected node.")
		return

	var script_code = ""
	var script_file = FileAccess.open(script_path, FileAccess.READ)
	if not script_file:
		push_error("SignalFlow: Failed to open script for modification: %s" % script_path)
		return
	script_code = script_file.get_as_text()
	script_file.close()

	var event_id = event_resource_path.get_file().get_basename().to_snake_case() # simplified event ID for now
	var handler_name = "_on_%s_event" % event_id

	# Check if handler function already exists
	if script_code.find("func %s(" % handler_name) != -1:
		push_error("SignalFlow: Function '%s' already exists in script." % handler_name)
		return

	var new_content_to_add = "\n\n@on_event(\"%s\") # SignalFlow Generated\nfunc %s(event_data: Dictionary):\n\tpass # Event handler for %s\n" % [event_id, handler_name, event_id]

	# Find insertion point: At the end of the script.
	script_code += new_content_to_add

	script_file = FileAccess.open(script_path, FileAccess.WRITE)
	if not script_file:
		push_error("SignalFlow: Failed to save modified script: %s" % script_path)
		return
	script_file.store_string(script_code)
	script_file.close()
	print("SignalFlow: Added @on_event for '%s' to script '%s'." % [event_id, script_path])


func _get_script_path_of_inspected_node() -> String:
	if inspected_node and inspected_node.get_script():
		return inspected_node.get_script().resource_path
	return ""


func _set_default_icon(button: Button):
	if editor_interface:
		var editor_theme = editor_interface.get_editor_theme()
		if editor_theme:
			var add_icon = editor_theme.get_icon("Add", "EditorIcons")
			if add_icon:
				button.icon = add_icon

func set_inspected_node(node: Node):
	inspected_node = node

func set_editor_interface(interface: EditorInterface):
	editor_interface = interface
	# The panel might be ready before the interface is set.
	if is_inside_tree() and emit_button:
		_set_default_icon(emit_button)
		_set_default_icon(subscribe_button)

func set_main_plugin(plugin: EditorPlugin):
	main_plugin = plugin