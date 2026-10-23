	var player_rect := _player_rect()
	draw_rect(player_rect, Color(0.25, 0.72, 1.0))
	draw_circle(Vector2(player_rect.position.x + 22, player_rect.position.y + 10), 4, Color.WHITE)
	draw_rect(Rect2(player_rect.position.x - 3, player_rect.end.y - 4, 40, 5), Color(0.07, 0.1, 0.14))
	if DEBUG_HITBOXES:
		draw_rect(player_rect, Color(0.2, 1.0, 0.45, 0.95), false, 2.0)
	draw_rect(Rect2(18, 18, w - 36, 8), Color(0.16, 0.22, 0.28))
	draw_rect(Rect2(18, 18, (w - 36) * clampf(world_x / LEVEL_LENGTH, 0.0, 1.0), 8), Color(0.12, 0.85, 0.88))
	draw_string(ThemeDB.fallback_font, Vector2(22, 48), "ГРАФФИТИ: %d" % _collected_count(), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
	draw_circle(Vector2(82, h - 68), 48, Color(0.12, 0.48, 0.62, 0.92))
	draw_string(ThemeDB.fallback_font, Vector2(44, h - 61), "ПРЫЖОК", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	draw_circle(Vector2(w - 82, h - 68), 48, Color(0.1, 0.35, 0.48, 0.92))
	draw_string(ThemeDB.fallback_font, Vector2(w - 119, h - 61), "ПОДКАТ", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(w * 0.5 - 112, h - 26), "ПРЫЖОК СЛЕВА • ПОДКАТ СПРАВА", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.85, 0.9, 0.96))
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
	var heading := result_text
	if not painting:
		draw_string(ThemeDB.fallback_font, Vector2(24, h * 0.66), heading, HORIZONTAL_ALIGNMENT_CENTER, w - 48, 32, result_color)
		draw_string(ThemeDB.fallback_font, Vector2(24, h * 0.76), "Попробуй ещё раз", HORIZONTAL_ALIGNMENT_CENTER, w - 48, 24, Color.WHITE)
	else:
		draw_string(ThemeDB.fallback_font, Vector2(24, h * 0.78), heading, HORIZONTAL_ALIGNMENT_CENTER, w - 48, 24, result_color)
	draw_string(ThemeDB.fallback_font, Vector2(24, h * 0.9), "Собрано: %d   •   НАЖМИ, ЧТОБЫ НАЧАТЬ ЗАНОВО" % _collected_count(), HORIZONTAL_ALIGNMENT_CENTER, w - 48, 16, Color.WHITE)	for obstacle in _obstacles():
		var ox: float = float(obstacle["x"]) - world_x + player_x
		if ox > -80 and ox < w + 80:
			if str(obstacle["kind"]) == "jump":
				draw_rect(Rect2(ox - 20, ground - 48, 40, 48), Color(0.9, 0.42, 0.22))
				draw_line(Vector2(ox - 13, ground - 35), Vector2(ox + 13, ground - 35), Color(1.0, 0.8, 0.55), 3.0)
			else:
				draw_rect(Rect2(ox - 28, ground - 90, 56, 12), Color(0.88, 0.32, 0.28))
				draw_rect(Rect2(ox - 28, ground - 90, 8, 64), Color(0.88, 0.32, 0.28))
				draw_rect(Rect2(ox + 20, ground - 90, 8, 64), Color(0.88, 0.32, 0.28))
			if DEBUG_HITBOXES:
				for hitbox in _obstacle_rects(obstacle, ox, ground):
					draw_rect(hitbox, Color(1.0, 0.2, 0.2, 0.9), false, 1.0)

