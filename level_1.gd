extends Control

# MVP level: temporary geometric art, no external assets required.
const RUN_SPEED := 230.0
const GRAVITY := 1150.0
const JUMP_SPEED := -560.0
const SLIDE_DURATION := 0.78
const CLIMB_RANGE := 650.0
const CLIMB_UP_DURATION := 0.34
const CLIMB_DOWN_DURATION := 0.32
const CLIMB_OBSTACLE_HEIGHT := 112.0
const MIN_LEVEL_LENGTH := 4200.0
const MAX_LEVEL_LENGTH := 5000.0
const PLAYER_X_RATIO := 0.22
const PLAYER_WIDTH := 38.0
const PLAYER_HEIGHT := 64.0
const SLIDE_HEIGHT := 24.0
const PICKUP_RADIUS := 15.0
const DEBUG_HITBOXES := false
const MIN_PICKUPS := 14
const MAX_PICKUPS := 18
const GRAFFITI_EXAMPLE_PATHS: Array[String] = [
	"res://assets/graffiti-constructor/4 Examples/1Band.png",
	"res://assets/graffiti-constructor/4 Examples/2Squad13.png",
	"res://assets/graffiti-constructor/4 Examples/3Sport.png",
	"res://assets/graffiti-constructor/4 Examples/4Shortway.png",
	"res://assets/graffiti-constructor/4 Examples/5Greenteam.png",
	"res://assets/graffiti-constructor/4 Examples/6Benice.png",
	"res://assets/graffiti-constructor/4 Examples/7Dangerarea.png",
	"res://assets/graffiti-constructor/4 Examples/8Loot.png"
]

var rng := RandomNumberGenerator.new()
var level_seed: int = 0
var level_length: float = 4600.0
var pickup_positions: Array[float] = []
var obstacle_layout: Array[Dictionary] = []
var spray_can_positions: Array[float] = []
var shield_active := false
var shield_invulnerability := 0.0
var combo_count := 0
var combo_timer := 0.0
var run_score := 0
var best_score := 0
var best_score_path := "user://parkour_progress.cfg"
var hit_flash_timer := 0.0

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
var finish_flash_time := 0.0
var jump_requested := false
var jump_count := 0
var slide_requested := false
var climb_requested := false
var climb_timer := 0.0
var climb_state := "" # approach -> up -> cross -> down
var climb_target_x := -1.0
var climb_phase_timer := 0.0
var climb_start_y := 0.0
var character_anim_time := 0.0
var player_sprite: Sprite2D
var character_viewport: SubViewport
var character_animation_player: AnimationPlayer
var current_character_animation := ""
var was_airborne := false
var parallax_layers: Array[Dictionary] = []
var graffiti_full_texture: Texture2D
var graffiti_partial_texture: Texture2D
var end_graffiti_texture: Texture2D
const PARALLAX_LAYER_DEFS := [
	{"path": "res://assets/background/post_soviet_city_parallax/post_soviet_city_parallax/layer_2_stars.png", "speed": 0.015},
	{"path": "res://assets/background/post_soviet_city_parallax/post_soviet_city_parallax/layer_3_moon.png", "speed": 0.02},
	{"path": "res://assets/background/post_soviet_city_parallax/post_soviet_city_parallax/layer_4_clouds_1.png", "speed": 0.035},
	{"path": "res://assets/background/post_soviet_city_parallax/post_soviet_city_parallax/layer_5_clouds_2.png", "speed": 0.055},
	{"path": "res://assets/background/post_soviet_city_parallax/post_soviet_city_parallax/layer_6_far_buildings.png", "speed": 0.10},
	{"path": "res://assets/background/post_soviet_city_parallax/post_soviet_city_parallax/layer_7_bg_buildings.png", "speed": 0.17},
	{"path": "res://assets/background/post_soviet_city_parallax/post_soviet_city_parallax/layer_8_fg_buildings.png", "speed": 0.28}
]

func _ready() -> void:
	_load_parallax_layers()
	_load_best_score()
	# Wildstyle is generated locally from the level seed; no fixed name/art asset is required.
	rng.randomize()
	level_seed = int(rng.randi())
	rng.seed = level_seed
	_generate_level_layout()
	for _i in pickup_positions.size():
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
	combo_timer = maxf(0.0, combo_timer - delta)
	if combo_timer <= 0.0:
		combo_count = 0
	shield_invulnerability = maxf(0.0, shield_invulnerability - delta)
	hit_flash_timer = maxf(0.0, hit_flash_timer - delta)
	if ended:
		if painting:
			paint_timer += delta
			if paint_timer >= 2.7:
				painting = false
			queue_redraw()
		return

	if jump_requested and slide_timer <= 0.0 and climb_state.is_empty():
		if on_ground:
			player_vy = JUMP_SPEED
			on_ground = false
			jump_count = 1
		elif jump_count == 1:
			# A second tap while airborne triggers one extra jump.
			player_vy = JUMP_SPEED * 0.92
			jump_count = 2
	jump_requested = false

	if slide_requested and on_ground and slide_timer <= 0.0 and climb_state.is_empty():
		slide_timer = SLIDE_DURATION
		player_y = _ground_y() - SLIDE_HEIGHT
	slide_requested = false
	if slide_timer > 0.0:
		slide_timer = maxf(0.0, slide_timer - delta)
		if slide_timer == 0.0 and on_ground:
			player_y = _ground_y() - PLAYER_HEIGHT

	if not climb_state.is_empty():
		_process_climb(delta)
	else:
		world_x += (_current_run_speed() * 1.35 if slide_timer > 0.0 else _current_run_speed()) * delta
		player_vy += GRAVITY * delta
		player_y += player_vy * delta
		if player_y + _player_height() >= _ground_y():
			player_y = _ground_y() - _player_height()
			player_vy = 0.0
			on_ground = true
			jump_count = 0

	_check_pickups()
	_check_obstacles()
	if world_x >= level_length and not ended:
		_finish_level()
	_update_player_sprite()
	queue_redraw()

