extends Node2D

func _ready() -> void:
	$Title/CenterContainer/OptionsMenu/FullscrenCB.button_pressed = true if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN else false
	$Title/CenterContainer/OptionsMenu/MainVolumeHSlider.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")))
	$Title/CenterContainer/OptionsMenu/MusicHSlider.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")))
	$Title/CenterContainer/OptionsMenu/SFXHSlider.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX")))

func _on_start_button_pressed() -> void:
	pass # Replace with function body.


func _on_options_button_pressed() -> void:
	$Title/CenterContainer/MainMenu.visible = false;
	$Title/CenterContainer/OptionsMenu.visible = true;


func _on_credits_button_pressed() -> void:
	$Title/CenterContainer/MainMenu.visible = false;
	$Title/CenterContainer/CreditsMenu.visible = true;


func _on_exit_button_pressed() -> void:
	get_tree().quit();



func _on_credits_back_button_pressed() -> void:
	$Title/CenterContainer/MainMenu.visible = true;
	$Title/CenterContainer/CreditsMenu.visible = false;


func _on_options_back_button_pressed() -> void:
	$Title/CenterContainer/MainMenu.visible = true;
	$Title/CenterContainer/OptionsMenu.visible = false;


func _on_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on :
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)


func _on_main_volume_h_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("Master"), value)


func _on_music_h_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("Music"), value)


func _on_sfxh_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("SFX"), value)
