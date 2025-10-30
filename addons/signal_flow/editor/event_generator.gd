class_name EventGenerator
extends RefCounted

const EventRegistry = preload("res://addons/signal_flow/core/event_registry.gd")
const EventManifest = preload("res://addons/signal_flow/cache/EventManifest.gd")
const EventResource = preload("res://addons/signal_flow/core/event_resource.gd")
const EventsIndex = preload("res://addons/signal_flow/core/events_index.gd")

const INDEX_PATH = "res://.godot/signal_flow_index.json" # New constant

var editor_interface: EditorInterface
var _event_manifest: EventManifest # Reference to the loaded event manifest

func _init(interface: EditorInterface):
	editor_interface = interface

func generate_event_manifest():
	print("SignalFlow: Generating event manifest...")
	var manifest_data := {}
	var event_resources := _scan_for_event_resources()

	for path in event_resources:
		var event_resource: EventResource = load(path)
		if event_resource:
			# Ensure domain is set
			if event_resource.domain.is_empty():
				push_error("SignalFlow: EventResource at %s has no domain set. Skipping." % path)
				continue

			var event_id = "%s_%s" % [event_resource.domain, path.get_file().get_basename()]
			manifest_data[event_id] = event_resource
		else:
			push_error("SignalFlow: Failed to load EventResource at %s" % path)

	var manifest := EventManifest.new()
	manifest.events = manifest_data

	var save_error = ResourceSaver.save(manifest, EventRegistry.MANIFEST_PATH)
	if save_error != OK:
		push_error("SignalFlow: Failed to save event manifest: %s" % save_error)
	else:
		print("SignalFlow: Event manifest generated successfully.")

	_generate_events_indices() # Call new function
	_generate_signal_flow_index() # Call new function

func _generate_events_indices():
	print("SignalFlow: Generating events indices...")
	var feature_folders := _scan_for_feature_folders("res://")

	for folder_path in feature_folders:
		var events_index := EventsIndex.new()
		var events_index_path = folder_path.path_join("events/events_index.tres")

		# Populate 'provides'
		var provided_events = _scan_directory_for_event_resources(folder_path.path_join("events"))
		for path in provided_events:
			var event_resource: EventResource = load(path)
			if event_resource:
				events_index.provides.append(event_resource)

		# Populate 'requires'
		var scripts_in_folder = _scan_directory_for_scripts(folder_path)
		for script_path in scripts_in_folder:
			var required_events = _parse_script_for_required_events(script_path)
			for event_resource in required_events:
				if not events_index.requires.has(event_resource):
					events_index.requires.append(event_resource)

		var save_error = ResourceSaver.save(events_index, events_index_path)
		if save_error != OK:
			push_error("SignalFlow: Failed to save events index for %s: %s" % [folder_path, save_error])
		else:
			print("SignalFlow: Events index generated for %s." % folder_path)

func _generate_signal_flow_index():
	print("SignalFlow: Generating signal flow index...")
	var index_data := {} # Dictionary to store event usage: {event_id: [{script_path: "...", line: ...}]}
	var all_scripts = _scan_directory_for_scripts("res://") # Scan all scripts in the project

	var on_event_regex = RegEx.new()
	var error = on_event_regex.compile(r'@on_event\("([^\"]+)"\)')
	if error != OK:
		push_error("SignalFlow: Invalid regex for @on_event: %s" % error)
		return

	var forward_signal_regex = RegEx.new()
	error = forward_signal_regex.compile(r'@forward_signal\("[^\"]+",\s*"([^\"]+)"\)')
	if error != OK:
		push_error("SignalFlow: Invalid regex for @forward_signal: %s" % error)
		return

	var emit_regex = RegEx.new()
	error = emit_regex.compile(r'EventHub\.emit\("([^\"]+)"\)')
	if error != OK:
		push_error("SignalFlow: Invalid regex for EventHub.emit: %s" % error)
		return

	var subscribe_regex = RegEx.new()
	error = subscribe_regex.compile(r'EventHub\.subscribe\("([^\"]+)"\)')
	if error != OK:
		push_error("SignalFlow: Invalid regex for EventHub.subscribe: %s" % error)
		return

	for script_path in all_scripts:
		var file = FileAccess.open(script_path, FileAccess.READ)
		if not file:
			push_error("SignalFlow: Failed to open script for indexing: %s" % script_path)
			continue

		var content = file.get_as_text()
		file.close()

		var lines = content.split("\n")
		for i in range(lines.size()):
			var line_content = lines[i]
			var line_number = i + 1

			# Regex for @on_event("event_id")
			var on_event_matches = on_event_regex.search_all(line_content)
			for match in on_event_matches:
				var event_id = match.get_string(1)
				if not index_data.has(event_id):
					index_data[event_id] = []
				index_data[event_id].append({"script_path": script_path, "line": line_number, "type": "subscribe"})

			# Regex for @forward_signal("signal_name", "res://path/to/event.tres")
			var forward_signal_matches = forward_signal_regex.search_all(line_content)
			for match in forward_signal_matches:
				var event_resource_path = match.get_string(1)
				var event_resource: EventResource = load(event_resource_path)
				if event_resource:
					# Find the event_id from the manifest using the loaded event_resource
					var found_event_id = ""
					for id in _event_manifest.events:
						if _event_manifest.events[id] == event_resource:
							found_event_id = id
							break

						if not found_event_id.is_empty():
							if not index_data.has(found_event_id):
								index_data[found_event_id] = []
							index_data[found_event_id].append({"script_path": script_path, "line": line_number, "type": "forward"})
						else:
							push_warning("SignalFlow: Forwarded event resource '%s' not found in manifest for script %s" % [event_resource_path, script_path])
				else:
					push_warning("SignalFlow: Forwarded event resource '%s' not found for script %s" % [event_resource_path, script_path])

			# Regex for EventHub.emit("event_id", ...)
			var emit_matches = emit_regex.search_all(line_content)
			for match in emit_matches:
				var event_id = match.get_string(1)
				if not index_data.has(event_id):
					index_data[event_id] = []
				index_data[event_id].append({"script_path": script_path, "line": line_number, "type": "emit"})

			# Regex for EventHub.subscribe("event_id", ...)
			var subscribe_matches = subscribe_regex.search_all(line_content)
			for match in subscribe_matches:
				var event_id = match.get_string(1)
				if not index_data.has(event_id):
					index_data[event_id] = []
				index_data[event_id].append({"script_path": script_path, "line": line_number, "type": "subscribe_api"})

	var file = FileAccess.open(INDEX_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(index_data, "\t"))
		file.close()
		print("SignalFlow: Signal flow index generated successfully.")
	else:
		push_error("SignalFlow: Failed to save signal flow index to %s" % INDEX_PATH)

