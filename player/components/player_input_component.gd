class_name PlayerInputComponent
extends Node



# --- G.U.I.D.E. Resources ---
@export_group("G.U.I.D.E. Setup")
@export var mapping_context: GUIDEMappingContext

@export_group("Actions")
@export var move_action: GUIDEAction
@export var jump_action: GUIDEAction
@export var dash_action: GUIDEAction
@export var crouch_action: GUIDEAction
@export var latch_action: GUIDEAction
@export var physics_system: PhysicsIntegrationSystem

func _ready() -> void:
	if not mapping_context:
		push_error("PlayerInputComponent: GUIDEMappingContext is not set!")
		return
	
	
	# Activate the controls for this player
	GUIDE.enable_mapping_context(mapping_context)

	# Connect to actions that are single events (like button presses)
	if jump_action:
		jump_action.triggered.connect(func(): physics_system.request_jump())
	#if dash_action:
	#	dash_action.triggered.connect(func(): _action_input_component.request_dash())
	
	# For hold actions, we can check their state change
	##if crouch_action:
	#	crouch_action.started.connect(func(): _action_input_component.start_crouch())
	#	crouch_action.completed.connect(func(): _action_input_component.stop_crouch())
	#if latch_action:
	#	latch_action.started.connect(func(): _action_input_component.toggle_latch(true))
	#	latch_action.completed.connect(func(): _action_input_component.toggle_latch(false))


func _physics_process(_delta: float) -> void:
	if not move_action:
		return
	
	# Continuously poll the move action for its vector
	var current_move_vector: Vector2 = move_action.value_axis_2d
	physics_system._change_movement_vector(current_move_vector)
