@tool
extends EditorPlugin

const AUTOLOADS := {
	"EventHub": "res://addons/signal_flow/core/event_hub.gd"
}

const EventGenerator = preload("res://addons/signal_flow/editor/event_generator.gd")
#const SignalFlowStudioDock = preload("res://addons/signal_flow/editor/ui/SignalFlowStudioDock.tscn")
const CreateEventResourceDialog = preload("res://addons/signal_flow/editor/ui/CreateEventResourceDialog.tscn")
#const ContextMenuPlugin = preload("res://addons/signal_flow/editor/context_menu_plugin.gd")

var inspector_plugin = preload("res://addons/signal_flow/signal_flow_inspector_plugin.gd").new()
var event_generator: EventGenerator
#var context_menu_plugin
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

	# Initialize and add Context Menu Plugin
	#context_menu_plugin = ContextMenuPlugin.new()
	#context_menu_plugin.main_plugin = self
	#add_context_menu_plugin(context_menu_plugin, "FileSystemDock")

func _exit_tree():
	remove_inspector_plugin(inspector_plugin)
	_manage_autoloads(false)
	
	# Disconnect from filesystem_changed
	if _editor_interface and _editor_interface.get_resource_filesystem().filesystem_changed.is_connected(event_generator.generate_event_manifest):
		_editor_interface.get_resource_filesystem().filesystem_changed.disconnect(event_generator.generate_event_manifest)
	event_generator = null

	# Remove Context Menu Plugin
	#if context_menu_plugin:
	#	remove_context_menu_plugin(context_menu_plugin)
	#	context_menu_plugin = null

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
