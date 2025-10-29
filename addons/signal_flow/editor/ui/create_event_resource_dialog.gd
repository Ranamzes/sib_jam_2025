class_name CreateEventResourceDialog
extends ConfirmationDialog

const EventResource = preload("res://addons/signal_flow/core/event_resource.gd")

@onready var event_name_edit = $VBoxContainer/EventNameEdit
@onready var domain_edit = $VBoxContainer/DomainEdit

var editor_interface: EditorInterface
var _target_path: String

func _ready():
	confirmed.connect(Callable(self, "_on_confirmed"))

func set_editor_interface(interface: EditorInterface):
	editor_interface = interface

func set_target_path(path: String):
	_target_path = path
	# Suggest domain based on folder name
	domain_edit.text = path.get_file()

func _on_confirmed():
	if not editor_interface:
		push_error("EditorInterface not set.")
		return

	var event_name: String = event_name_edit.text
	var domain_name: String = domain_edit.text

	if event_name.is_empty() or not event_name.is_valid_identifier():
		push_error("Event name is not a valid identifier.")
		return
	if domain_name.is_empty() or not domain_name.is_valid_identifier():
		push_error("Domain name is not a valid identifier.")
		return

	var events_path: String = _target_path.path_join("events")
	DirAccess.make_dir_recursive_absolute(events_path)

	var snake_name: String = _to_snake_case(event_name)
	var tres_path: String = events_path.path_join("%s.tres" % snake_name)

	var resource := EventResource.new()
	resource.domain = domain_name

	var save_error := ResourceSaver.save(resource, tres_path)
	if save_error != OK:
		push_error("Failed to save event resource: %s" % tres_path)
		return

	var editor_fs = editor_interface.get_resource_filesystem()
	editor_fs.scan()
	await editor_fs.filesystem_changed
	
	print("SignalFlow: Created new EventResource: %s" % tres_path)
	hide()

func _to_snake_case(pascal_string: String) -> String:
	var snake_string := ""
	for i in range(pascal_string.length()):
		var char := pascal_string[i]
		if (char == char.to_upper() and char != char.to_lower()) and i > 0:
			snake_string += "_"
		snake_string += char.to_lower()
	return snake_string