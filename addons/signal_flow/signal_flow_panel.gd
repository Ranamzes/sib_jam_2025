@tool
extends VBoxContainer

const EventResource = preload("res://addons/signal_flow/core/event_resource.gd")
const EmitEventPopupScene = preload("res://addons/signal_flow/ui/EmitEventPopup.tscn")
const BuiltinSignalDialog = preload("res://addons/signal_flow/ui/BuiltinSignalDialog.tscn")

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
var _emit_event_popup: PopupPanel
var _builtin_signal_dialog: ConfirmationDialog

func _ready():
	# Get node references
	emit_event_button = $HBoxContainer/EmitEventButton
	subscribe_button = $HBoxContainer/SubscribeButton
	new_event_dialog = $NewEventDialog
	event_name_edit = $NewEventDialog/VBoxContainer/EventNameEdit
	file_dialog = $FileDialog
	select_existing_event_dialog = $SelectExistingEventDialog
	event_resource_picker = $SelectExistingEventDialog/VBoxContainer/EventResourcePicker
	event_resource_picker.base_type = "EventResource"

	# Connect signals
	emit_event_button.pressed.connect(Callable(self, "_on_emit_button_pressed"))
	subscribe_button.pressed.connect(Callable(self, "_on_subscribe_pressed"))
	new_event_dialog.confirmed.connect(Callable(self, "_on_new_event_dialog_confirmed"))
	select_existing_event_dialog.confirmed.connect(Callable(self, "_on_select_existing_event_confirmed"))

	# Set icons
	_set_default_icon(emit_event_button)
	_set_default_icon(subscribe_button)

func _on_subscribe_pressed():
	_selection_mode = "subscribe"
	select_existing_event_dialog.popup_centered()

func _on_emit_button_pressed():
	if not is_instance_valid(_emit_event_popup):
		_emit_event_popup = EmitEventPopupScene.instantiate()
		add_child(_emit_event_popup)
		_emit_event_popup.set_editor_interface(editor_interface)
		_emit_event_popup.set_inspected_node(inspected_node)
		_emit_event_popup.event_selected.connect(Callable(self, "_on_emit_event_selected"))
		_emit_event_popup.new_event_requested.connect(Callable(self, "_on_emit_new_event_requested"))
		_emit_event_popup.builtin_signal_requested.connect(Callable(self, "_on_builtin_signal_requested"))

	var popup_panel_instance: PopupPanel = _emit_event_popup as PopupPanel
	if popup_panel_instance:
		var button_global_pos: Vector2 = emit_event_button.get_screen_position()
		var button_size: Vector2 = emit_event_button.size
		var popup_global_pos = button_global_pos + Vector2(0, button_size.y)
		popup_panel_instance.popup(Rect2(popup_global_pos, popup_panel_instance.size))

func _on_builtin_signal_requested():
	if not is_instance_valid(_builtin_signal_dialog):
		_builtin_signal_dialog = BuiltinSignalDialog.instantiate()
		add_child(_builtin_signal_dialog)
		_builtin_signal_dialog.signal_selected.connect(Callable(self, "_on_builtin_signal_selected"))
	
	_builtin_signal_dialog.popup_dialog(inspected_node)

func _on_builtin_signal_selected(signal_name: String):
	var script_path = _get_script_path_of_inspected_node()
	if script_path.is_empty():
		push_error("SignalFlow: Inspected node has no script.")
		return

	# 1. Generate paths and names
	var script_base_name = script_path.get_file().get_basename()
	var feature_path = script_path.get_base_dir()
	var events_dir = feature_path.path_join("events")
	DirAccess.make_dir_recursive_absolute(events_dir)
	var resource_path = events_dir.path_join("%s_%s.tres" % [script_base_name.to_snake_case(), signal_name.to_snake_case()])

	# 2. Create and save the resource
	var new_event = EventResource.new()
	new_event.domain = script_base_name.to_snake_case()
	var save_error = ResourceSaver.save(new_event, resource_path)
	if save_error != OK:
		push_error("SignalFlow: Failed to save event resource: %s" % resource_path)
		return

	# 3. Add the @forward_signal annotation to the script
	var file = FileAccess.open(script_path, FileAccess.READ)
	if not file:
		push_error("SignalFlow: Failed to open script for reading: %s" % script_path)
		return
	var script_code = file.get_as_text()
	file.close()

	var annotation_line = "\n@forward_signal(\"%s\", \"%s\") # SignalFlow Generated\n" % [signal_name, resource_path]
	script_code = _insert_after_extends(script_code, annotation_line)
	
	var write_file = FileAccess.open(script_path, FileAccess.WRITE)
	if not write_file:
		push_error("SignalFlow: Failed to open script for writing: %s" % script_path)
		return
	write_file.store_string(script_code)
	write_file.close()

	# 4. Reload the script and inspector
	var editor_fs = editor_interface.get_resource_filesystem()
	editor_fs.scan()
	await editor_fs.filesystem_changed
	inspected_node.set_script(load(script_path))
	editor_interface.inspect_object(inspected_node)

