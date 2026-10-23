extends Control

@onready var status_label: Label = $Content/StatusLabel

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://level_1.tscn")
