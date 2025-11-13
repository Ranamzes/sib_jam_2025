
extends Node

@onready var player_a: AudioStreamPlayer = $PlayerA
@onready var player_b: AudioStreamPlayer = $PlayerB

var _current_player: AudioStreamPlayer
var _is_fading: bool = false

func _ready() -> void:
	# Start with player_a
	_current_player = player_a

	# Ensure players are assigned to the correct bus
	player_a.bus = &"Music"
	player_b.bus = &"Music"

	# Connect to the global event bus
	EventBus.change_background_music.connect(play_track)

	# Connect finished signals for looping
	player_a.finished.connect(_on_player_finished)
	player_b.finished.connect(_on_player_finished)


func play_track(new_stream: AudioStream, fade_duration: float = 1.5) -> void:
	if not new_stream:
		push_error("Cannot play track: new_stream is null.")
		return

	# If we are already fading, or the new track is the same as the current one, do nothing
	if _is_fading or (_current_player.stream == new_stream and _current_player.playing):
		return

	_is_fading = true

	var fade_out_player: AudioStreamPlayer = _current_player
	var fade_in_player: AudioStreamPlayer = player_b if _current_player == player_a else player_a

	# Set the new stream and start playing it silently
	fade_in_player.stream = new_stream
	fade_in_player.volume_db = -80.0 # Effectively silent
	fade_in_player.play()

	# Create a tween to handle the crossfade
	var tween := create_tween()
	tween.set_parallel(true)

	# Fade in the new track
	tween.tween_property(fade_in_player, "volume_db", 0.0, fade_duration).from(-80.0)

	# Fade out the old track (if it's playing)
	if fade_out_player.playing:
		tween.tween_property(fade_out_player, "volume_db", -80.0, fade_duration).from(0.0)

	# When the tween finishes, stop the old player and update state
	await tween.finished

	fade_out_player.stop()
	_current_player = fade_in_player
	_is_fading = false


func _on_player_finished() -> void:
	# This signal can be emitted by the player that just faded out.
	# We only want to loop the *currently active* player.
	# We also don't want to loop if a fade is in progress.
	if not _is_fading and _current_player.stream != null and not _current_player.playing:
		_current_player.play()
