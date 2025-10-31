@tool
extends ConfirmationDialog

@onready var search_box: LineEdit = $VBoxContainer/SearchLineEdit
@onready var signal_tree: Tree = $VBoxContainer/SignalTree

var inspected_node: Node

signal signal_selected(signal_name: String)

func _ready():
	# Connect signals
	confirmed.connect(_on_confirmed)
	search_box.text_changed.connect(_on_search_text_changed)
	signal_tree.item_selected.connect(_on_item_selected)

	# Configure dialog
	ok_button_text = "Create Event"
	title = "Select a Built-in Signal to Promote"

func popup_dialog(node: Node):
	inspected_node = node
	_populate_signal_tree()
	popup_centered()

func _populate_signal_tree(filter_text: String = ""):
	signal_tree.clear()
	var root = signal_tree.create_item()
	get_ok_button().disabled = true

	if not is_instance_valid(inspected_node):
		return

	var theme = EditorInterface.get_editor_theme()
	var signal_icon = theme.get_icon("Signal", "EditorIcons")

	var current_class = inspected_node.get_class()

	# Traverse the inheritance tree upwards
	while not current_class.is_empty() and current_class != "Object":
		var own_signals = _get_class_own_signals(current_class)

		# Filter signals based on search text
		var filtered_signals = []
		if not filter_text.is_empty():
			for s in own_signals:
				if s.name.findn(filter_text) != -1:
					filtered_signals.append(s)
		else:
			filtered_signals = own_signals

		if filtered_signals.is_empty():
			current_class = ClassDB.get_parent_class(current_class)
			continue

		# Create a parent item for the class
		var class_item = signal_tree.create_item(root)
		class_item.set_text(0, current_class)
		# Safely get the class icon
		if theme.has_icon(StringName(current_class), "EditorIcons"):
			var class_icon = theme.get_icon(StringName(current_class), "EditorIcons")
			class_item.set_icon(0, class_icon)
		
		class_item.set_selectable(0, false)
		class_item.set_custom_color(0, theme.get_color("font_color", "EditorHelp"))

		# Add signals as children
		for signal_info in filtered_signals:
			var signal_item = signal_tree.create_item(class_item)
			signal_item.set_text(0, signal_info.name)
			signal_item.set_icon(0, signal_icon)

		current_class = ClassDB.get_parent_class(current_class)

# Helper to get only signals declared in the specific class, not inherited ones
func _get_class_own_signals(p_class_name: String) -> Array:
	return ClassDB.class_get_signal_list(StringName(p_class_name), true)

func _on_search_text_changed(new_text: String):
	_populate_signal_tree(new_text)

func _on_item_selected():
	var selected = signal_tree.get_selected()
	if selected:
		get_ok_button().disabled = not selected.is_selectable(0)
	else:
		get_ok_button().disabled = true

func _on_confirmed():
	var selected = signal_tree.get_selected()
	if not selected or not selected.is_selectable(0):
		return
	
	var selected_signal_name = selected.get_text(0)
	signal_selected.emit(selected_signal_name)
	hide()
