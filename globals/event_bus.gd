
extends Node

signal create_echo(echo_stats:EchoStats,position:Vector2)

signal player_died()

signal  reset_level()

signal new_respawn(new_pos:Vector2)
signal player_respawned(player_node: Node2D)
