class_name EventProxy
extends RefCounted

var _hub
var _event: EventResource

func _init(hub, event: EventResource):
	_hub = hub
	_event = event

func subscribe(callback: Callable):
	if _event:
		_event.subscribe(callback)

func emit(payload = null):
	if _hub and _event:
		_hub.emit_fast(_event, payload)
