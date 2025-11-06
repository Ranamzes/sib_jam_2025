extends Node

@export var player: AudioStreamPlayer2D
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	player = $AudioStreamPlayer2D
	player.play() # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
