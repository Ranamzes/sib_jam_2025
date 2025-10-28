@tool
extends EditorInspectorPlugin

const SignalFlowPanel = preload("res://addons/signal_flow/signal_flow_panel.tscn")
const AttachScriptPanel = preload("res://addons/signal_flow/attach_script_panel.tscn")

var editor_interface: EditorInterface
var main_plugin: EditorPlugin

# The main plugin will call these to provide necessary references.
func set_editor_interface(interface: EditorInterface):
	editor_interface = interface

func set_main_plugin(plugin: EditorPlugin):
	main_plugin = plugin

# We can handle any node.
func _can_handle(object):
	return object is Node

# We add all our custom controls at the beginning of the inspector.
func _parse_begin(object):
	# Add the appropriate panel below the header
	var panel_instance
	if object.get_script() != null:
		panel_instance = SignalFlowPanel.instantiate()
	else:
		panel_instance = AttachScriptPanel.instantiate()
	
	panel_instance.set_inspected_node(object)
	
	# Pass references down to the panel
	if panel_instance.has_method("set_editor_interface"):
		panel_instance.set_editor_interface(editor_interface)
	if panel_instance.has_method("set_main_plugin"):
		panel_instance.set_main_plugin(main_plugin)
	
	add_custom_control(panel_instance)

	# Add a separator at the end for visual clarity
	add_custom_control(HSeparator.new())