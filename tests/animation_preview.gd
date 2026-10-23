extends Node3D
## Isolated preview for the Universal Animation Library Standard mannequin.
## Does not replace or modify the game's main scene.

@onready var animation_player: AnimationPlayer = $UAL1_Standard/AnimationPlayer
@onready var camera: Camera3D = $Camera3D

func _ready() -> void:
	camera.look_at(Vector3(0.0, 1.0, 0.0), Vector3.UP)
	if animation_player.has_animation("Idle"):
		animation_player.play("Idle")
	else:
		push_warning("The imported Standard GLB does not expose an 'Idle' animation.")