func _check_pickups() -> void:
	var player_rect := _player_rect()
	var player_x := _player_screen_x()
	var ground := _ground_y()
	for i in pickup_positions.size():
		if collected[i]:
			continue
		var pickup_screen_x: float = pickup_positions[i] - world_x + player_x
		if player_rect.intersects(_pickup_rect(pickup_screen_x, ground)):
			collected[i] = true
			_register_pickup()
	for can_x in spray_can_positions:
		var can_screen_x: float = can_x - world_x + player_x
		if can_screen_x < player_x - 40.0 or can_screen_x > player_x + 40.0:
			continue
		if player_rect.intersects(Rect2(can_screen_x - 18.0, ground - 100.0, 36.0, 46.0)):
			spray_can_positions.erase(can_x)
			shield_active = true
			run_score += 250
			combo_count = mini(combo_count + 1, 9)
			combo_timer = 3.0
			return

func _generate_level_layout() -> void:
	level_length = snappedf(rng.randf_range(MIN_LEVEL_LENGTH, MAX_LEVEL_LENGTH), 100.0)
	pickup_positions.clear()
	obstacle_layout.clear()

	var obstacle_x := 620.0
	var previous_kind := ""
	var repeated_kind_count := 0
	while obstacle_x < level_length - 380.0:
		var roll := rng.randi_range(0, 99)
		var kind := "jump"
		if obstacle_layout.size() == 0:
			kind = "jump" # Teach the basic jump first.
		elif obstacle_layout.size() == 1:
			kind = "slide" # Then introduce the low-beam slide.
		elif obstacle_layout.size() == 2:
			kind = "double_jump" # Taller barrier introduces the second airborne jump.
		elif roll < 50:
			kind = "slide"
		else:
			kind = "jump"
		if kind == previous_kind:
			repeated_kind_count += 1
		else:
			repeated_kind_count = 1
		if repeated_kind_count >= 3:
			kind = "jump" if previous_kind != "jump" else "slide"
			repeated_kind_count = 1
		obstacle_layout.append({"x": obstacle_x, "kind": kind})
		previous_kind = kind
		obstacle_x += rng.randf_range(410.0, 560.0)

	var desired_pickups := rng.randi_range(MIN_PICKUPS, MAX_PICKUPS)
	var attempts := 0
	while pickup_positions.size() < desired_pickups and attempts < 500:
		attempts += 1
		var candidate := rng.randf_range(300.0, level_length - 260.0)
		var valid := true
		for existing in pickup_positions:
			if absf(existing - candidate) < 165.0:
				valid = false
				break
		if not valid:
			continue
		for obstacle in obstacle_layout:
			if absf(float(obstacle["x"]) - candidate) < 115.0:
				valid = false
				break
		if valid:
			pickup_positions.append(candidate)
	
	# Rare spray cans grant one-hit protection; keep them clear of hazards and tokens.
	var can_attempts := 0
	while spray_can_positions.size() < 2 and can_attempts < 200:
		can_attempts += 1
		var can_candidate := rng.randf_range(500.0, level_length - 350.0)
		var can_valid := true
		for existing in pickup_positions:
			if absf(existing - can_candidate) < 90.0:
				can_valid = false
				break
		for obstacle in obstacle_layout:
			if absf(float(obstacle["x"]) - can_candidate) < 150.0:
				can_valid = false
				break
		if can_valid:
			spray_can_positions.append(can_candidate)

	if pickup_positions.size() < MIN_PICKUPS:
		pickup_positions.clear()
		var spacing := (level_length - 620.0) / float(MIN_PICKUPS)
		for index in MIN_PICKUPS:
			pickup_positions.append(310.0 + spacing * float(index) + spacing * 0.5)
	pickup_positions.sort()
	# Deterministic fallback keeps the rare bonus available even in crowded random layouts.
	var fallback_x := 420.0
	while spray_can_positions.size() < 2 and fallback_x < level_length - 250.0:
		var fallback_valid := true
		for existing in pickup_positions:
			if absf(existing - fallback_x) < 105.0:
				fallback_valid = false
				break
		for obstacle in obstacle_layout:
			if absf(float(obstacle["x"]) - fallback_x) < 155.0:
				fallback_valid = false
				break
		if fallback_valid:
			spray_can_positions.append(fallback_x)
		fallback_x += 45.0
	spray_can_positions.sort()
	print("Generated parkour run seed=%d length=%.0f pickups=%d spray_cans=%d obstacles=%d" % [
		level_seed, level_length, pickup_positions.size(), spray_can_positions.size(), obstacle_layout.size()
	])

