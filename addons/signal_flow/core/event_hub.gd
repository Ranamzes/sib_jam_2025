class_name EventHubClass
extends Node

const EventRegistry = preload("res://addons/signal_flow/core/event_registry.gd")
const SignalDomain = preload("res://addons/signal_flow/core/signal_domain.gd")

var _registry: EventRegistry
var _domain_cache := {}

func _ready():
	_registry = EventRegistry.new()

# Dynamically returns a "smart" proxy for the domain (e.g., EventHub.player).
func _get(domain_name: StringName):
	if not _domain_cache.has(domain_name):
		_domain_cache[domain_name] = SignalDomain.new(self, domain_name)
	return _domain_cache[domain_name]

# --- Public API ---

func subscribe(event_name: StringName, callback: Callable):
	var event = _registry.get_event(event_name)
	if event:
		event.subscribe(callback)

func emit(event_name: StringName, ...args):
	var event = _registry.get_event(event_name)
	if event:
		event.emit(args)

func emit_fast(event_resource: EventResource, ...args):
	if event_resource:
		event_resource.emit(args)