func _on_emit_event_selected(resource: EventResource):
	_add_export_var_to_script(_get_script_path_of_inspected_node(), resource.resource_path.get_file().get_basename().to_snake_case(), resource.resource_path)

func _on_emit_new_event_requested():
	new_event_dialog.popup_centered()

func _on_select_existing_event_confirmed():
	var selected_resource: Resource = event_resource_picker.get_edited_resource()
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
	if event_name.is_empty(): return

	var resource_dir: String = "res://events/"
	var resource_path: String = resource_dir + event_name.to_snake_case() + ".tres"

	if FileAccess.file_exists(resource_path): return

	DirAccess.make_dir_recursive_absolute(resource_dir)

	var new_event: EventResource = EventResource.new()
	new_event.domain = "default"
	ResourceSaver.save(new_event, resource_path)

	_add_export_var_to_script(_get_script_path_of_inspected_node(), event_name.to_snake_case(), resource_path)

# --- Script Modification Helpers ---

func _add_export_var_to_script(script_path: String, base_var_name: String, resource_path: String):
	var file = FileAccess.open(script_path, FileAccess.READ)
	if not file:
		push_error("SignalFlow: Failed to open script for reading: %s" % script_path)
		return
	var script_code = file.get_as_text()
	file.close()

	var var_name: String = base_var_name
	var counter: int = 0
	while script_code.find("var %s:" % var_name) != -1:
		counter += 1
		var_name = "%s_%d" % [base_var_name, counter]

	var new_line = "\n@export var %s: EventResource = preload(\"%s\") # SignalFlow Generated\n" % [var_name, resource_path]
	script_code = _insert_after_extends(script_code, new_line)
	
	var write_file = FileAccess.open(script_path, FileAccess.WRITE)
	if not write_file:
		push_error("SignalFlow: Failed to open script for writing: %s" % script_path)
		return
	write_file.store_string(script_code)
	write_file.close()

func _add_on_event_to_script(script_path: String, event_resource_path: String):
	var file = FileAccess.open(script_path, FileAccess.READ)
	if not file:
		push_error("SignalFlow: Failed to open script for reading: %s" % script_path)
		return
	var script_code = file.get_as_text()
	file.close()

	var event_id: String = event_resource_path.get_file().get_basename().to_snake_case()
	var handler_name: String = "_on_%s_event" % event_id

	if script_code.find("func %s(" % handler_name) != -1: return

	var new_content = "\n\n@on_event(\"%s\") # SignalFlow Generated\nfunc %s(event_data: Dictionary):\n\tpass # Event handler for %s\n" % [event_id, handler_name, event_id]
	script_code += new_content
	
	var write_file = FileAccess.open(script_path, FileAccess.WRITE)
	if not write_file:
		push_error("SignalFlow: Failed to open script for writing: %s" % script_path)
		return
	write_file.store_string(script_code)
	write_file.close()

func _insert_after_extends(content: String, line_to_insert: String) -> String:
	var lines := content.split("\n")
	for i in range(lines.size()):
		if lines[i].begins_with("extends"):
			lines.insert(i + 1, line_to_insert)
			return "\n".join(lines)
	# Fallback if extends is not found
	lines.insert(1, line_to_insert)
	return "\n".join(lines)

func _get_script_path_of_inspected_node() -> String:
	if inspected_node and inspected_node.get_script():
		return inspected_node.get_script().resource_path
	return ""

# --- UI Setup Helpers ---

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
	if is_inside_tree() and emit_event_button:
		_set_default_icon(emit_event_button)
		_set_default_icon(subscribe_button)

func set_main_plugin(plugin: EditorPlugin):
	main_plugin = plugin