func _obstacles() -> Array[Dictionary]:
	return obstacle_layout

func _obstacle_rects(obstacle: Dictionary, screen_x: float, ground: float) -> Array[Rect2]:
	var rects: Array[Rect2] = []
	if str(obstacle["kind"]) == "jump":
		rects.append(Rect2(screen_x - 32.0, ground - 78.0, 64.0, 78.0))
	elif str(obstacle["kind"]) == "double_jump":
		rects.append(Rect2(screen_x - 34.0, ground - 118.0, 68.0, 118.0))
	else:
		# The low beam intersects a standing player but clears the crouched slide hitbox.
		rects.append(Rect2(screen_x - 28.0, ground - 52.0, 56.0, 12.0))
		rects.append(Rect2(screen_x - 28.0, ground - 52.0, 8.0, 26.0))
		rects.append(Rect2(screen_x + 20.0, ground - 52.0, 8.0, 26.0))
	return rects

func _try_climb() -> void:
	# The climb button is an assisted parkour action: approach, mantle, cross, drop.
	# Only start if a climbable block is close enough and no other obstacle comes first.
	var nearest_climb_x := -1.0
	var nearest_distance := CLIMB_RANGE + 1.0
	for obstacle in _obstacles():
		var distance: float = float(obstacle["x"]) - world_x
		if distance < -PLAYER_WIDTH or distance > CLIMB_RANGE:
			continue
		if str(obstacle["kind"]) == "climb" and distance < nearest_distance:
			nearest_distance = distance
			nearest_climb_x = float(obstacle["x"])
	if nearest_climb_x < 0.0:
		return
	for obstacle in _obstacles():
		var distance: float = float(obstacle["x"]) - world_x
		if distance >= -PLAYER_WIDTH and distance < nearest_distance and str(obstacle["kind"]) != "climb":
			return
	climb_target_x = nearest_climb_x
	climb_state = "approach"
	climb_phase_timer = 0.0
	climb_start_y = player_y
	on_ground = true
	player_vy = 0.0
	jump_count = 0

func _process_climb(delta: float) -> void:
	var ground := _ground_y()
	var top_y := ground - PLAYER_HEIGHT - CLIMB_OBSTACLE_HEIGHT
	var speed := _current_run_speed()
	player_vy = 0.0
	match climb_state:
		"approach":
			# Keep running until the character reaches the front face of the block.
			var obstacle_screen_x := climb_target_x - world_x + _player_screen_x()
			if obstacle_screen_x > _player_screen_x() + PLAYER_WIDTH * 0.5 + 2.0:
				world_x += speed * delta
				player_y = ground - PLAYER_HEIGHT
			else:
				climb_state = "up"
				climb_phase_timer = 0.0
				climb_start_y = player_y
				on_ground = false
		"up":
			climb_phase_timer = minf(1.0, climb_phase_timer + delta / CLIMB_UP_DURATION)
			player_y = lerpf(ground - PLAYER_HEIGHT, top_y, _ease_out(climb_phase_timer))
			if climb_phase_timer >= 1.0:
				climb_state = "cross"
				climb_phase_timer = 0.0
				player_y = top_y
		"cross":
			# Run across the obstacle top; don't freeze in place on the ledge.
			world_x += speed * delta
			player_y = top_y
			var obstacle_right_screen_x := climb_target_x + 34.0 - world_x + _player_screen_x()
			if obstacle_right_screen_x < _player_screen_x() - PLAYER_WIDTH * 0.5:
				climb_state = "down"
				climb_phase_timer = 0.0
				climb_start_y = player_y
		"down":
			climb_phase_timer = minf(1.0, climb_phase_timer + delta / CLIMB_DOWN_DURATION)
			player_y = lerpf(climb_start_y, ground - PLAYER_HEIGHT, _ease_in(climb_phase_timer))
			world_x += speed * 0.35 * delta
			if climb_phase_timer >= 1.0:
				climb_state = ""
				climb_target_x = -1.0
				climb_phase_timer = 0.0
				player_y = ground - PLAYER_HEIGHT
				on_ground = true
				jump_count = 0

func _ease_out(t: float) -> float:
	return 1.0 - pow(1.0 - clampf(t, 0.0, 1.0), 3.0)

func _ease_in(t: float) -> float:
	return pow(clampf(t, 0.0, 1.0), 2.0)

