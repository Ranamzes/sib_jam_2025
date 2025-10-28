class_name SignalDomain
extends RefCounted

var _hub
var _domain_name: StringName
var _proxy_cache := {}

# The EventProxy class needs to be preloaded to be used.
const EventProxy = preload("res://addons/signal_flow/core/event_proxy.gd")

func _init(hub, domain_name: StringName):
	_hub = hub
	_domain_name = domain_name

func _get(property: StringName):
	if not _proxy_cache.has(property):
		var event_name = "%s_%s" % [_domain_name, property]
		var event_resource = _hub.get_event(event_name)
		if event_resource:
			_proxy_cache[property] = EventProxy.new(_hub, event_resource)
		else:
			push_error("SignalFlow: Event '" + event_name + "' not found in manifest.")
			return null
	return _proxy_cache[property]
