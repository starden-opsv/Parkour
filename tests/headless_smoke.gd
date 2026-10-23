extends SceneTree

func _initialize() -> void:
	call_deferred("_run_smoke_tests")

func _run_smoke_tests() -> void:
	var main_packed := load("res://main.tscn") as PackedScene
	if main_packed == null:
		_fail("Could not load main.tscn")
		return
	var main_instance := main_packed.instantiate()
	root.add_child(main_instance)
	await process_frame
	if main_instance.get_node_or_null("Content/StartButton") == null:
		_fail("Main menu start button is missing")
		return
	print("PASS: main menu scene instantiates and has a start button")
	main_instance.queue_free()
	await process_frame

	var level_packed := load("res://level_1.tscn") as PackedScene
	if level_packed == null:
		_fail("Could not load level_1.tscn")
		return
	var level_instance := level_packed.instantiate()
	root.add_child(level_instance)
	await process_frame
	var sprite := level_instance.get_node_or_null("PlayerSprite") as AnimatedSprite2D
	if sprite == null:
		_fail("PlayerSprite was not created")
		return
	var expected_frames := {
		"idle": 7,
		"run": 12,
		"jump": 13,
		"running_jump": 7,
		"fall": 9,
		"land": 8,
		"dash": 5,
	}
	for animation_name in expected_frames:
		if not sprite.sprite_frames.has_animation(animation_name):
			_fail("Missing animation: " + animation_name)
			return
		var actual_frames: int = sprite.sprite_frames.get_frame_count(animation_name)
		if actual_frames != expected_frames[animation_name]:
			_fail("Animation %s expected %d frames, got %d" % [animation_name, expected_frames[animation_name], actual_frames])
			return
		print("PASS: animation %s has %d frames" % [animation_name, actual_frames])
	if sprite.animation != "run":
		_fail("Player should start with the run animation")
		return
	print("PASS: level scene instantiates and player starts running")
	if level_instance.get("graffiti_full_texture") == null or level_instance.get("graffiti_partial_texture") == null:
		_fail("Graffiti mural variants did not load")
		return
	print("PASS: both graffiti mural variants load")
	var pickup_states: Array = level_instance.get("collected")
	if pickup_states.size() < 14 or pickup_states.size() > 18:
		_fail("Expected 14-18 procedurally generated graffiti collectibles")
		return
	var generated_length: float = level_instance.get("level_length")
	if generated_length < 4200.0 or generated_length > 5000.0:
		_fail("Generated level length is outside 4200-5000")
		return
	var generated_obstacles: Array = level_instance.get("obstacle_layout")
	if generated_obstacles.size() < 6:
		_fail("Generated level should contain at least 6 obstacles")
		return
	var spray_cans: Array = level_instance.get("spray_can_positions")
	if spray_cans.size() != 2:
		_fail("Expected two rare spray-can shield pickups")
		return
	if not level_instance.has_method("_draw_finish_marker"):
		_fail("Visible finish marker method is missing")
		return
	print("PASS: procedural layout has %d pickups, %d obstacles, %d shields, length %.0f" % [pickup_states.size(), generated_obstacles.size(), spray_cans.size(), generated_length])
	level_instance.call("_register_pickup")
	level_instance.set("combo_timer", 2.0)
	level_instance.call("_register_pickup")
	if level_instance.get("combo_count") != 2 or level_instance.get("run_score") != 300:
		_fail("Pickup streak should award a 2x combo and 300 points")
		return
	level_instance.set("world_x", generated_length * 0.5)
	if level_instance.call("_current_run_speed") <= 230.0:
		_fail("Run speed should increase as the level progresses")
		return
	level_instance.set("world_x", 0.0)
	print("PASS: combo scoring and progressive run speed")
	pickup_states[0] = true
	level_instance.set("collected", pickup_states)
	level_instance.call("_finish_level")
	if level_instance.get("result_text") == "ШЕДЕВР ЗАВЕРШЁН":
		_fail("Incomplete graffiti must not be marked fully painted")
		return
	print("PASS: incomplete graffiti remains unfinished")
	level_instance.queue_free()
	await process_frame
	var complete_instance := level_packed.instantiate()
	root.add_child(complete_instance)
	await process_frame
	var complete_states: Array = complete_instance.get("collected")
	for index in complete_states.size():
		complete_states[index] = true
	complete_instance.set("collected", complete_states)
	complete_instance.call("_finish_level")
	if complete_instance.get("result_text") != "ШЕДЕВР ЗАВЕРШЁН":
		_fail("Collecting every graffiti item must complete the mural")
		return
	print("PASS: collecting every graffiti item completes the mural")
	quit(0)

func _fail(message: String) -> void:
	push_error("SMOKE TEST FAILED: " + message)
	quit(1)
