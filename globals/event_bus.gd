
extends Node

signal create_echo(echo_stats:EchoStats,position:Vector2)

signal player_died()
signal player_respawned(player: CharacterBody2D)

signal  reset_level()

signal new_respawn(new_pos:Vector2)