func _check_obstacles() -> void:
	var player_rect := _player_rect()
	var player_x := _player_screen_x()
	var ground := _ground_y()
	for obstacle in _obstacles():
		if not climb_state.is_empty() and str(obstacle["kind"]) == "climb" and is_equal_approx(float(obstacle["x"]), climb_target_x):
			continue
		var obstacle_screen_x: float = float(obstacle["x"]) - world_x + player_x
		if obstacle_screen_x < -80.0 or obstacle_screen_x > size.x + 80.0:
			continue
		for obstacle_rect in _obstacle_rects(obstacle, obstacle_screen_x, ground):
			if player_rect.intersects(obstacle_rect):
				if shield_active and shield_invulnerability <= 0.0:
					shield_active = false
					shield_invulnerability = 1.1
					hit_flash_timer = 0.55
					world_x += 100.0
					return
				if shield_invulnerability > 0.0:
					return
				_finish_level(true)
				return

func _finish_level(failed: bool = false) -> void:
	ended = true
	painting = not failed
	combo_count = 0
	combo_timer = 0.0
	paint_timer = 0.0
	if failed:
		result_text = "Не получилось!"
		result_color = Color(1.0, 0.38, 0.32)
	else:
		var count := _collected_count()
		if count == pickup_positions.size():
			result_text = "ШЕДЕВР ЗАВЕРШЁН"
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
	if not failed:
		run_score += _collected_count() * 100
		# Choose one of the bundled graffiti examples for this completed run.
		var graffiti_path: String = GRAFFITI_EXAMPLE_PATHS[rng.randi_range(0, GRAFFITI_EXAMPLE_PATHS.size() - 1)]
		end_graffiti_texture = load(graffiti_path) as Texture2D
		if end_graffiti_texture == null:
			push_warning("Could not load end-of-level graffiti: " + graffiti_path)
	_save_best_score()
	queue_redraw()

func _current_run_speed() -> float:
	return RUN_SPEED * (1.0 + 0.12 * clampf(world_x / level_length, 0.0, 1.0))

func _register_pickup() -> void:
	if combo_timer > 0.0:
		combo_count = mini(combo_count + 1, 9)
	else:
		combo_count = 1
	combo_timer = 3.0
	run_score += 100 * combo_count

func _load_best_score() -> void:
	var config := ConfigFile.new()
	if config.load(best_score_path) == OK:
		best_score = int(config.get_value("progress", "best_score", 0))

func _save_best_score() -> void:
	if run_score <= best_score:
		return
	best_score = run_score
	var config := ConfigFile.new()
	config.set_value("progress", "best_score", best_score)
	var error := config.save(best_score_path)
	if error != OK:
		push_warning("Could not save local best score: %s" % error_string(error))

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
			jump_requested = true
	else:
		jump_requested = true

func _load_parallax_layers() -> void:
	parallax_layers.clear()
	for layer_def in PARALLAX_LAYER_DEFS:
		var texture := load(str(layer_def["path"])) as Texture2D
		if texture == null:
			push_warning("Parallax layer missing: " + str(layer_def["path"]))
			continue
		parallax_layers.append({"texture": texture, "speed": float(layer_def["speed"])})

func _draw_parallax_layer(texture: Texture2D, speed: float, ground: float) -> void:
	# Fit each layer to the viewport height, then repeat it horizontally.
	# Wrapping the offset by the tile width avoids gaps during endless running.
	var tile_height := maxf(ground, 1.0)
	var scale_factor := tile_height / float(texture.get_height())
	var tile_width := maxf(float(texture.get_width()) * scale_factor, 1.0)
	var offset := fmod(world_x * speed, tile_width)
	var x := -offset
	while x < size.x:
		draw_texture_rect(texture, Rect2(Vector2(x, 0.0), Vector2(tile_width, tile_height)), false)
		x += tile_width

