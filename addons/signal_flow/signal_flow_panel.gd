@tool
extends VBoxContainer

@export var collect_coin: EventResource = preload("res://events/collect_coin.tres") # SignalFlow Generated


const EventResource = preload("res://addons/signal_flow/core/event_resource.gd")
const EmitEventPopupScene = preload("res://addons/signal_flow/ui/EmitEventPopup.tscn")
const SubscribeEventPopupScene = preload("res://addons/signal_flow/ui/SubscribeEventPopup.tscn")
const BuiltinSignalDialog = preload("res://addons/signal_flow/ui/BuiltinSignalDialog.tscn")
const FileOpHelpers = preload("res://addons/signal_flow/editor/file_op_helpers.gd")
const EventGenerator = preload("res://addons/signal_flow/editor/event_generator.gd")

var emit_event_button: Button
var subscribe_button: Button
var new_event_dialog: ConfirmationDialog
var event_name_edit: LineEdit

var inspected_node: Node
var editor_interface: EditorInterface
var main_plugin: EditorPlugin
var undo_redo: EditorUndoRedoManager
var event_generator: EventGenerator # Added
var _emit_event_popup: PopupPanel
var _subscribe_event_popup: PopupPanel
var _builtin_signal_dialog: ConfirmationDialog

func _ready():
	# Get node references
	emit_event_button = $HBoxContainer/EmitEventButton
	subscribe_button = $HBoxContainer/SubscribeButton
	new_event_dialog = $NewEventDialog
	event_name_edit = $NewEventDialog/VBoxContainer/EventNameEdit

	emit_event_button.toggle_mode = true
	subscribe_button.toggle_mode = true

	# Connect signals
	emit_event_button.pressed.connect(Callable(self, "_on_emit_button_pressed"))
	subscribe_button.pressed.connect(Callable(self, "_on_subscribe_pressed"))
	new_event_dialog.confirmed.connect(Callable(self, "_on_new_event_dialog_confirmed"))

	# Set icons
	_set_default_icon(emit_event_button)
	_set_default_icon(subscribe_button)

func _on_subscribe_pressed():
	if not is_instance_valid(_subscribe_event_popup):
		_subscribe_event_popup = SubscribeEventPopupScene.instantiate()
		add_child(_subscribe_event_popup)
		_subscribe_event_popup.event_selected.connect(Callable(self, "_on_subscribe_event_selected"))
		_subscribe_event_popup.popup_hide.connect(Callable(self, "_on_subscribe_popup_hidden"))

	var popup_panel_instance: PopupPanel = _subscribe_event_popup as PopupPanel
	if popup_panel_instance:
		var button_global_pos: Vector2 = subscribe_button.get_screen_position()
		var button_size: Vector2 = subscribe_button.size
		var popup_global_pos = button_global_pos + Vector2(0, button_size.y)
		popup_panel_instance.popup(Rect2(popup_global_pos, popup_panel_instance.size))

func _on_emit_button_pressed():
	if not is_instance_valid(_emit_event_popup):
		_emit_event_popup = EmitEventPopupScene.instantiate()
		add_child(_emit_event_popup)
		_emit_event_popup.set_editor_interface(editor_interface)
		_emit_event_popup.set_inspected_node(inspected_node)
		_emit_event_popup.event_selected.connect(Callable(self, "_on_emit_event_selected"))
		_emit_event_popup.new_event_requested.connect(Callable(self, "_on_emit_new_event_requested"))
		_emit_event_popup.builtin_signal_requested.connect(Callable(self, "_on_builtin_signal_requested"))
		_emit_event_popup.popup_hide.connect(Callable(self, "_on_emit_popup_hidden"))

	var popup_panel_instance: PopupPanel = _emit_event_popup as PopupPanel
	if popup_panel_instance:
		var button_global_pos: Vector2 = emit_event_button.get_screen_position()
		var button_size: Vector2 = emit_event_button.size
		var popup_global_pos = button_global_pos + Vector2(0, button_size.y)
		popup_panel_instance.popup(Rect2(popup_global_pos, popup_panel_instance.size))

func _on_emit_popup_hidden():
	emit_event_button.button_pressed = false

