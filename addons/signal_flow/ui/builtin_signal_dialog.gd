@tool
extends ConfirmationDialog

@onready var search_box: LineEdit = $VBoxContainer/SearchLineEdit
@onready var signal_list: ItemList = $VBoxContainer/SignalList

var inspected_node: Node
var _all_signals: Array = []

signal signal_selected(signal_name: String)

func _ready():
	# Connect signals
	confirmed.connect(_on_confirmed)
	search_box.text_changed.connect(_on_search_text_changed)
	signal_list.item_selected.connect(_on_item_selected)

	# Configure dialog
	ok_button_text = "Create Event"
	title = "Select a Built-in Signal to Promote"

func popup_dialog(node: Node):
	inspected_node = node
	_populate_signal_list()
	popup_centered()

func _populate_signal_list():
	if not is_instance_valid(inspected_node):
		return
	
	_all_signals = inspected_node.get_signal_list()
	# Sort alphabetically by name
	_all_signals.sort_custom(func(a, b): return a.name < b.name)
	
	_filter_list()

func _filter_list(filter_text: String = ""):
	signal_list.clear()
	for signal_info in _all_signals:
		var signal_name: String = signal_info.name
		if filter_text.is_empty() or signal_name.findn(filter_text) != -1:
			signal_list.add_item(signal_name)
	
	# Disable OK button until an item is selected
	get_ok_button().disabled = true

func _on_search_text_changed(new_text: String):
	_filter_list(new_text)

func _on_item_selected(index: int):
	get_ok_button().disabled = false

func _on_confirmed():
	var selected_items = signal_list.get_selected_items()
	if selected_items.is_empty():
		return
	
	var selected_signal_name = signal_list.get_item_text(selected_items[0])
	signal_selected.emit(selected_signal_name)
	hide()
