extends Window

@onready var tab_container = $TabContainer
@onready var event_resource_picker = $TabContainer/FromNewEmitter/EventResourcePicker
@onready var search_line_edit = $TabContainer/FromBuiltInSignal/SearchLineEdit
@onready var signal_list = $TabContainer/FromBuiltInSignal/SignalList
@onready var create_from_signal_button = $TabContainer/FromBuiltInSignal/CreateFromSignalButton

var inspected_node: Node
var editor_interface: EditorInterface
var _all_signals: Array[Dictionary] # Cache all signals

signal event_selected(event_resource: EventResource)
signal forward_signal_event_created(event_resource: EventResource, signal_name: String)

func _ready():
	event_resource_picker.connect("resource_changed", Callable(self, "_on_resource_picker_resource_changed"))
	search_line_edit.text_changed.connect(Callable(self, "_on_search_text_changed"))
	signal_list.item_selected.connect(Callable(self, "_on_signal_list_item_selected"))
	create_from_signal_button.pressed.connect(Callable(self, "_on_create_from_signal_pressed"))
	
	# Disable button initially
	create_from_signal_button.disabled = true

func set_inspected_node(node: Node):
	inspected_node = node
	_populate_signal_list()

func set_editor_interface(interface: EditorInterface):
	editor_interface = interface

func _populate_signal_list():
	signal_list.clear()
	_all_signals.clear()
	if inspected_node:
		_all_signals = inspected_node.get_signal_list()
		_filter_signal_list("") # Populate initially with all signals

func _filter_signal_list(filter_text: String):
	signal_list.clear()
	for signal_info in _all_signals:
		var signal_name: String = signal_info["name"]
		if filter_text.is_empty() or signal_name.findn(filter_text) != -1:
			signal_list.add_item(signal_name)

func _on_resource_picker_resource_changed(resource: Resource):
	if resource is EventResource:
		event_selected.emit(resource)
		hide()

func _on_search_text_changed(text: String):
	_filter_signal_list(text)

func _on_signal_list_item_selected(index: int):
	create_from_signal_button.disabled = false

func _on_create_from_signal_pressed():
	if signal_list.get_selected_items().is_empty():
		return

	var selected_signal_name: String = signal_list.get_item_text(signal_list.get_selected_items()[0])
	
	# Generate suggested resource path
	var suggested_tres_path = _generate_event_resource_path(selected_signal_name)
	
	# Create and configure the EventResource
	var resource := EventResource.new()
	resource.domain = inspected_node.get_script().resource_path.get_file().get_basename() # Use script name as domain
	
	var save_error := ResourceSaver.save(resource, suggested_tres_path)
	if save_error != OK:
		push_error("Failed to save event resource: %s" % suggested_tres_path)
		return

	# Automatically process the newly created event
	var editor_fs = editor_interface.get_resource_filesystem()
	editor_fs.scan()
	await editor_fs.filesystem_changed
	
	forward_signal_event_created.emit(resource, selected_signal_name)
	hide()

func _generate_event_resource_path(signal_name: String) -> String:
	if not inspected_node or not inspected_node.get_script():
		return "res://events/new_event.tres" # Fallback
	
	var script_path: String = inspected_node.get_script().resource_path
	var script_base_name: String = script_path.get_file().get_basename()
	var feature_path: String = script_path.get_base_dir()
	var events_path: String = feature_path.path_join("events")
	
	# Ensure the directory exists
	DirAccess.make_dir_recursive_absolute(events_path)
	
	return events_path.path_join("%s_%s.tres" % [script_base_name.to_snake_case(), signal_name.to_snake_case()])