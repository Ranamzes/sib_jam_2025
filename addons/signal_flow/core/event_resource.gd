class_name EventResource
extends Resource

# A unique domain name (e.g., "player", "inventory").
# Uniqueness will be enforced by the plugin.
@export var domain: StringName

signal triggered(payload)

# Subscribe a callback to this event.
func subscribe(callback: Callable):
	triggered.connect(callback)

# Emits the event signal. Can be called directly or via EventHub.
func emit(payload = null):
	triggered.emit(payload)
