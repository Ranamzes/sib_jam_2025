class_name SignalFlowStudioDock
extends Control

const EventRegistry = preload("res://addons/signal_flow/core/event_registry.gd")
const EventResource = preload("res://addons/signal_flow/core/event_resource.gd")
const EventManifest = preload("res://addons/signal_flow/cache/EventManifest.gd")

@onready var search_line_edit = $VBoxContainer/SearchLineEdit
@onready var event_tree = $VBoxContainer/EventTree
@onready var usage_panel = $VBoxContainer/UsagePanel

var editor_interface: EditorInterface
var _event_manifest: EventManifest # Reference to the loaded event manifest

func _ready():
	search_line_edit.text_changed.connect(Callable(self, "_on_search_text_changed"))
	event_tree.item_selected.connect(Callable(self, "_on_event_tree_item_selected"))
	_populate_event_tree() # Populate the tree on ready

func set_editor_interface(interface: EditorInterface):
	editor_interface = interface

func _on_search_text_changed(text: String):
	_filter_event_tree(text)

func _on_event_tree_item_selected():
	_display_event_usage()

func _populate_event_tree():
	event_tree.clear()
	var root = event_tree.create_item()
	
	if not _event_manifest:
		_event_manifest = load(EventRegistry.MANIFEST_PATH)
		if not _event_manifest:
			push_error("SignalFlowStudioDock: Event manifest not found at %s" % EventRegistry.MANIFEST_PATH)
			return

	var domains: Dictionary = {}
	for event_id in _event_manifest.events:
		var event_resource: EventResource = _event_manifest.events[event_id]
		if not domains.has(event_resource.domain):
			domains[event_resource.domain] = []
		domains[event_resource.domain].append(event_resource)

	for domain_name in domains:
		var domain_item = event_tree.create_item(root)
		domain_item.set_text(0, domain_name)
		domain_item.set_icon(0, editor_interface.get_editor_theme().get_icon("Folder", "EditorIcons")) # Folder icon for domain
		
		for event_resource in domains[domain_name]:
			var event_item = event_tree.create_item(domain_item)
			event_item.set_text(0, event_resource.resource_path.get_file().get_basename())
			event_item.set_icon(0, editor_interface.get_editor_theme().get_icon("Resource", "EditorIcons")) # Resource icon for event
			event_item.set_metadata(0, event_resource) # Store the event resource as metadata

func _filter_event_tree(filter_text: String):
	_populate_event_tree() # Re-populate the tree to clear previous filters
	
	if filter_text.is_empty():
		return # No filter, show all

	var root = event_tree.get_root()
	if not root:
		return

	var current_domain_item = root.get_first_child()
	while current_domain_item:
		var has_visible_children = false
		var current_event_item = current_domain_item.get_first_child()
		while current_event_item:
			var event_name: String = current_event_item.get_text(0)
			if event_name.findn(filter_text) == -1:
				current_event_item.set_visible(false)
			else:
				current_event_item.set_visible(true)
				has_visible_children = true
			current_event_item = current_event_item.get_next()
		
		current_domain_item.set_visible(has_visible_children)
		current_domain_item = current_domain_item.get_next()

func _display_event_usage():
	var selected_item = event_tree.get_selected()
	if not selected_item:
		usage_panel.set_tooltip_text("Select an event to see its usage.")
		return

	var event_resource: EventResource = selected_item.get_metadata(0)
	if event_resource:
		# For now, just display the resource path.
		# Later, this will read from .godot/signal_flow_index.json
		usage_panel.set_tooltip_text("Usage for: %s\nPath: %s" % [event_resource.resource_path.get_file().get_basename(), event_resource.resource_path])
	else:
		usage_panel.set_tooltip_text("Select an event to see its usage.")