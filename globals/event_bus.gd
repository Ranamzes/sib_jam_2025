
extends Node

signal create_echo(echo_stats:EchoStats,position:Vector2)

signal player_died()
signal player_respawned(player: CharacterBody2D)

# Emitted when the level needs to be reset (e.g., on player death).
# Passes the ID of the checkpoint that was active when the reset was triggered.
signal reset_level(checkpoint_id: int)

# Emitted by a RespawnArea when the player enters it.
# Passes the new position and the ID of the checkpoint.
signal new_respawn(new_pos: Vector2, checkpoint_id: int)
