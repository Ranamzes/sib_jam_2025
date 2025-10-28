# Base class for all game-specific event resources.
# Renamed to GameEvent to avoid conflict with Godot's built-in Event class.
class_name GameEvent
extends Resource

signal triggered

# Subscribes a callable to this event.
func subscribe(callback: Callable):
	if not triggered.is_connected(callback):
		triggered.connect(callback)

# Unsubscribes a callable from this event.
func unsubscribe(callback: Callable):
	if triggered.is_connected(callback):
		triggered.disconnect(callback)

# This function accepts multiple arguments and emits them deferred.
func emit(...args):
	call_deferred("_emit_deferred", args)

# This internal function does the actual emitting.
# Subscribers will receive all arguments packed into a single Array.
func _emit_deferred(args: Array):
	triggered.emit(args)
