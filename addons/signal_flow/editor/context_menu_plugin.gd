@tool
extends EditorContextMenuPlugin

var main_plugin

func _popup_menu(paths: PackedStringArray):
	# We only want to show the menu on a single selected directory
	if paths.size() == 1 and DirAccess.dir_exists_absolute(paths[0]):
		var dir_path = paths[0]
		var icon = main_plugin.get_editor_interface().get_editor_theme().get_icon("EventResource", "EditorIcons")
		
		# Create the callback
		var callback = Callable(main_plugin, "_on_create_event_resource_selected").bind(dir_path)
		
		# Add the menu item
		add_context_menu_item("Create New EventResource", callback, icon)
