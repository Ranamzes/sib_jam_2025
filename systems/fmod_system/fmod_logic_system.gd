
class_name FmodLogicSystem
extends Node

@export var banks_path: String = "res://fmod_banks"

func _ready() -> void:
	print("Hello from Godot!")
	load_banks()
	# play_test_sound()

func load_banks() -> void:
	FmodManager.load_bank(banks_path + "/Master.bank", FmodManager.FMOD_STUDIO_LOAD_BANK_NORMAL)
	FmodManager.load_bank(banks_path + "/Master.strings.bank", FmodManager.FMOD_STUDIO_LOAD_BANK_NORMAL)

func play_test_sound() -> void:
	var event_path: String = "event:/test_event"
	FmodManager.play_one_shot(event_path)
