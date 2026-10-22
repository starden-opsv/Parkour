extends Control

@onready var status_label: Label = $Content/StatusLabel

func _on_start_pressed() -> void:
	status_label.text = "Скоро здесь начнётся игра!"
