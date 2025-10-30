class_name ActionInputComponent
extends Node

# --- Signals for other systems to consume ---
signal jump_requested
signal dash_requested
signal crouch_started
signal crouch_stopped
signal latch_toggled(is_pressed: bool)
signal move_vector_changed(move_vector: Vector2)

# --- Public methods to trigger actions ---
func request_jump() -> void:
    jump_requested.emit()

func request_dash() -> void:
    dash_requested.emit()

func start_crouch() -> void:
    crouch_started.emit()

func stop_crouch() -> void:
    crouch_stopped.emit()

func toggle_latch(is_pressed: bool) -> void:
    latch_toggled.emit(is_pressed)

func set_move_vector(move_vector: Vector2) -> void:
    move_vector_changed.emit(move_vector)