func _draw() -> void:
	var w := size.x
	var h := size.y
	var ground := _ground_y()
	var player_x := _player_screen_x()
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.055, 0.09, 0.15))
	for layer in parallax_layers:
		_draw_parallax_layer(layer["texture"] as Texture2D, float(layer["speed"]), ground)
	draw_rect(Rect2(0, ground, w, h - ground), Color(0.12, 0.16, 0.19))
	for i in range(0, int(w) + 80, 80):
		var x := float(i) - fmod(world_x, 80.0)
		draw_line(Vector2(x, ground + 18), Vector2(x + 34, ground + 18), Color(0.22, 0.28, 0.31), 2.0)
	for i in pickup_positions.size():
		if not collected[i]:
			var pickup_x: float = pickup_positions[i] - world_x + player_x
			if pickup_x > -30 and pickup_x < w + 30:
				var pulse := 1.0 + 0.12 * sin(character_anim_time * 5.0 + float(i))
				draw_circle(Vector2(pickup_x, ground - 54), 15.0 * pulse, Color(0.12, 0.85, 0.88, 0.22))
				draw_circle(Vector2(pickup_x, ground - 54), 12.0, Color(0.12, 0.85, 0.88))
				draw_circle(Vector2(pickup_x, ground - 54), 6.0, Color(0.08, 0.16, 0.22))
				draw_line(Vector2(pickup_x - 5, ground - 54), Vector2(pickup_x + 5, ground - 54), Color.WHITE, 3.0)
	for can_x in spray_can_positions:
		var can_screen_x: float = can_x - world_x + player_x
		if can_screen_x > -40 and can_screen_x < w + 40:
			var can_rect := Rect2(can_screen_x - 11.0, ground - 92.0, 22.0, 34.0)
			draw_rect(can_rect.grow(5.0), Color(0.78, 0.32, 1.0, 0.2))
			draw_rect(can_rect, Color(0.76, 0.3, 1.0))
			draw_rect(Rect2(can_screen_x - 7.0, ground - 99.0, 14.0, 8.0), Color(0.94, 0.88, 1.0))
			draw_line(Vector2(can_screen_x - 6.0, ground - 77.0), Vector2(can_screen_x + 6.0, ground - 77.0), Color.WHITE, 3.0)
	for obstacle in _obstacles():
		var ox: float = float(obstacle["x"]) - world_x + player_x
		if ox > -80 and ox < w + 80:
			if str(obstacle["kind"]) == "jump":
				# Roadwork barrier: silhouette, reflective stripes and feet read clearly at speed.
				draw_rect(Rect2(ox - 35, ground - 76, 70, 76), Color(0.18, 0.12, 0.12, 0.28))
				draw_rect(Rect2(ox - 32, ground - 72, 64, 72), Color(0.82, 0.25, 0.17))
				draw_rect(Rect2(ox - 32, ground - 55, 64, 13), Color(1.0, 0.83, 0.48))
				draw_rect(Rect2(ox - 32, ground - 31, 64, 13), Color(1.0, 0.83, 0.48))
				draw_rect(Rect2(ox - 38, ground - 7, 76, 7), Color(0.24, 0.27, 0.3))
			elif str(obstacle["kind"]) == "climb":
				# Stack of tagged concrete blocks with a bright top lip: this is the climb target.
				draw_rect(Rect2(ox - 38, ground - 112, 76, 112), Color(0.12, 0.10, 0.13, 0.3))
				draw_rect(Rect2(ox - 34, ground - 112, 68, 112), Color(0.43, 0.38, 0.34))
				for row in range(4):
					var by := ground - 88.0 + float(row) * 25.0
					draw_line(Vector2(ox - 32, by), Vector2(ox + 32, by), Color(0.25, 0.24, 0.24), 3.0)
					draw_line(Vector2(ox - 8, by - 22), Vector2(ox - 8, by), Color(0.25, 0.24, 0.24), 2.0)
				draw_rect(Rect2(ox - 35, ground - 116, 70, 8), Color(0.12, 0.85, 0.88))
				draw_rect(Rect2(ox - 24, ground - 90, 48, 22), Color(0.9, 0.25, 0.64))
				draw_string(ThemeDB.fallback_font, Vector2(ox - 20, ground - 74), "UP", HORIZONTAL_ALIGNMENT_LEFT, 40, 12, Color.WHITE)
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
	draw_rect(Rect2(18, 18, (w - 36) * clampf(world_x / level_length, 0.0, 1.0), 8), Color(0.12, 0.85, 0.88))
	_draw_finish_marker(w, ground, player_x)
	draw_string(ThemeDB.fallback_font, Vector2(22, 48), "ГРАФФИТИ: %d/%d" % [_collected_count(), pickup_positions.size()], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(22, 72), "ОЧКИ: %d  РЕКОРД: %d" % [run_score, best_score], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.92, 0.95, 1.0))
	if combo_count >= 2 and combo_timer > 0.0:
		draw_string(ThemeDB.fallback_font, Vector2(w * 0.5 - 90.0, 54.0), "КОМБО x%d" % combo_count, HORIZONTAL_ALIGNMENT_CENTER, 180.0, 24, Color(1.0, 0.78, 0.25))
	if shield_active:
		draw_string(ThemeDB.fallback_font, Vector2(w - 210.0, 48.0), "ЗАЩИТА: 1 УДАР", HORIZONTAL_ALIGNMENT_RIGHT, 190.0, 16, Color(0.84, 0.58, 1.0))
	elif shield_invulnerability > 0.0:
		draw_string(ThemeDB.fallback_font, Vector2(w - 210.0, 48.0), "ЩИТ СРАБОТАЛ!", HORIZONTAL_ALIGNMENT_RIGHT, 190.0, 16, Color(0.84, 0.58, 1.0))
	if hit_flash_timer > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.8, 0.3, 1.0, hit_flash_timer * 0.25))
	draw_circle(Vector2(w * 0.14, h - 68), 45, Color(0.12, 0.48, 0.62, 0.92))
	draw_string(ThemeDB.fallback_font, Vector2(w * 0.14 - 38, h - 61), "ПРЫЖОК", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)
	draw_circle(Vector2(w * 0.50, h - 68), 45, Color(0.1, 0.35, 0.48, 0.92))
	draw_string(ThemeDB.fallback_font, Vector2(w * 0.50 - 34, h - 61), "СКОЛЬЗ.", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)
	draw_circle(Vector2(w * 0.86, h - 68), 45, Color(0.35, 0.28, 0.52, 0.95))
	draw_string(ThemeDB.fallback_font, Vector2(w * 0.86 - 42, h - 61), "ЗАЛЕЗТЬ", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(w * 0.5 - 160, h - 14), "ПРЫЖОК • СКОЛЬЖЕНИЕ • КАРАБКАНИЕ", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.85, 0.9, 0.96))
	if ended:
		_draw_result()

