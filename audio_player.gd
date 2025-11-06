extends Node

@onready var music_player = $MusicPlayer
@onready var coin_player = $CoinPlayer
@onready var jump_player = $JumpPlayer
@onready var hurt_player = $HurtPlayer
@onready var win_player = $WinPlayer
@onready var dash_player = $DashPlayer

func _ready() -> void:
	music_player.connect("finished", Callable(self, "_on_loop_sound").bind(music_player))
	music_player.play()

func play_sfx(sfx_name: String):
	match sfx_name:
		"coin":
			coin_player.play()
		"jump":
			jump_player.play()
		"hurt":
			hurt_player.play()
		"win":
			win_player.play()
		"dash":
			dash_player.play() # Используем звук прыжка для dash
		_:
			print("Invalid sfx name")

func _on_loop_sound():
	music_player.stream_paused = false
	music_player.play()
