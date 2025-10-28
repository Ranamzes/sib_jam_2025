@tool
extends EditorPlugin

const AUTOLOADS := {
	"EventHub": "res://addons/signal_flow/core/event_hub.gd"
}

var inspector_plugin = preload("res://addons/signal_flow/signal_flow_inspector_plugin.gd").new()

func _enter_tree():
	var editor_interface_ref = get_editor_interface()
	inspector_plugin.set_editor_interface(editor_interface_ref)
	inspector_plugin.set_main_plugin(self) # Pass the main plugin reference
	add_inspector_plugin(inspector_plugin)
	_manage_autoloads(true)

func _exit_tree():
	remove_inspector_plugin(inspector_plugin)
	_manage_autoloads(false)

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
