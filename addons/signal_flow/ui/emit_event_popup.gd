@tool
extends PopupPanel
class_name EmitEventPopup

@export var player_died: EventResource = preload("res://events/player_died.tres") # SignalFlow Generated

const EventResource = preload("res://addons/signal_flow/core/event_resource.gd")

@onready var existing_event_picker: EditorResourcePicker = $MarginContainer/VBoxContainer/HBoxContainer/ExistingEventPicker
@onready var new_event_button: Button = $MarginContainer/VBoxContainer/NewEventButton
@onready var load_event_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/LoadEventLabel

var editor_interface: EditorInterface
var inspected_node: Node

signal event_selected(resource: EventResource)
signal new_event_requested()

func _ready():
	if existing_event_picker:
		existing_event_picker.resource_selected.connect(_on_existing_event_selected)
	else:
		push_error("EmitEventPopup: Node not found: ExistingEventPicker")

	if new_event_button:
		new_event_button.pressed.connect(_on_new_event_button_pressed)
	else:
		push_error("EmitEventPopup: Node not found: NewEventButton")

	if load_event_label:
		load_event_label.gui_input.connect(_on_load_event_label_gui_input)
		load_event_label.mouse_filter = Control.MOUSE_FILTER_STOP
	else:
		push_error("EmitEventPopup: Node not found: LoadEventLabel")

	popup_hide.connect(_on_popup_hide)

func set_editor_interface(interface: EditorInterface):
	editor_interface = interface

func set_inspected_node(node: Node):
	inspected_node = node

func _on_existing_event_selected(resource: Resource):
	if resource is EventResource:
		event_selected.emit(resource)
		hide()

func _on_new_event_button_pressed():
	new_event_requested.emit()
	hide()

func _on_load_event_label_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		existing_event_picker.emit_signal("pressed") # Simulate button press
		get_viewport().set_input_as_handled()

func _on_popup_hide():
	if existing_event_picker:
		existing_event_picker.set_edited_resource(null)