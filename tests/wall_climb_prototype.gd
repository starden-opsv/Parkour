extends Node3D
## Isolated visual prototype: grab the wall lip, pull up, mantle onto the top.
## Gameplay position is deterministic; animation clips are only visual feedback.

@onready var character: Node3D = $Character
@onready var animation_player: AnimationPlayer = $Character/AnimationPlayer
@onready var status_label: Label = $CanvasLayer/Panel/Info/Status
@onready var climb_button: Button = $CanvasLayer/Panel/Info/ClimbButton

const START_POSITION := Vector3(-1.2, 0.0, 0.0)
const WALL_FRONT_X := 0.3
const WALL_TOP_Y := 1.8
const TOP_POSITION := Vector3(1.75, WALL_TOP_Y, 0.0)
const CLIMB_DURATION := 2.4

var climbing := false
var climb_elapsed := 0.0
var stage := "idle"

func _ready() -> void:
	character.position = START_POSITION
	_play_if_available("Idle")
	climb_button.pressed.connect(_on_climb_pressed)
	$CanvasLayer/Panel/Info/RestartButton.pressed.connect(_on_restart_pressed)
	status_label.text = "Подойди к стене и нажми E / «Карабкаться»."
	var wall_material := StandardMaterial3D.new()
	wall_material.albedo_color = Color("#55545b")
	$Wall.material_override = wall_material
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color("#303843")
	$Floor.material_override = floor_material

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E or event.keycode == KEY_SPACE:
			_on_climb_pressed()
		elif event.keycode == KEY_R:
			_on_restart_pressed()

func _process(delta: float) -> void:
	if not climbing:
		return
	climb_elapsed += delta
	var t := clampf(climb_elapsed / CLIMB_DURATION, 0.0, 1.0)
	if t < 0.18:
		stage = "grab"
		_play_if_available("Jump_Start")
		character.position = START_POSITION.lerp(Vector3(WALL_FRONT_X, 0.85, 0.0), _ease(t / 0.18))
	elif t < 0.64:
		stage = "pull_up"
		_play_if_available("Jump")
		character.position = Vector3(WALL_FRONT_X, 0.85, 0.0).lerp(Vector3(0.72, 1.95, 0.0), _ease((t - 0.18) / 0.46))
	elif t < 0.84:
		stage = "mantle"
		_play_if_available("Jump")
		character.position = Vector3(0.72, 1.95, 0.0).lerp(Vector3(1.25, 1.98, 0.0), _ease((t - 0.64) / 0.20))
	else:
		stage = "stand"
		_play_if_available("Jump_Land")
		character.position = Vector3(1.25, 1.98, 0.0).lerp(TOP_POSITION, _ease((t - 0.84) / 0.16))
	status_label.text = "Фаза: %s  •  %.0f%%" % [stage, t * 100.0]
	if t >= 1.0:
		climbing = false
		stage = "complete"
		character.position = TOP_POSITION
		_play_if_available("Idle")
		status_label.text = "Готово: персонаж оказался НАД стеной. R — повторить."
		climb_button.disabled = false

func _on_climb_pressed() -> void:
	if climbing:
		return
	character.position = START_POSITION
	climb_elapsed = 0.0
	climbing = true
	stage = "grab"
	climb_button.disabled = true
	status_label.text = "Захват края → подтягивание → выход на верх."
	_play_if_available("Jump_Start")

func _on_restart_pressed() -> void:
	climbing = false
	climb_elapsed = 0.0
	stage = "idle"
	character.position = START_POSITION
	climb_button.disabled = false
	_play_if_available("Idle")
	status_label.text = "Сброшено. Нажми E / «Карабкаться»."

func _play_if_available(clip_name: String) -> void:
	if animation_player and animation_player.has_animation(clip_name):
		if animation_player.current_animation != clip_name:
			animation_player.play(clip_name)

func _ease(t: float) -> float:
	var value := clampf(t, 0.0, 1.0)
	return value * value * (3.0 - 2.0 * value)
