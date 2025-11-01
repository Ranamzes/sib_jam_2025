@tool
extends EditorPlugin

const AUTOLOADS := {
	"EventHub": "res://addons/signal_flow/core/event_hub.gd"
}

const SignalFlowStudioDock = preload("res://addons/signal_flow/editor/ui/SignalFlowStudioDock.tscn")
const inspector_plugin = preload("res://addons/signal_flow/signal_flow_inspector_plugin.gd")
const plugin_icon = preload("res://addons/signal_flow/icon.svg")

var dock
var _inspector_plugin
var _script_create_dialog: ScriptCreateDialog
var _newly_created_scripts: Dictionary = {}

func _enter_tree():
	_inspector_plugin = inspector_plugin.new()
	_inspector_plugin.set_editor_interface(get_editor_interface())
	_inspector_plugin.set_undo_redo(get_undo_redo())
	_inspector_plugin.set_main_plugin(self)
	add_inspector_plugin(_inspector_plugin)

	dock = SignalFlowStudioDock.instantiate()
	get_editor_interface().get_editor_main_screen().add_child(dock)
	_make_visible(false)

	_script_create_dialog = ScriptCreateDialog.new()
	get_editor_interface().get_base_control().add_child(_script_create_dialog)

	_manage_autoloads(true)

func _exit_tree():
	remove_inspector_plugin(_inspector_plugin)
	if is_instance_valid(dock):
		dock.queue_free()
	if is_instance_valid(_script_create_dialog):
		_script_create_dialog.queue_free()

	_manage_autoloads(false)

func get_script_create_dialog() -> ScriptCreateDialog:
	return _script_create_dialog

func _create_file_on_disk(path: String, content: String):
	var new_script = GDScript.new()
	new_script.source_code = content
	var save_error = ResourceSaver.save(new_script, path)
	if save_error != OK:
		push_error("Failed to save script: %s" % save_error)
	get_editor_interface().get_resource_filesystem().scan_sources()


func _delete_file_from_disk(path: String):
	if ResourceLoader.exists(path):
		var global_path = ProjectSettings.globalize_path(path)
		var dir = DirAccess.open(global_path.get_base_dir())
		if dir:
			var err = dir.remove_absolute(global_path)
			if err == OK:
				get_editor_interface().get_resource_filesystem().scan_sources()
			else:
				push_error("Error removing file: %s" % err)


func register_script_attachment_undo(node: Node, script: Script, previous_script: Script, was_newly_created_by_dialog: bool):
	var undo_redo = get_undo_redo()
	undo_redo.create_action("Attach Script")

	# DO: Attach the new script
	undo_redo.add_do_property(node, "script", script)

	# UNDO: Restore the previous script
	undo_redo.add_undo_property(node, "script", previous_script)

	# If the file was newly created by the dialog, delete it on undo
	if was_newly_created_by_dialog:
		undo_redo.add_undo_method(self, "_delete_file_from_disk", script.resource_path)

	undo_redo.commit_action()

func _has_main_screen() -> bool:
	return true

func _get_plugin_name() -> String:
	return "SignalFlow Studio"

func _get_plugin_icon() -> Texture2D:
	return plugin_icon

func _make_visible(visible: bool):
	if is_instance_valid(dock):
		dock.visible = visible

func _manage_autoloads(should_add: bool):
	var changed := false
	for name in AUTOLOADS:
		var path = AUTOLOADS[name]
		var key = "autoload/%s" % name
		var value = "*" + path

		if should_add:
			if not ProjectSettings.has_setting(key) or ProjectSettings.get_setting(key) != value:
				ProjectSettings.set_setting(key, value)
				changed = true
		else:
			if ProjectSettings.has_setting(key):
				ProjectSettings.clear(key)
				changed = true

	if changed:
		ProjectSettings.save()
		print("SignalFlow: Autoloads configuration changed. Please restart the Godot editor to apply changes.")