func _on_subscribe_popup_hidden():
	subscribe_button.button_pressed = false

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

	if not undo_redo:
		push_error("SignalFlow: UndoRedo manager not available.")
		return

	# 1. Generate paths and names
	var script_base_name = script_path.get_file().get_basename()
	var feature_path = script_path.get_base_dir()
	var events_dir = feature_path.path_join("events")
	var resource_path = events_dir.path_join("%s_%s.tres" % [script_base_name.to_snake_case(), signal_name.to_snake_case()])

	if FileAccess.file_exists(resource_path):
		push_warning("SignalFlow: Event resource for this signal already exists at %s" % resource_path)
		return

	# 2. Prepare script modification
	var file = FileAccess.open(script_path, FileAccess.READ)
	if not file:
		push_error("SignalFlow: Failed to open script for reading: %s" % script_path)
		return
	var old_content = file.get_as_text()
	file.close()

	var annotation_line = "\n@forward_signal(\"%s\", \"%s\") # SignalFlow Generated\n" % [signal_name, resource_path]
	var result = _insert_after_extends(old_content, annotation_line)
	var new_content = result.content
	var new_line_number = result.line_number

	# 3. Create the resource instance
	var new_event = EventResource.new()
	new_event.domain = script_base_name.to_snake_case()

	# 4. Register with UndoRedo
	undo_redo.create_action("SignalFlow: Forward Built-in Signal")
	# Resource operations
	undo_redo.add_do_method(ResourceSaver, "save", new_event, resource_path)
	undo_redo.add_undo_method(FileOpHelpers, "delete_file", resource_path)
	# Script operations
	undo_redo.add_do_method(FileOpHelpers, "write_text_to_file", script_path, new_content)
	undo_redo.add_undo_method(FileOpHelpers, "write_text_to_file", script_path, old_content)
	# Commit
	undo_redo.commit_action()

	# 5. Feedback
	print("SignalFlow: Forwarded signal '%s' to event '%s'" % [signal_name, resource_path.get_file()])
	editor_interface.edit_script(load(script_path), new_line_number, 0)
	if event_generator:
		event_generator.generate_event_manifest() # Trigger manifest regeneration

func _on_emit_event_selected(resource: EventResource):
	_add_export_var_to_script(_get_script_path_of_inspected_node(), resource.resource_path.get_file().get_basename().to_snake_case(), resource.resource_path)

func _on_subscribe_event_selected(resource: EventResource):
	if not resource is EventResource:
		push_error("SignalFlow: Selected resource is not an EventResource.")
		return

	var resource_path: String = resource.resource_path
	if resource_path.is_empty():
		push_error("SignalFlow: Selected EventResource has no path.")
		return

	_add_on_event_to_script(_get_script_path_of_inspected_node(), resource_path)

func _on_emit_new_event_requested():
	new_event_dialog.popup_centered()

func _on_new_event_dialog_confirmed():
	var event_name: String = event_name_edit.text
	if event_name.is_empty(): return

	var resource_dir: String = "res://events/"
	var resource_path: String = resource_dir + event_name.to_snake_case() + ".tres"

	if FileAccess.file_exists(resource_path):
		push_warning("SignalFlow: Event resource already exists at %s" % resource_path)
		return

	var script_path = _get_script_path_of_inspected_node()
	if script_path.is_empty():
		push_error("SignalFlow: Cannot add event emitter, inspected node has no script.")
		return

	if not undo_redo:
		push_error("SignalFlow: UndoRedo manager not available.")
		return

	# 1. Preparation
	var file = FileAccess.open(script_path, FileAccess.READ)
	if not file:
		push_error("SignalFlow: Failed to open script for reading: %s" % script_path)
		return
	var old_content = file.get_as_text()
	file.close()

	# 2. Generate new script content
	var base_var_name = event_name.to_snake_case()
	var var_name: String = base_var_name
	var counter: int = 0
	while old_content.find("var %s:" % var_name) != -1:
		counter += 1
		var_name = "%s_%d" % [base_var_name, counter]

	var new_line = "\n@export var %s: EventResource = preload(\"%s\") # SignalFlow Generated\n" % [var_name, resource_path]
	var result = _insert_after_extends(old_content, new_line)
	var new_content = result.content
	var new_line_number = result.line_number

	# 3. Create the resource instance
	var new_event: EventResource = EventResource.new()
	new_event.domain = "default"

	# 4. Register with UndoRedo
	undo_redo.create_action("SignalFlow: Create and Emit Event")
	# Resource operations
	undo_redo.add_do_method(ResourceSaver, "save", new_event, resource_path)
	undo_redo.add_undo_method(FileOpHelpers, "delete_file", resource_path)
	# Script operations
	undo_redo.add_do_method(FileOpHelpers, "write_text_to_file", script_path, new_content)
	undo_redo.add_undo_method(FileOpHelpers, "write_text_to_file", script_path, old_content)
	# Commit
	undo_redo.commit_action()

	# 5. Feedback
	print("SignalFlow: Created event '%s' and added emitter to script." % resource_path.get_file())
	editor_interface.edit_script(load(script_path), new_line_number, 0)
	if event_generator:
		event_generator.generate_event_manifest() # Trigger manifest regeneration

