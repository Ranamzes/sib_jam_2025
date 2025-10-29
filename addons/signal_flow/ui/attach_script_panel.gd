@tool
extends VBoxContainer

@onready var attach_button = $AttachButton

var inspected_node: Node
var editor_interface: EditorInterface
var main_plugin: EditorPlugin # Reference to the main EditorPlugin

func _ready():
	attach_button.pressed.connect(self._on_attach_pressed)

	# Set the icon for the button
	if editor_interface:
		var editor_theme = editor_interface.get_editor_theme()
		if editor_theme:
			var script_create_icon = editor_theme.get_icon("ScriptCreate", "EditorIcons")
			if script_create_icon:
				attach_button.icon = script_create_icon

func set_inspected_node(node: Node):
	inspected_node = node

func set_editor_interface(interface: EditorInterface):
	editor_interface = interface

func set_main_plugin(plugin: EditorPlugin):
	main_plugin = plugin

func _on_attach_pressed():
	if inspected_node == null:
		push_error("SignalFlow: Inspected node is null.")
		return
	if main_plugin == null:
		push_error("SignalFlow: Main plugin reference is null.")
		return

	var dialog = main_plugin.get_script_create_dialog()
	if not dialog:
		push_error("SignalFlow: Could not get ScriptCreateDialog from main plugin.")
		return

	var node_name: String = inspected_node.name
	var base_type: String = inspected_node.get_class()

	var suggested_path: String
	var scene_path_of_inspected_node: String = inspected_node.scene_file_path
	var current_edited_scene_root = editor_interface.get_edited_scene_root()
	var current_edited_scene_path: String = current_edited_scene_root.scene_file_path if current_edited_scene_root else ""

	if not scene_path_of_inspected_node.is_empty():
		suggested_path = scene_path_of_inspected_node.get_base_dir().path_join(node_name.to_snake_case() + ".gd")
	elif not current_edited_scene_path.is_empty():
		suggested_path = current_edited_scene_path.get_base_dir().path_join(node_name.to_snake_case() + ".gd")
	else:
		suggested_path = "res://" + node_name.to_snake_case() + ".gd"

	print("SignalFlow Debug: Inspected Node: ", inspected_node.name)
	print("SignalFlow Debug: Base Type: ", base_type)
	print("SignalFlow Debug: Suggested Path: ", suggested_path)

	dialog.config(base_type, suggested_path, false, false)

	if not dialog.script_created.is_connected(_on_script_created):
		dialog.script_created.connect(_on_script_created)

	dialog.popup_centered()

func _on_script_created(script: Script):
	if inspected_node:
		inspected_node.set_script(script)
		# This will cause the inspector to refresh, and our other panel will now appear.
		if editor_interface:
			editor_interface.inspect_object(inspected_node)