func _scan_for_feature_folders(path: String) -> Array[String]:
	var folders: Array[String] = []
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				var sub_path = path.path_join(file_name)
				if sub_path.ends_with("/events"): # A folder containing an 'events' subfolder is a feature folder
					folders.append(path) # The parent folder is the feature folder
				else:
					folders.append_array(_scan_for_feature_folders(sub_path))
			file_name = dir.get_next()
		dir.list_dir_end()
	return folders

func _scan_directory_for_scripts(path: String) -> Array[String]:
	var scripts: Array[String] = []
	var excluded_folders = ["addons", ".godot", ".git", ".history"]
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				if file_name in excluded_folders:
					pass # Skip
				else:
					scripts.append_array(_scan_directory_for_scripts(path.path_join(file_name)))
			elif file_name.ends_with(".gd"):
				scripts.append(path.path_join(file_name))
			file_name = dir.get_next()
		dir.list_dir_end()
	return scripts

func _scan_for_event_resources() -> Array[String]:
	var paths: Array[String] = []
	var dir = DirAccess.open("res://")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				if file_name != "addons" and file_name != ".git" and file_name != ".godot" and file_name != ".history": # Avoid scanning unnecessary folders
					paths.append_array(_scan_directory_for_event_resources("res://%s" % file_name))
			elif file_name.ends_with(".tres"):
				var resource = load("res://%s" % file_name)
				if resource is EventResource:
					paths.append("res://%s" % file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	return paths

func _scan_directory_for_event_resources(path: String) -> Array[String]:
	var paths: Array[String] = []
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				paths.append_array(_scan_directory_for_event_resources("%s/%s" % [path, file_name]))
			elif file_name.ends_with(".tres"):
				var resource = load("%s/%s" % [path, file_name])
				if resource is EventResource:
					paths.append("%s/%s" % [path, file_name])
			file_name = dir.get_next()
		dir.list_dir_end()
	return paths

func _parse_script_for_required_events(script_path: String) -> Array[EventResource]:
	var required_events: Array[EventResource] = []
	var file = FileAccess.open(script_path, FileAccess.READ)
	if not file:
		push_error("SignalFlow: Failed to open script for parsing: %s" % script_path)
		return required_events

	var content = file.get_as_text()
	file.close()

	# Regex for @on_event("event_id")
	var on_event_regex = RegEx.new()
	var error = on_event_regex.compile(r'@on_event\("([^\"]+)"\)')
	if error != OK:
		push_error("SignalFlow: Invalid regex for @on_event: %s" % error)
	else:
		var on_event_matches = on_event_regex.search_all(content)
		for match in on_event_matches:
			var event_id = match.get_string(1)
			var event_resource = _event_manifest.events.get(event_id) # Assuming _event_manifest is available
			if event_resource:
				required_events.append(event_resource)
			else:
				push_warning("SignalFlow: Required event '%s' not found in manifest for script %s" % [event_id, script_path])

	# Regex for @forward_signal("signal_name", "res://path/to/event.tres")
	var forward_signal_regex = RegEx.new()
	error = forward_signal_regex.compile(r'@forward_signal\("[^\"]+",\s*"([^\"]+)"\)')
	if error != OK:
		push_error("SignalFlow: Invalid regex for @forward_signal: %s" % error)
	else:
		var forward_signal_matches = forward_signal_regex.search_all(content)
		for match in forward_signal_matches:
			var event_resource_path = match.get_string(1)
			var event_resource: EventResource = load(event_resource_path)
			if event_resource:
				required_events.append(event_resource)
			else:
				push_warning("SignalFlow: Forwarded event resource '%s' not found for script %s" % [event_resource_path, script_path])

	return required_events
