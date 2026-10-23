extends Node3D
## Isolated animation preview for the Universal Animation Library Standard mannequin.
## This is a test scene and does not replace the 2D game's main scene.

@onready var animation_player: AnimationPlayer = $UAL1_Standard/AnimationPlayer
@onready var camera: Camera3D = $Camera3D
@onready var status_label: Label = $CanvasLayer/Panel/StatusLabel

const CLIPS: Array[String] = [
	"Idle",
	"Walk",
	"Jog_Fwd",
	"Sprint",
	"Jump_Start",
	"Jump",
	"Jump_Land",
	"Crouch_Idle",
	"Crouch_Fwd",
	"Roll",
]

var clip_index := 0

func _ready() -> void:
	camera.look_at(Vector3(0.0, 1.0, 0.0), Vector3.UP)
	play_clip(0)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return

	match event.keycode:
		KEY_RIGHT, KEY_SPACE:
			play_clip((clip_index + 1) % CLIPS.size())
		KEY_LEFT:
			play_clip(posmod(clip_index - 1, CLIPS.size()))
		KEY_1:
			play_clip(0)
		KEY_2:
			play_clip(1)
		KEY_3:
			play_clip(2)
		KEY_4:
			play_clip(3)
		KEY_5:
			play_clip(4)
		KEY_6:
			play_clip(5)
		KEY_7:
			play_clip(6)
		KEY_8:
			play_clip(7)
		KEY_9:
			play_clip(8)
		KEY_0:
			play_clip(9)

func play_clip(index: int) -> void:
	if index < 0 or index >= CLIPS.size():
		return
	var clip_name := CLIPS[index]
	if not animation_player.has_animation(clip_name):
		status_label.text = "Missing animation: " + clip_name
		push_warning("Animation not found: " + clip_name)
		return
	clip_index = index
	animation_player.play(clip_name)
	status_label.text = "%s  (%d/%d)\n←/→ or Space: switch animation | 1–0: select" % [
		clip_name, clip_index + 1, CLIPS.size()
	]
