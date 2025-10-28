extends Node

# Preload core components.
const EventRegistry = preload("res://addons/signal_flow/core/event_registry.gd")
const SignalDomain = preload("res://addons/signal_flow/core/signal_domain.gd")

# --- Runtime Properties ---
var _registry
var _domain_cache := {}

# --- Initializer Properties ---
const SUBSCRIPTION_MAP_PATH = "res://addons/signal_flow/cache/subscription_map.tres"


func _ready():
	# 1. Initialize the event bus itself
	_registry = EventRegistry.new()
	
	# 2. Connect to the tree to initialize subscriptions for each scene
	get_tree().scene_tree_ready.connect(_on_scene_tree_ready, CONNECT_ONE_SHOT)


# --- Public API ---

# Dynamically returns a proxy for the domain (e.g., EventHub.player).
func _get(property: StringName):
	if not _domain_cache.has(property):
		_domain_cache[property] = SignalDomain.new(self, property)
	return _domain_cache[property]

func get_event(event_name: StringName) -> EventResource:
	return _registry.get_event(event_name)

func subscribe(event_name: StringName, callback: Callable):
	var event = get_event(event_name)
	if event:
		event.subscribe(callback)

func emit(event_name: StringName, payload = null):
	var event = get_event(event_name)
	if event:
		emit_fast(event, payload)

func emit_fast(event_resource: EventResource, payload = null):
	if event_resource:
		event_resource.emit(payload)


# --- Private Initializer Logic ---

func _on_scene_tree_ready():
	var scene_root = get_tree().current_scene
	if not scene_root:
		return

	var sub_map = load(SUBSCRIPTION_MAP_PATH)
	if not sub_map:
		return # No subscriptions to process

	for sub_info in sub_map.subscriptions:
		var node = scene_root.get_node_or_null(sub_info.node_path)
		if not node:
			push_warning("SignalFlow: Node not found at path: %s" % sub_info.node_path)
			continue
		
		# Since we are inside EventHub, we can call subscribe directly.
		subscribe(sub_info.event_name, Callable(node, sub_info.method_name))
