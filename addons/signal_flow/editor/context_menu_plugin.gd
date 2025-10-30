@tool
extends EditorContextMenuPlugin

var main_plugin

func _popup_menu(paths: PackedStringArray):
	# Clear previous items to avoid duplicates
	get_popup().clear()
	
	# We only want to show the menu on directories
	if paths.size() == 1 and DirAccess.dir_exists_absolute(paths[0]):
		var dir_path = paths[0]
		var icon = main_plugin.get_editor_interface().get_editor_theme().get_icon("EventResource", "EditorIcons")
		
		# Add the item, binding the selected directory path to the callback
		get_popup().add_icon_item(icon, "Create New EventResource", -1)
		get_popup().set_item_callback(-1, Callable(main_plugin, "_on_create_event_resource_selected").bind(dir_path))

