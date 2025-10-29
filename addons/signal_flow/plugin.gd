@tool
extends EditorPlugin

const AUTOLOADS := {
	"EventHub": "res://addons/signal_flow/core/event_hub.gd"
}

const EventGenerator = preload("res://addons/signal_flow/editor/event_generator.gd")
const SignalFlowStudioDock = preload("res://addons/signal_flow/editor/ui/SignalFlowStudioDock.tscn")
const CreateEventResourceDialog = preload("res://addons/signal_flow/editor/ui/CreateEventResourceDialog.tscn")

var inspector_plugin = preload("res://addons/signal_flow/signal_flow_inspector_plugin.gd").new()
var event_generator: EventGenerator
var signal_flow_dock: Control
var _editor_interface: EditorInterface

func _enter_tree():
	_editor_interface = get_editor_interface()
	inspector_plugin.set_editor_interface(_editor_interface)
	inspector_plugin.set_main_plugin(self)
	add_inspector_plugin(inspector_plugin)
	_manage_autoloads(true)

	# Initialize and connect EventGenerator
	event_generator = EventGenerator.new(_editor_interface)
	event_generator.generate_event_manifest()
	_editor_interface.get_resource_filesystem().filesystem_changed.connect(event_generator.generate_event_manifest)

	# Initialize and add SignalFlowStudioDock
	signal_flow_dock = SignalFlowStudioDock.instantiate()
	add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_UL, signal_flow_dock)

	# Add "Create New EventResource" to FileSystem dock context menu
	_editor_interface.add_filesystem_plugin_item("Create New EventResource", Callable(self, "_on_create_event_resource_selected"))

func _exit_tree():
	remove_inspector_plugin(inspector_plugin)
	_manage_autoloads(false)
	# Disconnect from filesystem_changed
	if _editor_interface and _editor_interface.get_resource_filesystem().filesystem_changed.is_connected(event_generator.generate_event_manifest):
		_editor_interface.get_resource_filesystem().filesystem_changed.disconnect(event_generator.generate_event_manifest)
	event_generator = null

	# Remove SignalFlowStudioDock
	if signal_flow_dock:
		remove_control_from_dock(signal_flow_dock)
		signal_flow_dock.queue_free()
		signal_flow_dock = null

	# Remove "Create New EventResource" from FileSystem dock context menu
	_editor_interface.remove_filesystem_plugin_item("Create New EventResource")

# Adds or removes the required singletons from the Autoload configuration using ProjectSettings.
func _manage_autoloads(should_add: bool):
	var changed := false
	for name in AUTOLOADS:
		var path = AUTOLOADS[name]
		var key = "autoload/%s" % name
		var value = "*" + path

		if should_add:
			# Add only if it doesn't exist or has a different path
			if not ProjectSettings.has_setting(key) or ProjectSettings.get_setting(key) != value:
				ProjectSettings.set_setting(key, value)
				changed = true
		else:
			# Remove only if it exists
			if ProjectSettings.has_setting(key):
				ProjectSettings.clear(key)
				changed = true

	if changed:
		ProjectSettings.save()
		print("SignalFlow: Autoloads configuration changed. Please restart the Godot editor to apply changes.")

func _on_create_event_resource_selected(path: String):
	var create_dialog = CreateEventResourceDialog.instantiate()
	add_child(create_dialog)
	create_dialog.set_editor_interface(_editor_interface)
	create_dialog.set_target_path(path)
	create_dialog.popup_centered()
