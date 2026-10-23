extends Control

# MVP level: temporary geometric art, no external assets required.
const RUN_SPEED := 230.0
const GRAVITY := 1150.0
const JUMP_SPEED := -520.0
const SLIDE_DURATION := 0.78
const CLIMB_DURATION := 0.82
const CLIMB_RANGE := 105.0
const LEVEL_LENGTH := 3300.0
const PLAYER_X_RATIO := 0.22
const PLAYER_WIDTH := 38.0
const PLAYER_HEIGHT := 64.0
const SLIDE_HEIGHT := 24.0
const PICKUP_RADIUS := 15.0
const DEBUG_HITBOXES := false
const PICKUP_POSITIONS := [430.0, 650.0, 880.0, 1110.0, 1390.0, 1630.0, 1880.0, 2110.0, 2350.0, 2580.0]

var world_x := 0.0 # World coordinate of the player's feet; screen position stays fixed.
var player_y := 0.0 # Top of the player's collision rectangle in level-local coordinates.
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
var jump_count := 0
var slide_requested := false
var climb_requested := false
var climb_timer := 0.0
var character_anim_time := 0.0
var player_sprite: AnimatedSprite2D
var was_airborne := false

func _ready() -> void:
	for _i in PICKUP_POSITIONS.size():
		collected.append(false)
	player_y = _ground_y() - PLAYER_HEIGHT
	_setup_player_sprite()
	_update_player_sprite()
	queue_redraw()

func _ground_y() -> float:
	return size.y * 0.78

func _player_screen_x() -> float:
	return size.x * PLAYER_X_RATIO

func _player_height() -> float:
	return SLIDE_HEIGHT if slide_timer > 0.0 else PLAYER_HEIGHT

func _player_rect() -> Rect2:
	var height := _player_height()
	# player_y is already clamped using the active height, so crouching stays on the ground.
	return Rect2(_player_screen_x() - PLAYER_WIDTH * 0.5, player_y, PLAYER_WIDTH, height)

func _pickup_rect(screen_x: float, ground: float) -> Rect2:
	return Rect2(screen_x - PICKUP_RADIUS, ground - 54.0 - PICKUP_RADIUS, PICKUP_RADIUS * 2.0, PICKUP_RADIUS * 2.0)

func _process(delta: float) -> void:
	character_anim_time += delta
	if ended:
		if painting:
			paint_timer += delta
			if paint_timer >= 2.7:
				painting = false
			queue_redraw()
		return

	if climb_requested and on_ground and slide_timer <= 0.0 and climb_timer <= 0.0:
		_try_climb()
	climb_requested = false

	if jump_requested and slide_timer <= 0.0 and climb_timer <= 0.0:
		if on_ground:
			player_vy = JUMP_SPEED
			on_ground = false
			jump_count = 1
		elif jump_count == 1:
			# A second tap while airborne triggers one extra jump.
			player_vy = JUMP_SPEED * 0.92
			jump_count = 2
	jump_requested = false

	if slide_requested and on_ground and slide_timer <= 0.0 and climb_timer <= 0.0:
		slide_timer = SLIDE_DURATION
		player_y = _ground_y() - SLIDE_HEIGHT
	slide_requested = false
	if slide_timer > 0.0:
		slide_timer = maxf(0.0, slide_timer - delta)
		if slide_timer == 0.0 and on_ground:
			player_y = _ground_y() - PLAYER_HEIGHT

	if climb_timer > 0.0:
		climb_timer = maxf(0.0, climb_timer - delta)
		world_x += RUN_SPEED * 1.6 * delta
		var climb_progress := 1.0 - climb_timer / CLIMB_DURATION
		player_vy = 0.0
		player_y = _ground_y() - PLAYER_HEIGHT - sin(climb_progress * PI) * 135.0
		if climb_timer == 0.0:
			player_y = _ground_y() - PLAYER_HEIGHT
			on_ground = true
			jump_count = 0
	else:
		world_x += (RUN_SPEED * 1.35 if slide_timer > 0.0 else RUN_SPEED) * delta
		player_vy += GRAVITY * delta
		player_y += player_vy * delta
	if climb_timer <= 0.0 and player_y + _player_height() >= _ground_y():
		player_y = _ground_y() - _player_height()
		player_vy = 0.0
		on_ground = true
		jump_count = 0

	_check_pickups()
	_check_obstacles()
	if world_x >= LEVEL_LENGTH and not ended:
		_finish_level()
	_update_player_sprite()
	queue_redraw()

