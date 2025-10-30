@tool
extends VBoxContainer

var inspected_node: Node

func set_inspected_node(node: Node):
	inspected_node = node

func set_editor_interface(interface: EditorInterface):
	pass

func set_main_plugin(plugin: EditorPlugin):
	pass