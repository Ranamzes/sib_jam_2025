@tool
extends VBoxContainer

@onready var emit_button = $HBoxContainer/EmitButton
@onready var subscribe_button = $HBoxContainer/SubscribeButton
@onready var file_dialog = $FileDialog
@onready var new_event_dialog = $NewEventDialog
@onready var event_name_edit = $NewEventDialog/VBoxContainer/EventNameEdit

var inspected_node: Node
var editor_interface: EditorInterface
var _mode: String # "emit" or "subscribe"
var _action_menu: PopupMenu

func _ready():
	_action_menu = PopupMenu.new()
	_action_menu.add_item("Select Existing Event", 0)
	_action_menu.add_item("Create New Event", 1)
	_action_menu.id_pressed.connect(_on_action_menu_id_pressed)
	add_child(_action_menu)

	emit_button.pressed.connect(_on_emit_pressed)
	subscribe_button.pressed.connect(_on_subscribe_pressed)
	file_dialog.file_selected.connect(_on_file_selected)
	new_event_dialog.confirmed.connect(_on_new_event_confirmed)

func set_inspected_node(node: Node):
	inspected_node = node

func set_editor_interface(interface: EditorInterface):
	editor_interface = interface

func _on_emit_pressed():
	_mode = "emit"
	_action_menu.popup_on_parent(Rect2(get_global_mouse_position(), _action_menu.size))

func _on_subscribe_pressed():
	_mode = "subscribe"
	_action_menu.popup_on_parent(Rect2(get_global_mouse_position(), _action_menu.size))

func _on_action_menu_id_pressed(id: int):
	if id == 0:
		_open_file_dialog()
	elif id == 1:
		_open_new_event_dialog()

func _open_file_dialog():
	file_dialog.popup_centered()

func _open_new_event_dialog():
	event_name_edit.clear()
	new_event_dialog.popup_centered()

func _on_file_selected(path: String):
	_process_event(path)

func _on_new_event_confirmed():
	if not editor_interface:
		push_error("EditorInterface not set.")
		return

	var event_name: String = event_name_edit.text
	if event_name.is_empty() or not event_name.is_valid_identifier():
		push_error("Event name is not a valid identifier.")
		return

	# New logic to determine path and domain
	var scene_root = editor_interface.get_edited_scene_root()
	if not scene_root or scene_root.scene_file_path.is_empty():
		push_error("Could not determine scene path. Save the scene first.")
		return
	
	var feature_path: String = scene_root.scene_file_path.get_base_dir()
	var events_path: String = feature_path.path_join("events")
	var domain_name: String = feature_path.get_file()

	# Ensure the directory exists
	DirAccess.make_dir_recursive_absolute(events_path)

	var snake_name: String = _to_snake_case(event_name)
	var tres_path: String = events_path.path_join("%s.tres" % snake_name)

	# Create and configure the EventResource
	var resource := EventResource.new()
	resource.domain = domain_name

	var save_error := ResourceSaver.save(resource, tres_path)
	if save_error != OK:
		push_error("Failed to save event resource: %s" % tres_path)
		return

	# Automatically process the newly created event
	var editor_fs = editor_interface.get_resource_filesystem()
	editor_fs.scan()
	await editor_fs.filesystem_changed
	_process_event(tres_path)

func _process_event(event_path: String):
	if inspected_node == null or inspected_node.get_script() == null:
		return
	if not editor_interface:
		push_error("EditorInterface not set.")
		return

	var script_path: String = inspected_node.get_script().resource_path
	var script_file := FileAccess.open(script_path, FileAccess.READ)
	if not script_file:
		push_error("Failed to open script: %s" % script_path)
		return
	var script_content := script_file.get_as_text()
	script_file.close()

	var event_resource: EventResource = load(event_path)
	if not event_resource:
		push_error("Failed to load event resource: %s" % event_path)
		return

	var var_name := _to_snake_case(event_resource.resource_path.get_file().get_basename()) + "_event"

	var export_line := "\n@export var %s: EventResource" % var_name
	if not export_line in script_content:
		script_content = _insert_after_extends(script_content, export_line)

	if _mode == "subscribe":
		var event_identifier = "%s_%s" % [event_resource.domain, event_resource.resource_path.get_file().get_basename()]
		var func_name := "_on_%s" % event_identifier
		var annotation_line := "@on_event(\"%s\")" % event_identifier
		var func_body := "\n%s\nfunc %s(payload):\n\tpass # TODO: Implement logic" % [annotation_line, func_name]
		if not ("func %s(" % func_name) in script_content:
			script_content += func_body

	var file_access_write := FileAccess.open(script_path, FileAccess.WRITE)
	if file_access_write:
		file_access_write.store_string(script_content)
		file_access_write.close()
	else:
		push_error("Failed to write to script: %s" % script_path)
		return

	var editor_fs = editor_interface.get_resource_filesystem()
	editor_fs.scan()
	await editor_fs.filesystem_changed

	var reloaded_script = load(script_path)
	inspected_node.set_script(reloaded_script)

	# Automatically assign the resource to the exported variable
	if inspected_node.has_method("set"):
		inspected_node.set(var_name, event_resource)
		# Mark the scene as changed to prompt saving
		if editor_interface.get_edited_scene_root():
			editor_interface.get_edited_scene_root().set_edited(true)

	editor_interface.inspect_object(inspected_node)


# --- Helper Functions ---

func _to_snake_case(pascal_string: String) -> String:
	var snake_string := ""
	for i in range(pascal_string.length()):
		var char := pascal_string[i]
		if (char == char.to_upper() and char != char.to_lower()) and i > 0:
			snake_string += "_"
		snake_string += char.to_lower()
	return snake_string

func _insert_after_extends(content: String, line_to_insert: String) -> String:
	var lines := content.split("\n")
	for i in range(lines.size()):
		if lines[i].begins_with("extends"):
			lines.insert(i + 1, line_to_insert)
			return "\n".join(lines)
	lines.insert(1, line_to_insert)
	return "\n".join(lines)