func _check_pickups() -> void:
	var player_rect := _player_rect()
	var player_x := _player_screen_x()
	var ground := _ground_y()
	for i in PICKUP_POSITIONS.size():
		if collected[i]:
			continue
		var pickup_screen_x: float = float(PICKUP_POSITIONS[i]) - world_x + player_x
		if player_rect.intersects(_pickup_rect(pickup_screen_x, ground)):
			collected[i] = true

func _obstacles() -> Array[Dictionary]:
	return [
		{"x": 760.0, "kind": "climb"},
		{"x": 1280.0, "kind": "slide"},
		{"x": 1800.0, "kind": "jump"},
		{"x": 2240.0, "kind": "slide"},
		{"x": 2760.0, "kind": "climb"}
	]

func _obstacle_rects(obstacle: Dictionary, screen_x: float, ground: float) -> Array[Rect2]:
	var rects: Array[Rect2] = []
	if str(obstacle["kind"]) == "jump":
		rects.append(Rect2(screen_x - 32.0, ground - 78.0, 64.0, 78.0))
	elif str(obstacle["kind"]) == "climb":
		rects.append(Rect2(screen_x - 34.0, ground - 112.0, 68.0, 112.0))
	else:
		# The low beam intersects a standing player but clears the crouched slide hitbox.
		rects.append(Rect2(screen_x - 28.0, ground - 52.0, 56.0, 12.0))
		rects.append(Rect2(screen_x - 28.0, ground - 52.0, 8.0, 26.0))
		rects.append(Rect2(screen_x + 20.0, ground - 52.0, 8.0, 26.0))
	return rects

func _try_climb() -> void:
	var player_x := _player_screen_x()
	for obstacle in _obstacles():
		if str(obstacle["kind"]) != "climb":
			continue
		var obstacle_screen_x: float = float(obstacle["x"]) - world_x + player_x
		var distance := obstacle_screen_x - player_x
		if distance >= -PLAYER_WIDTH and distance <= CLIMB_RANGE:
			climb_timer = CLIMB_DURATION
			on_ground = false
			player_vy = 0.0
			jump_count = 0
			return

func _check_obstacles() -> void:
	var player_rect := _player_rect()
	var player_x := _player_screen_x()
	var ground := _ground_y()
	for obstacle in _obstacles():
		if climb_timer > 0.0 and str(obstacle["kind"]) == "climb":
			continue
		var obstacle_screen_x: float = float(obstacle["x"]) - world_x + player_x
		if obstacle_screen_x < -80.0 or obstacle_screen_x > size.x + 80.0:
			continue
		for obstacle_rect in _obstacle_rects(obstacle, obstacle_screen_x, ground):
			if player_rect.intersects(obstacle_rect):
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

func _input(event: InputEvent) -> void:
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
		elif event.keycode == KEY_C or event.keycode == KEY_E:
			climb_requested = true

func _handle_press(position: Vector2) -> void:
	if ended:
		get_tree().reload_current_scene()
	elif position.y >= size.y * 0.62:
		var zone := position.x / maxf(size.x, 1.0)
		if zone < 0.34:
			jump_requested = true
		elif zone < 0.67:
			slide_requested = true
		else:
			climb_requested = true
	else:
		jump_requested = true

