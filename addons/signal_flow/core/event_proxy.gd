class_name EventProxy
extends RefCounted

var _hub: EventHubClass
var _full_event_name: StringName

func _init(hub: EventHubClass, event_name: StringName):
    _hub = hub
    _full_event_name = event_name

func subscribe(callback: Callable):
    _hub.subscribe(_full_event_name, callback)

func emit(data := {}):
    _hub.emit(_full_event_name, data)