func _draw_finish_marker(view_width: float, ground: float, player_x: float) -> void:
	var marker_x := level_length - world_x + player_x
	if marker_x < player_x + 24.0 or marker_x > view_width + 100.0:
		return
	var top := ground - 150.0
	var glow := 0.5 + 0.5 * sin(character_anim_time * 4.0)
	draw_line(Vector2(marker_x - 42.0, ground), Vector2(marker_x - 42.0, top + 18.0), Color(0.12, 0.85, 0.88, 0.8), 7.0)
	draw_line(Vector2(marker_x + 42.0, ground), Vector2(marker_x + 42.0, top + 18.0), Color(0.12, 0.85, 0.88, 0.8), 7.0)
	draw_line(Vector2(marker_x - 42.0, top + 18.0), Vector2(marker_x + 42.0, top + 18.0), Color(0.12, 0.85, 0.88, 0.8), 7.0)
	draw_rect(Rect2(marker_x - 35.0, top + 25.0, 14.0, 14.0), Color.WHITE)
	draw_rect(Rect2(marker_x - 21.0, top + 39.0, 14.0, 14.0), Color(0.08, 0.12, 0.18))
	draw_rect(Rect2(marker_x - 7.0, top + 25.0, 14.0, 14.0), Color.WHITE)
	draw_rect(Rect2(marker_x + 7.0, top + 39.0, 14.0, 14.0), Color(0.08, 0.12, 0.18))
	draw_rect(Rect2(marker_x + 21.0, top + 25.0, 14.0, 14.0), Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(marker_x - 58.0, top - 12.0), "ФИНИШ", HORIZONTAL_ALIGNMENT_CENTER, 116.0, 22, Color(0.3, 1.0, 0.88, 0.65 + glow * 0.35))

func _setup_player_sprite() -> void:
	# Render the 3D Universal Animation Library mannequin into a transparent 2D viewport.
	# The game remains a 2D side-scroller; gameplay physics and hitboxes stay independent.
	character_viewport = SubViewport.new()
	character_viewport.name = "CharacterViewport"
	character_viewport.size = Vector2i(256, 256)
	character_viewport.transparent_bg = true
	character_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	character_viewport.msaa_3d = Viewport.MSAA_2X
	add_child(character_viewport)

	var character_world := Node3D.new()
	character_world.name = "CharacterWorld"
	character_viewport.add_child(character_world)

	var character_scene := load("res://assets/Universal Animation Library[Standard]/Unreal-Godot/UAL1_Standard.glb") as PackedScene
	if character_scene == null:
		push_error("Could not load Universal Animation Library Standard character.")
		return
	var character := character_scene.instantiate() as Node3D
	if character == null:
		push_error("Standard character scene root is not Node3D.")
		return
	character.name = "UAL1_Standard"
	# Turn the mannequin into a side-on runner facing screen-right.
	character.rotation_degrees.y = 90.0
	character_world.add_child(character)

	character_animation_player = character.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if character_animation_player == null:
		push_error("Standard character has no AnimationPlayer.")
		return

	var camera := Camera3D.new()
	camera.name = "CharacterCamera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.2
	camera.position = Vector3(0.0, 1.0, 4.5)
	camera.current = true
	character_world.add_child(camera)
	camera.look_at(Vector3(0.0, 1.0, 0.0), Vector3.UP)

	var key_light := DirectionalLight3D.new()
	key_light.name = "CharacterKeyLight"
	key_light.rotation_degrees = Vector3(-25.0, -35.0, 0.0)
	key_light.light_energy = 1.6
	key_light.shadow_enabled = false
	character_world.add_child(key_light)

	var fill_light := OmniLight3D.new()
	fill_light.name = "CharacterFillLight"
	fill_light.position = Vector3(1.5, 2.0, 2.0)
	fill_light.light_energy = 0.65
	fill_light.omni_range = 8.0
	character_world.add_child(fill_light)

	player_sprite = Sprite2D.new()
	player_sprite.name = "PlayerSprite"
	player_sprite.centered = true
	player_sprite.texture = character_viewport.get_texture()
	player_sprite.scale = Vector2(0.31, 0.31)
	player_sprite.z_index = 5
	add_child(player_sprite)
	_play_character_animation("Jog_Fwd")


func _play_character_animation(animation_name: String) -> void:
	if character_animation_player == null:
		return
	if not character_animation_player.has_animation(animation_name):
		push_warning("Standard character animation is missing: " + animation_name)
		return
	if current_character_animation == animation_name and character_animation_player.is_playing():
		return
	current_character_animation = animation_name
	character_animation_player.play(animation_name)


