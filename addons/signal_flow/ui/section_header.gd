@tool
extends Button

@onready var label: Label = $HBoxContainer/Label
@onready var arrow_icon: TextureRect = $HBoxContainer/TextureRect

func _ready():
	# --- Apply theme resources to match Godot's native look ---
	var theme = EditorInterface.get_editor_theme()
	if theme:
		var bold_font = theme.get_font("bold", "EditorFonts")
		var font_size = theme.get_font_size("font_size", "Label")
		
		if bold_font:
			label.add_theme_font_override("font", bold_font)
		if font_size > 0:
			label.add_theme_font_size_override("font_size", font_size)

		var font_color = theme.get_color("font_color", "Label")
		label.add_theme_color_override("font_color", font_color)

	# Connect signals and set initial state
	toggled.connect(_on_toggled)
	_on_toggled(button_pressed)

func _on_toggled(is_pressed: bool):
	var theme = EditorInterface.get_editor_theme()
	if not theme:
		return

	var icon_down = theme.get_icon("CodeFoldDownArrow", "EditorIcons")
	var icon_right = theme.get_icon("CodeFoldedRightArrow", "EditorIcons")

	if is_pressed:
		arrow_icon.texture = icon_down
	else:
		arrow_icon.texture = icon_right

