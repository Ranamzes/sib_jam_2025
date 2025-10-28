class_name EventRegistry
extends RefCounted

const MANIFEST_PATH = "res://addons/signal_flow/cache/event_manifest.tres"
var _registry := {}

func _init():
	var manifest = load(MANIFEST_PATH)
	if manifest:
		_registry = manifest.events
	else:
		push_error("SignalFlow: EventManifest not found!")

func get_event(event_name: StringName) -> EventResource:
	return _registry.get(event_name)