# --- Script Modification Helpers ---

func _add_export_var_to_script(script_path: String, base_var_name: String, resource_path: String):
	if not undo_redo:
		push_error("SignalFlow: UndoRedo manager not available.")
		return

	var file = FileAccess.open(script_path, FileAccess.READ)
	if not file:
		push_error("SignalFlow: Failed to open script for reading: %s" % script_path)
		return
	var old_content = file.get_as_text()
	file.close()

	var var_name: String = base_var_name
	var counter: int = 0
	while old_content.find("var %s:" % var_name) != -1:
		counter += 1
		var_name = "%s_%d" % [base_var_name, counter]

	var new_line = "\n@export var %s: EventResource = preload(\"%s\") # SignalFlow Generated\n" % [var_name, resource_path]
	var result = _insert_after_extends(old_content, new_line)
	var new_content = result.content
	var new_line_number = result.line_number

	undo_redo.create_action("SignalFlow: Add Event Emitter")
	undo_redo.add_do_method(FileOpHelpers, "write_text_to_file", script_path, new_content)
	undo_redo.add_undo_method(FileOpHelpers, "write_text_to_file", script_path, old_content)
	undo_redo.commit_action()

	print("SignalFlow: Added event emitter '%s' to script '%s'" % [var_name, script_path.get_file()])
	editor_interface.edit_script(load(script_path), new_line_number, 0)
	if event_generator:
		event_generator.generate_event_manifest() # Trigger manifest regeneration

func _add_on_event_to_script(script_path: String, event_resource_path: String):
	if not undo_redo:
		push_error("SignalFlow: UndoRedo manager not available.")
		return

	var file = FileAccess.open(script_path, FileAccess.READ)
	if not file:
		push_error("SignalFlow: Failed to open script for reading: %s" % script_path)
		return
	var old_content = file.get_as_text()
	file.close()

	var event_id: String = event_resource_path.get_file().get_basename().to_snake_case()
	var handler_name: String = "_on_%s_event" % event_id

	if old_content.find("func %s(" % handler_name) != -1:
		push_warning("SignalFlow: Handler function '%s' already exists." % handler_name)
		return

	var new_code_block = "\n\n@on_event(\"%s\") # SignalFlow Generated\nfunc %s(event_data: Dictionary):\n\tpass # Event handler for %s\n" % [event_id, handler_name, event_id]
	var new_content = old_content + new_code_block
	var new_line_number = old_content.get_line_count() + 1

	undo_redo.create_action("SignalFlow: Add Event Handler")
	undo_redo.add_do_method(FileOpHelpers, "write_text_to_file", script_path, new_content)
	undo_redo.add_undo_method(FileOpHelpers, "write_text_to_file", script_path, old_content)
	undo_redo.commit_action()

	print("SignalFlow: Added event handler '%s' to script '%s'" % [handler_name, script_path.get_file()])
	editor_interface.edit_script(load(script_path), new_line_number, 0)
	if event_generator:
		event_generator.generate_event_manifest() # Trigger manifest regeneration

func _insert_after_extends(content: String, line_to_insert: String) -> Dictionary:
	var lines := content.split("\n")
	for i in range(lines.size()):
		if lines[i].begins_with("extends"):
			lines.insert(i + 1, line_to_insert)
			return { "content": "\n".join(lines), "line_number": i + 2 }
	# Fallback if extends is not found
	lines.insert(1, line_to_insert)
	return { "content": "\n".join(lines), "line_number": 2 }

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

func set_undo_redo(ur: EditorUndoRedoManager):
	undo_redo = ur

func set_event_generator(generator: EventGenerator):
	event_generator = generator