func _update_player_sprite() -> void:
	if player_sprite == null:
		return
	var player_rect := _player_rect()
	player_sprite.position = Vector2(
		player_rect.position.x + player_rect.size.x * 0.5,
		player_rect.end.y - (12.0 if slide_timer > 0.0 else 31.0)
	)
	player_sprite.scale = Vector2(0.31, 0.31)
	player_sprite.visible = true

	var next_animation := "Jog_Fwd"
	if slide_timer > 0.0:
		next_animation = "Roll"
	elif not on_ground:
		if jump_count >= 2 or player_vy < -120.0:
			next_animation = "Jump"
		else:
			next_animation = "Jump"
	else:
		if was_airborne:
			next_animation = "Jump_Land"
			was_airborne = false
		elif current_character_animation == "Jump_Land" and character_animation_player != null and character_animation_player.is_playing():
			next_animation = "Jump_Land"
	if not on_ground:
		was_airborne = true
	_play_character_animation(next_animation)


func _draw_result() -> void:
	var w := size.x
	var h := size.y
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.015, 0.025, 0.05, 0.88))
	var success := result_text != "Не получилось!"
	if success:
		# The wall is the end-of-level reward: unfinished unless every tag was collected.
		var all_collected := _collected_count() == pickup_positions.size()
		var mural_rect := Rect2(w * 0.16, h * 0.08, w * 0.68, h * 0.50)
		_draw_example_graffiti(mural_rect)
		var count := _collected_count()
		var progress_label := "ГРАФФИТИ ЗАКРАШЕНО: %d/%d" % [count, pickup_positions.size()]
		var progress_color := Color(0.38, 1.0, 0.78) if all_collected else Color(0.92, 0.76, 0.48)
		draw_string(ThemeDB.fallback_font, Vector2(20, h * 0.65), progress_label, HORIZONTAL_ALIGNMENT_CENTER, w - 40, 22, progress_color)
		var heading := result_text
		draw_string(ThemeDB.fallback_font, Vector2(24, h * 0.76), heading, HORIZONTAL_ALIGNMENT_CENTER, w - 48, 28, result_color)
		draw_string(ThemeDB.fallback_font, Vector2(24, h * 0.80), "СЧЁТ: %d  •  РЕКОРД: %d" % [run_score, best_score], HORIZONTAL_ALIGNMENT_CENTER, w - 48, 20, Color(1.0, 0.88, 0.55))
		draw_string(ThemeDB.fallback_font, Vector2(24, h * 0.84), "Нажми, чтобы пройти уровень ещё раз", HORIZONTAL_ALIGNMENT_CENTER, w - 48, 19, Color.WHITE)
	else:
		draw_string(ThemeDB.fallback_font, Vector2(24, h * 0.66), result_text, HORIZONTAL_ALIGNMENT_CENTER, w - 48, 32, result_color)
		draw_string(ThemeDB.fallback_font, Vector2(24, h * 0.76), "Попробуй ещё раз", HORIZONTAL_ALIGNMENT_CENTER, w - 48, 24, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(24, h * 0.94), "Собрано: %d/%d" % [_collected_count(), pickup_positions.size()], HORIZONTAL_ALIGNMENT_CENTER, w - 48, 16, Color.WHITE)


func _draw_example_graffiti(rect: Rect2) -> void:
	# Keep the wall frame, but fit the selected example without stretching or cropping it.
	draw_rect(rect, Color("#252a31"))
	if end_graffiti_texture == null:
		return
	var texture_size := Vector2(end_graffiti_texture.get_width(), end_graffiti_texture.get_height())
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return
	var fit_scale := minf(rect.size.x / texture_size.x, rect.size.y / texture_size.y)
	var fitted_size := texture_size * fit_scale
	var fitted_rect := Rect2(rect.position + (rect.size - fitted_size) * 0.5, fitted_size)
	draw_texture_rect(end_graffiti_texture, fitted_rect, false)


