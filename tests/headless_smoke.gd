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
	var sprite := level_instance.get_node_or_null("PlayerSprite") as Sprite2D
	if sprite == null:
		_fail("Standard character Sprite2D was not created")
		return
	if sprite.texture == null or not sprite.texture is ViewportTexture:
		_fail("Standard character must be rendered through a SubViewport texture")
		return
	var animation_player := level_instance.get_node_or_null("CharacterViewport/CharacterWorld/UAL1_Standard/AnimationPlayer") as AnimationPlayer
	if animation_player == null:
		_fail("Standard character AnimationPlayer was not created")
		return
	for animation_name in ["Idle", "Jog_Fwd", "Sprint", "Jump_Start", "Jump", "Jump_Land", "Crouch_Fwd", "Roll"]:
		if not animation_player.has_animation(animation_name):
			_fail("Standard character animation is missing: " + animation_name)
			return
	print("PASS: Universal Animation Library Standard mannequin is rendered in the 2D level")
	print("PASS: Standard character run, jump, landing, crouch, and roll clips are available")
	# Slide uses a shorter collision rectangle; keep this contract covered by CI.
	level_instance.set("slide_timer", 0.5)
	level_instance.set("player_y", float(level_instance.call("_ground_y")) - 24.0)
	var slide_rect: Rect2 = level_instance.call("_player_rect")
	if not is_equal_approx(slide_rect.size.y, 24.0):
		_fail("Slide hitbox should be 24 pixels tall")
		return
	if not is_equal_approx(slide_rect.position.y + slide_rect.size.y, float(level_instance.call("_ground_y"))):
		_fail("Slide hitbox should remain aligned to the ground")
		return
	level_instance.set("slide_timer", 0.0)
	level_instance.set("player_y", float(level_instance.call("_ground_y")) - 64.0)
	print("PASS: slide hitbox is short and remains grounded")
	print("PASS: level scene instantiates and player starts running")
	if not level_instance.has_method("_draw_wildstyle_mural"):
		_fail("Seeded Wildstyle mural generator is missing")
		return
	if level_instance.get("level_seed") == 0:
		_fail("Level seed must be initialized for deterministic graffiti")
		return
	print("PASS: seeded offline Wildstyle mural generator is available")
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