func _draw() -> void:
	var w := size.x
	var h := size.y
	var ground := _ground_y()
	var player_x := _player_screen_x()
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
			var pickup_x: float = float(PICKUP_POSITIONS[i]) - world_x + player_x
			if pickup_x > -30 and pickup_x < w + 30:
				draw_circle(Vector2(pickup_x, ground - 54), 15, Color(0.12, 0.85, 0.88))
				draw_circle(Vector2(pickup_x, ground - 54), 8, Color(0.08, 0.16, 0.22))
				draw_line(Vector2(pickup_x - 5, ground - 54), Vector2(pickup_x + 5, ground - 54), Color.WHITE, 3.0)
	for obstacle in _obstacles():
		var ox: float = float(obstacle["x"]) - world_x + player_x
		if ox > -80 and ox < w + 80:
			if str(obstacle["kind"]) == "jump":
				draw_rect(Rect2(ox - 32, ground - 78, 64, 78), Color(0.9, 0.42, 0.22))
				draw_line(Vector2(ox - 22, ground - 58), Vector2(ox + 22, ground - 58), Color(1.0, 0.8, 0.55), 4.0)
			elif str(obstacle["kind"]) == "climb":
				draw_rect(Rect2(ox - 34, ground - 112, 68, 112), Color(0.67, 0.38, 0.23))
				draw_rect(Rect2(ox - 27, ground - 100, 54, 7), Color(0.95, 0.69, 0.39))
				draw_rect(Rect2(ox - 27, ground - 76, 54, 7), Color(0.95, 0.69, 0.39))
			else:
				draw_rect(Rect2(ox - 28, ground - 52, 56, 12), Color(0.88, 0.32, 0.28))
				draw_rect(Rect2(ox - 28, ground - 52, 8, 26), Color(0.88, 0.32, 0.28))
				draw_rect(Rect2(ox + 20, ground - 52, 8, 26), Color(0.88, 0.32, 0.28))
			if DEBUG_HITBOXES:
				for hitbox in _obstacle_rects(obstacle, ox, ground):
					draw_rect(hitbox, Color(1.0, 0.2, 0.2, 0.9), false, 1.0)

	var player_rect := _player_rect()
	if DEBUG_HITBOXES:
		draw_rect(player_rect, Color(0.2, 1.0, 0.45, 0.95), false, 2.0)
	draw_rect(Rect2(18, 18, w - 36, 8), Color(0.16, 0.22, 0.28))
	draw_rect(Rect2(18, 18, (w - 36) * clampf(world_x / LEVEL_LENGTH, 0.0, 1.0), 8), Color(0.12, 0.85, 0.88))
	draw_string(ThemeDB.fallback_font, Vector2(22, 48), "ГРАФФИТИ: %d" % _collected_count(), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
	draw_circle(Vector2(w * 0.14, h - 68), 45, Color(0.12, 0.48, 0.62, 0.92))
	draw_string(ThemeDB.fallback_font, Vector2(w * 0.14 - 38, h - 61), "ПРЫЖОК", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)
	draw_circle(Vector2(w * 0.50, h - 68), 45, Color(0.1, 0.35, 0.48, 0.92))
	draw_string(ThemeDB.fallback_font, Vector2(w * 0.50 - 34, h - 61), "СКОЛЬЗ.", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)
	draw_circle(Vector2(w * 0.86, h - 68), 45, Color(0.35, 0.28, 0.52, 0.95))
	draw_string(ThemeDB.fallback_font, Vector2(w * 0.86 - 42, h - 61), "КАРАБК.", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(w * 0.5 - 160, h - 14), "ПРЫЖОК • СКОЛЬЖЕНИЕ • КАРАБКАНИЕ", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.85, 0.9, 0.96))
	if ended:
		_draw_result()