func _draw_wildstyle_mural(rect: Rect2, seed_value: int, fully_painted: bool) -> void:
	# Lettering-first mural: the word is the composition. All rendering is local/offline.
	# A seeded variation changes accents and paint details, never the letter skeleton.
	var mural_rng := RandomNumberGenerator.new()
	mural_rng.seed = seed_value ^ 0x57A11E
	var wall := Color("#252a31")
	var mortar := Color("#1b2026")
	draw_rect(rect, wall)
	for row in range(1, 5):
		var y := rect.position.y + rect.size.y * float(row) / 5.0
		draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), mortar, 2.0)
	for col in range(1, 9):
		var x := rect.position.x + rect.size.x * float(col) / 9.0
		draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), Color("#20252b"), 1.0)

	var palettes: Array = [
		[Color("#ff315f"), Color("#ffbd38"), Color("#32e6d0")],
		[Color("#b65cff"), Color("#39d8ff"), Color("#fff04a")],
		[Color("#ff6b35"), Color("#ff3d9a"), Color("#a5ff3d")],
		[Color("#16d9ff"), Color("#f7f7ff"), Color("#ff4d9d")]
	]
	var palette: Array = palettes[mural_rng.randi_range(0, palettes.size() - 1)]
	var fill: Color = palette[0] if fully_painted else palette[0].darkened(0.58)
	var highlight: Color = palette[1] if fully_painted else palette[1].darkened(0.62)
	var accent: Color = palette[2] if fully_painted else palette[2].darkened(0.62)
	var font := ThemeDB.fallback_font
	var word := "PARKOUR"
	var font_size := int(rect.size.y * 0.43)
	var text_width := font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var max_width := rect.size.x * 0.83
	if text_width > max_width:
		font_size = int(float(font_size) * max_width / text_width)
		text_width = font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var origin := Vector2(rect.position.x + (rect.size.x - text_width) * 0.5, rect.position.y + rect.size.y * 0.59)

	# Large, overlapping typography first: deep extrusion, then thick black keyline.
	# A small shear gives the word a forward-driving graffiti lean.
	var shear := -0.13
	var transform_origin := origin
	var shear_matrix := Transform2D(Vector2(1.0, 0.0), Vector2(shear, 1.0), transform_origin)
	draw_set_transform_matrix(shear_matrix)
	for depth in range(8, 0, -1):
		var offset := Vector2(float(depth) * 1.4, float(depth) * 1.2)
		draw_string(font, offset, word, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("#070a10"))
	# Several offsets create a continuous bold outline rather than thin decorative lines.
	for offset in [
		Vector2(-3, 0), Vector2(3, 0), Vector2(0, -3), Vector2(0, 3),
		Vector2(-2, -2), Vector2(2, -2), Vector2(-2, 2), Vector2(2, 2)
	]:
		draw_string(font, offset, word, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("#080b12"))
	draw_string(font, Vector2.ZERO, word, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, fill)
	draw_string(font, Vector2(0, -2), word, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, fill.lightened(0.12))
	# Hard-edged inline highlight adds a deliberate painted finish without changing glyphs.
	var baseline := Vector2(0, -float(font_size) * 0.17)
	draw_line(baseline + Vector2(5, 0), baseline + Vector2(text_width * 0.76, 0), highlight, maxf(2.0, rect.size.y * 0.012))
	draw_set_transform_matrix(Transform2D.IDENTITY)

	# Angular arrows are attached to the word's outer silhouette, not randomly scattered over it.
	var left := Vector2(rect.position.x + rect.size.x * 0.08, rect.position.y + rect.size.y * 0.48)
	var right := Vector2(rect.end.x - rect.size.x * 0.08, rect.position.y + rect.size.y * 0.42)
	var top := Vector2(rect.position.x + rect.size.x * 0.70, rect.position.y + rect.size.y * 0.20)
	var arrow_width := maxf(3.0, rect.size.y * 0.018)
	var left_arrow := PackedVector2Array([
		left, left + Vector2(rect.size.x * 0.11, -rect.size.y * 0.055),
		left + Vector2(rect.size.x * 0.075, rect.size.y * 0.005),
		left + Vector2(rect.size.x * 0.14, rect.size.y * 0.02)
	])
	draw_polyline(left_arrow, Color("#070a10"), arrow_width + 4.0, true)
	draw_polyline(left_arrow, accent, arrow_width, true)
	var right_arrow := PackedVector2Array([
		right, right + Vector2(-rect.size.x * 0.12, rect.size.y * 0.035),
		right + Vector2(-rect.size.x * 0.075, -rect.size.y * 0.025),
		right + Vector2(-rect.size.x * 0.16, -rect.size.y * 0.01)
	])
	draw_polyline(right_arrow, Color("#070a10"), arrow_width + 4.0, true)
	draw_polyline(right_arrow, accent, arrow_width, true)
	# Small crown-like shards break the top contour while keeping the lettering dominant.
	var crown := PackedVector2Array([
		top, top + Vector2(rect.size.x * 0.045, rect.size.y * 0.055),
		top + Vector2(rect.size.x * 0.085, -rect.size.y * 0.015),
		top + Vector2(rect.size.x * 0.11, rect.size.y * 0.045)
	])
	draw_polyline(crown, Color("#070a10"), arrow_width + 3.0, true)
	draw_polyline(crown, highlight, arrow_width, true)

	# Controlled spray halo and a handful of drips; the text remains clean and readable.
	for i in range(72):
		var angle := mural_rng.randf_range(0.0, TAU)
		var radius := mural_rng.randf_range(rect.size.x * 0.22, rect.size.x * 0.48)
		var center := Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y + rect.size.y * 0.49)
		var point := center + Vector2(cos(angle) * radius, sin(angle) * radius * 0.48)
		if rect.has_point(point):
			draw_circle(point, mural_rng.randf_range(0.7, 2.0), Color(fill.r, fill.g, fill.b, mural_rng.randf_range(0.12, 0.38)))
	for i in range(5):
		var drip_x := origin.x + text_width * mural_rng.randf_range(0.12, 0.88)
		var drip_y := origin.y + mural_rng.randf_range(4.0, 12.0)
		var drip_length := mural_rng.randf_range(5.0, 15.0)
		draw_line(Vector2(drip_x, drip_y), Vector2(drip_x, drip_y + drip_length), Color("#080b12"), 4.0)
		draw_line(Vector2(drip_x, drip_y), Vector2(drip_x, drip_y + drip_length), fill, 2.0)
