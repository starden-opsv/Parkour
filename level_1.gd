extends Control

# MVP level: temporary geometric art, no external assets required.
const RUN_SPEED := 230.0
const GRAVITY := 1150.0
const JUMP_SPEED := -440.0
const SLIDE_DURATION := 0.62
const LEVEL_LENGTH := 3300.0
const PICKUP_POSITIONS := [430.0, 650.0, 880.0, 1110.0, 1390.0, 1630.0, 1880.0, 2110.0, 2350.0, 2580.0]

var world_x := 0.0
var player_y := 0.0
var player_vy := 0.0
var on_ground := true
var slide_timer := 0.0
var collected: Array[bool] = []
var ended := false
var painting := false
var paint_timer := 0.0
var result_text := ""
var result_color := Color.WHITE
var jump_requested := false
var slide_requested := false

func _ready() -> void:
	for _i in PICKUP_POSITIONS.size():
		collected.append(false)
	player_y = _ground_y() - 58.0
	queue_redraw()

func _ground_y() -> float:
	return size.y * 0.78

func _process(delta: float) -> void:
	if ended:
		if painting:
			paint_timer += delta
			if paint_timer >= 2.7:
				painting = false
			queue_redraw()
		return

	if jump_requested and on_ground and slide_timer <= 0.0:
		player_vy = JUMP_SPEED
		on_ground = false
	jump_requested = false

	if slide_requested and on_ground:
		slide_timer = SLIDE_DURATION
	slide_requested = false
	if slide_timer > 0.0:
		slide_timer = maxf(0.0, slide_timer - delta)

	world_x += RUN_SPEED * delta
	player_vy += GRAVITY * delta
	player_y += player_vy * delta
	if player_y >= _ground_y() - (26.0 if slide_timer > 0.0 else 58.0):
		player_y = _ground_y() - (26.0 if slide_timer > 0.0 else 58.0)
		player_vy = 0.0
		on_ground = true

	_check_pickups()
	_check_obstacles()
	if world_x >= LEVEL_LENGTH and not ended:
		_finish_level()
	queue_redraw()

func _check_pickups() -> void:
	var player_world := world_x + size.x * 0.22
	for i in PICKUP_POSITIONS.size():
		if not collected[i] and absf(PICKUP_POSITIONS[i] - player_world) < 36.0:
			collected[i] = true

func _check_obstacles() -> void:
	var player_world := world_x + size.x * 0.22
	var obstacles := [
		{"x": 760.0, "kind": "jump"},
		{"x": 1280.0, "kind": "slide"},
		{"x": 1800.0, "kind": "jump"},
		{"x": 2240.0, "kind": "slide"},
		{"x": 2760.0, "kind": "jump"}
	]
	for obstacle in obstacles:
		if absf(float(obstacle.x) - player_world) < 28.0:
			var avoided := (obstacle.kind == "jump" and not on_ground) or (obstacle.kind == "slide" and slide_timer > 0.0)
			if not avoided:
				_finish_level(true)
				return

func _finish_level(failed: bool = false) -> void:
	ended = true
	painting = not failed
	paint_timer = 0.0
	if failed:
		result_text = "Не получилось!"
		result_color = Color(1.0, 0.38, 0.32)
	else:
		var count := _collected_count()
		if count >= 9:
			result_text = "УНИКАЛЬНОЕ ГРАФФИТИ"
			result_color = Color(0.45, 0.95, 1.0)
		elif count >= 6:
			result_text = "ЭПИЧЕСКОЕ ГРАФФИТИ"
			result_color = Color(0.82, 0.55, 1.0)
		elif count >= 3:
			result_text = "РЕДКОЕ ГРАФФИТИ"
			result_color = Color(1.0, 0.77, 0.28)
		else:
			result_text = "ОБЫЧНОЕ ГРАФФИТИ"
			result_color = Color(0.72, 0.95, 0.72)
	queue_redraw()