func _setup_player_sprite() -> void:
	player_sprite = AnimatedSprite2D.new()
	player_sprite.name = "PlayerSprite"
	player_sprite.centered = true
	player_sprite.scale = Vector2(0.48, 0.48)
	player_sprite.z_index = 5
	player_sprite.sprite_frames = SpriteFrames.new()
	player_sprite.sprite_frames.add_animation("idle")
	player_sprite.sprite_frames.set_animation_speed("idle", 7.0)
	player_sprite.sprite_frames.set_animation_loop("idle", true)
	player_sprite.sprite_frames.add_animation("run")
	player_sprite.sprite_frames.set_animation_speed("run", 12.0)
	player_sprite.sprite_frames.set_animation_loop("run", true)
	player_sprite.sprite_frames.add_animation("jump")
	player_sprite.sprite_frames.set_animation_speed("jump", 10.0)
	player_sprite.sprite_frames.set_animation_loop("jump", false)
	player_sprite.sprite_frames.add_animation("running_jump")
	player_sprite.sprite_frames.set_animation_speed("running_jump", 10.0)
	player_sprite.sprite_frames.set_animation_loop("running_jump", false)
	player_sprite.sprite_frames.add_animation("fall")
	player_sprite.sprite_frames.set_animation_speed("fall", 10.0)
	player_sprite.sprite_frames.set_animation_loop("fall", true)
	player_sprite.sprite_frames.add_animation("land")
	player_sprite.sprite_frames.set_animation_speed("land", 12.0)
	player_sprite.sprite_frames.set_animation_loop("land", false)
	player_sprite.sprite_frames.add_animation("dash")
	player_sprite.sprite_frames.set_animation_speed("dash", 12.0)
	player_sprite.sprite_frames.set_animation_loop("dash", true)
	_add_sprite_sheet("idle", "res://assets/character/character/idle/idle.png", 7, 1)
	_add_sprite_sheet("run", "res://assets/character/character/running/running.png", 12, 12)
	_add_sprite_sheet("jump", "res://assets/character/character/jumping/jump.png", 13, 13)
	_add_sprite_sheet("running_jump", "res://assets/character/character/runningjump/runningjump.png", 7, 7)
	_add_sprite_sheet("fall", "res://assets/character/character/falling/fall.png", 9, 3)
	_add_sprite_sheet("land", "res://assets/character/character/landing/land.png", 8, 8)
	_add_sprite_sheet("dash", "res://assets/character/character/dashing/dash.png", 5, 5)
	add_child(player_sprite)
	player_sprite.play("run")

func _add_sprite_sheet(animation_name: String, resource_path: String, frame_count: int, columns: int) -> void:
	var sheet := load(resource_path) as Texture2D
	if sheet == null:
		push_warning("Character sprite sheet could not be loaded: " + resource_path)
		return
	for frame_index in frame_count:
		var atlas_frame := AtlasTexture.new()
		atlas_frame.atlas = sheet
		var column := frame_index % columns
		var row := int(frame_index / columns)
		atlas_frame.region = Rect2(column * 128, row * 128, 128, 128)
		player_sprite.sprite_frames.add_frame(animation_name, atlas_frame)

func _update_player_sprite() -> void:
	if player_sprite == null:
		return
	var player_rect := _player_rect()
	player_sprite.position = Vector2(player_rect.position.x + player_rect.size.x * 0.5, player_rect.end.y - (12.0 if slide_timer > 0.0 else 31.0))
	player_sprite.scale = Vector2(0.48, 0.36) if slide_timer > 0.0 else Vector2(0.48, 0.48)
	player_sprite.visible = true
	var next_animation := "run"
	if slide_timer > 0.0:
		next_animation = "dash"
	elif not on_ground:
		if player_vy > 120.0:
			next_animation = "fall"
		elif jump_count >= 2:
			next_animation = "running_jump"
		else:
			next_animation = "jump"
	else:
		if was_airborne:
			next_animation = "land"
			was_airborne = false
		elif player_sprite.animation == "land" and player_sprite.is_playing():
			next_animation = "land"
	if not on_ground:
		was_airborne = true
	if player_sprite.animation != next_animation:
		player_sprite.play(next_animation)
	elif not player_sprite.is_playing() and next_animation != "land":
		player_sprite.play(next_animation)


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
	var heading := result_text
	if not painting:
		draw_string(ThemeDB.fallback_font, Vector2(24, h * 0.66), heading, HORIZONTAL_ALIGNMENT_CENTER, w - 48, 32, result_color)
		draw_string(ThemeDB.fallback_font, Vector2(24, h * 0.76), "Попробуй ещё раз", HORIZONTAL_ALIGNMENT_CENTER, w - 48, 24, Color.WHITE)
	else:
		draw_string(ThemeDB.fallback_font, Vector2(24, h * 0.78), heading, HORIZONTAL_ALIGNMENT_CENTER, w - 48, 24, result_color)
	draw_string(ThemeDB.fallback_font, Vector2(24, h * 0.9), "Собрано: %d   •   НАЖМИ, ЧТОБЫ НАЧАТЬ ЗАНОВО" % _collected_count(), HORIZONTAL_ALIGNMENT_CENTER, w - 48, 16, Color.WHITE)
