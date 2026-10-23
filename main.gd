extends Control

@onready var status_label: Label = $Content/StatusLabel
@onready var background: TextureRect = $Background
@onready var content: VBoxContainer = $Content
@onready var spacer_top: Control = $Content/SpacerTop
@onready var title_label: Label = $Content/Title
@onready var subtitle_label: Label = $Content/Subtitle
@onready var tagline_label: Label = $Content/Tagline
@onready var start_button: Button = $Content/StartButton

func _ready() -> void:
	_responsive_layout()
	get_viewport().size_changed.connect(_responsive_layout)

func _responsive_layout() -> void:
	var viewport_size := get_viewport_rect().size
	var portrait := viewport_size.y >= viewport_size.x

	# Portrait: preserve the entire original image, allowing empty margins if needed.
	# Landscape: fill the screen with the image, cropping only as much as necessary.
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED if portrait else TextureRect.STRETCH_KEEP_ASPECT_COVERED

	if portrait:
		content.offset_left = 20.0
		content.offset_right = -20.0
		content.offset_top = 24.0
		content.offset_bottom = -24.0
		spacer_top.custom_minimum_size.y = viewport_size.y * 0.25
		title_label.add_theme_font_size_override("font_size", 38)
		subtitle_label.add_theme_font_size_override("font_size", 16)
		tagline_label.add_theme_font_size_override("font_size", 16)
		start_button.custom_minimum_size.y = 58.0
	else:
		content.offset_left = 26.0
		content.offset_right = -26.0
		content.offset_top = 42.0
		content.offset_bottom = -36.0
		spacer_top.custom_minimum_size.y = viewport_size.y * 0.36
		title_label.add_theme_font_size_override("font_size", 46)
		subtitle_label.add_theme_font_size_override("font_size", 18)
		tagline_label.add_theme_font_size_override("font_size", 18)
		start_button.custom_minimum_size.y = 62.0

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://level_1.tscn")
