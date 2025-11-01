@tool
extends VBoxContainer

@export var attach_icon: Texture2D

@onready var attach_button = $AttachButton

var inspected_node: Node
var editor_interface: EditorInterface
var main_plugin: EditorPlugin # Reference to the main EditorPlugin

func _ready():
	attach_button.pressed.connect(self._on_attach_pressed)

	if attach_icon:
		attach_button.icon = attach_icon
	else:
		_set_default_icon()

func _set_default_icon():
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
	if is_inside_tree() and attach_button:
		if not attach_icon:
			_set_default_icon()

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

	print("SignalFlow Debug: Suggested Path: ", suggested_path)

	var file_existed_before_dialog = ResourceLoader.exists(suggested_path)
	dialog.config(base_type, suggested_path, false, true)

	var callable = Callable(self, "_on_script_created").bind(suggested_path, file_existed_before_dialog)
	# Disconnect first to be safe, then connect.
	if dialog.script_created.is_connected(callable):
		dialog.script_created.disconnect(callable)
	dialog.script_created.connect(callable)

	dialog.popup_centered()

func _on_script_created(script: Script, suggested_path: String, file_existed_before_dialog: bool):
	if inspected_node and main_plugin:
		var actual_path = script.resource_path
		var was_newly_created = not file_existed_before_dialog and actual_path == suggested_path
		var previous_script = inspected_node.get_script()
		
		main_plugin.call_deferred("register_script_attachment_undo", inspected_node, script, previous_script, was_newly_created)