func _collected_count() -> int:
	var total := 0
	for item in collected:
		if item:
			total += 1
	return total

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_handle_press(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_press(event.position)
	elif event is InputEventKey and event.pressed and not event.echo:
		if ended and (event.keycode == KEY_R or event.keycode == KEY_SPACE or event.keycode == KEY_ENTER):
			get_tree().reload_current_scene()
		elif event.keycode == KEY_SPACE or event.keycode == KEY_UP:
			jump_requested = true
		elif event.keycode == KEY_DOWN:
			slide_requested = true

func _handle_press(position: Vector2) -> void:
	if ended:
		get_tree().reload_current_scene()
	elif position.x > size.x * 0.68 and position.y > size.y * 0.62:
		slide_requested = true
	else:
		jump_requested = true

func _draw() -> void:
	var w := size.x
	var h := size.y
	var ground := _ground_y()
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.055, 0.09, 0.15))
	draw_rect(Rect2(0, ground, w, h - ground), Color(0.12, 0.16, 0.19))
	for i in range(0, int(w) + 80, 80):
		var x := float(i) - fmod(world_x, 80.0)
		draw_line(Vector2(x, ground + 18), Vector2(x + 34, ground + 18), Color(0.22, 0.28, 0.31), 2.0)
	for i in range(8):
		var bx := float(i) * 150.0 - fmod(world_x * 0.18, 150.0)
		draw_rect(Rect2(bx, ground - 100 - float((i * 17) % 60), 72, 120 + float((i * 17) % 60)), Color(0.075, 0.12, 0.18))
	for i in PICKUP_POSITIONS.size():
		if not collected[i]:
			var px := PICKUP_POSITIONS[i] - world_x + w * 0.22
			if px > -30 and px < w + 30:
				draw_circle(Vector2(px, ground - 54), 15, Color(0.12, 0.85, 0.88))
				draw_circle(Vector2(px, ground - 54), 8, Color(0.08, 0.16, 0.22))
				draw_line(Vector2(px - 5, ground - 54), Vector2(px + 5, ground - 54), Color.WHITE, 3.0)
	var obstacles := [
		{"x": 760.0, "kind": "jump"},
		{"x": 1280.0, "kind": "slide"},
		{"x": 1800.0, "kind": "jump"},
		{"x": 2240.0, "kind": "slide"},
		{"x": 2760.0, "kind": "jump"}
	]
	for obstacle in obstacles:
		var ox := float(obstacle.x) - world_x + w * 0.22
		if ox > -80 and ox < w + 80:
			if obstacle.kind == "jump":
				draw_rect(Rect2(ox - 20, ground - 48, 40, 48), Color(0.9, 0.42, 0.22))
				draw_line(Vector2(ox - 13, ground - 35), Vector2(ox + 13, ground - 35), Color(1.0, 0.8, 0.55), 3.0)
			else:
				draw_rect(Rect2(ox - 28, ground - 90, 56, 12), Color(0.88, 0.32, 0.28))
				draw_rect(Rect2(ox - 28, ground - 90, 8, 64), Color(0.88, 0.32, 0.28))
				draw_rect(Rect2(ox + 20, ground - 90, 8, 64), Color(0.88, 0.32, 0.28))
	var px := w * 0.22
	var ph := 26.0 if slide_timer > 0.0 else 58.0
	var py := player_y + (32.0 if slide_timer > 0.0 else 0.0)
	draw_rect(Rect2(px - 17, py, 34, ph), Color(0.25, 0.72, 1.0))
	draw_circle(Vector2(px + 5, py + 10), 4, Color.WHITE)
	draw_rect(Rect2(px - 20, py + ph - 4, 40, 5), Color(0.07, 0.1, 0.14))
	draw_rect(Rect2(18, 18, w - 36, 8), Color(0.16, 0.22, 0.28))
	draw_rect(Rect2(18, 18, (w - 36) * clampf(world_x / LEVEL_LENGTH, 0.0, 1.0), 8), Color(0.12, 0.85, 0.88))
	draw_string(ThemeDB.fallback_font, Vector2(22, 48), "ГРАФФИТИ: %d" % _collected_count(), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
	draw_circle(Vector2(w - 78, h - 68), 48, Color(0.1, 0.35, 0.48, 0.88))
	draw_string(ThemeDB.fallback_font, Vector2(w - 113, h - 60), "ПОДКАТ", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(24, h - 28), "КАСАНИЕ — ПРЫЖОК", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.85, 0.9, 0.96))
	if ended:
		_draw_result()

func _draw_result() -> void:
	var w := size.x
	var h := size.y
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.015, 0.025, 0.05, 0.82))
	if painting:
		draw_rect(Rect2(w * 0.27, h * 0.16, w * 0.46, h * 0.55), Color(0.32, 0.34, 0.37))
		for yy in range(0, 7):
			draw_line(Vector2(w * 0.27, h * 0.2 + yy * 35), Vector2(w * 0.73, h * 0.2 + yy * 35), Color(0.23, 0.25, 0.28), 2)
		for xx in range(0, 7):
			draw_line(Vector2(w * 0.27 + xx * (w * 0.46 / 7.0), h * 0.16), Vector2(w * 0.27 + xx * (w * 0.46 / 7.0), h * 0.71), Color(0.23, 0.25, 0.28), 1)
		if paint_timer > 0.45:
			var center := Vector2(w * 0.5, h * 0.43)
			var scale_factor := clampf((paint_timer - 0.45) / 1.4, 0.0, 1.0)
			for i in range(5):
				var angle := float(i) * TAU / 5.0
				var point := center + Vector2(cos(angle) * 92.0, sin(angle) * 48.0) * scale_factor
				draw_line(center, point, result_color, 13.0)
			draw_string(ThemeDB.fallback_font, Vector2(w * 0.36, h * 0.46), "TAG!", HORIZONTAL_ALIGNMENT_LEFT, -1, 48, result_color)
	draw_string(ThemeDB.fallback_font, Vector2(24, h * 0.82), result_text, HORIZONTAL_ALIGNMENT_CENTER, w - 48, 24, result_color)
	draw_string(ThemeDB.fallback_font, Vector2(24, h * 0.9), "Собрано: %d   •   Нажми, чтобы повторить" % _collected_count(), HORIZONTAL_ALIGNMENT_CENTER, w - 48, 16, Color.WHITE)
