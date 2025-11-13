
extends Node

# This script provides a global interface to control audio bus volumes.

# Note: Volume in decibels (dB) is not linear.
# 0 dB is full volume.
# -20 dB is roughly 10% of full volume.
# -80 dB is effectively silent.

const MUSIC_BUS_NAME: StringName = &"Music"
const SFX_BUS_NAME: StringName = &"SFX"
const FOOTSTEPS_BUS_NAME: StringName = &"Footsteps"
const MASTER_BUS_NAME: StringName = &"Master"

var music_bus_index: int
var sfx_bus_index: int
var footsteps_bus_index: int
var master_bus_index: int

func _ready() -> void:
	# Cache the bus indices for performance
	music_bus_index = AudioServer.get_bus_index(MUSIC_BUS_NAME)
	sfx_bus_index = AudioServer.get_bus_index(SFX_BUS_NAME)
	footsteps_bus_index = AudioServer.get_bus_index(FOOTSTEPS_BUS_NAME)
	master_bus_index = AudioServer.get_bus_index(MASTER_BUS_NAME)

## Sets the volume of the Master bus.
## @param db: The volume in decibels.
func set_master_volume_db(db: float) -> void:
	AudioServer.set_bus_volume_db(master_bus_index, db)

## Sets the volume of the Music bus.
## @param db: The volume in decibels.
func set_music_volume_db(db: float) -> void:
	AudioServer.set_bus_volume_db(music_bus_index, db)

## Sets the volume of the SFX bus.
## @param db: The volume in decibels.
func set_sfx_volume_db(db: float) -> void:
	AudioServer.set_bus_volume_db(sfx_bus_index, db)

## Sets the volume of the Footsteps bus.
## @param db: The volume in decibels.
func set_footsteps_volume_db(db: float) -> void:
	AudioServer.set_bus_volume_db(footsteps_bus_index, db)
