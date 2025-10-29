@tool
extends EditorInspectorPlugin

const SectionHeader = preload("res://addons/signal_flow/ui/SectionHeader.tscn")
const SignalFlowPanel = preload("res://addons/signal_flow/ui/SignalFlowPanel.tscn")
const AttachScriptPanel = preload("res://addons/signal_flow/ui/AttachScriptPanel.tscn")

var editor_interface: EditorInterface
var main_plugin: EditorPlugin

func set_editor_interface(interface: EditorInterface):
	editor_interface = interface

func set_main_plugin(plugin: EditorPlugin):
	main_plugin = plugin

func _can_handle(object):
	return object is Node

func _parse_begin(object):
	var container = VBoxContainer.new()
	container.name = "SignalFlowInspectorContainer"
	container.add_theme_constant_override("separation", 8) # Add some spacing between header and panel

	# --- 1. Create the Header ---
	var header = SectionHeader.instantiate()
	# The title is now set directly in the SectionHeader scene.

	# --- Apply the native Godot inspector section style ---
	var theme = EditorInterface.get_editor_theme()
	var stylebox = theme.get_stylebox("panel", "Panel")
	if stylebox:
		header.add_theme_stylebox_override("normal", stylebox)
		header.add_theme_stylebox_override("pressed", stylebox)
		header.add_theme_stylebox_override("hover", stylebox)

	container.add_child(header)

	# --- 2. Create the main content panel ---
	var panel_instance
	if object.get_script() != null:
		panel_instance = SignalFlowPanel.instantiate()
	else:
		panel_instance = AttachScriptPanel.instantiate()

	# Pass necessary references to the panel
	panel_instance.set_inspected_node(object)
	if panel_instance.has_method("set_editor_interface"):
		panel_instance.set_editor_interface(editor_interface)
	if panel_instance.has_method("set_main_plugin"):
		panel_instance.set_main_plugin(main_plugin)

	# --- 3. Connect header and panel ---
	# The header's toggled signal controls the panel's visibility
	header.toggled.connect(panel_instance.set_visible)
	# Set initial visibility based on the header's state
	panel_instance.visible = header.button_pressed

	# Add the panel to the container
	container.add_child(panel_instance)

	add_custom_control(container) # Add the container to the inspector
