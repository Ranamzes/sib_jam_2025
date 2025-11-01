class_name SignalDomain
extends RefCounted

var _eventhub: EventHubClass
var _domain_name: StringName
var _events := {} # { "died": EventProxy, "jumped": EventProxy }

func _init(eventhub: EventHubClass, domain: StringName):
    _eventhub = eventhub
    _domain_name = domain
    _preload_domain_events()

func _preload_domain_events():
    var manifest = _eventhub._registry._registry
    for event_name in manifest.keys():
        if event_name.begins_with(_domain_name + "_"):
            var short_name = event_name.trim_prefix(_domain_name + "_")
            _events[short_name] = EventProxy.new(_eventhub, event_name)

func _get(event_name: StringName):
    return _events.get(event_name)