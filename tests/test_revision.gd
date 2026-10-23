class_name KnightRevisionTests
extends Node

const Game = preload("res://scripts/wandering_knight.gd")
const Letters = preload("res://scripts/pixel_letters.gd")

func test_grid_progression() -> void:
	assert(Game.GRIDS == [3, 4, 5, 6])
	assert(Game.DEPTHS[0] < Game.DEPTHS[1])
	assert(Game.DEPTHS[1] < Game.DEPTHS[2])
	assert(Game.DEPTHS[2] < Game.DEPTHS[3])

func test_no_preview_entry_points() -> void:
	var game: WanderingKnightGame = Game.new()
	assert(not game.has_method("show_memory"))
	assert(not game.has_method("glimpse"))
	game.free()

func test_pixel_font_scales_and_covers_ui() -> void:
	var font: FontFile = Letters.build()
	assert(font.fixed_size == 8)
	assert(not font.allow_system_fallback)
	assert(font.get_string_size("KNIGHT", HORIZONTAL_ALIGNMENT_LEFT, -1, 32).x > font.get_string_size("KNIGHT", HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x)
	for code: int in range(32, 127):
		assert(font.get_glyph_size(0, Vector2i(8, 0), code) == Vector2(5, 7))

func test_four_distinct_music_tracks() -> void:
	var signatures: Array[int] = []
	for i: int in range(4):
		var stream: AudioStreamWAV = load("res://assets/audio/chapter_%d.res" % i)
		assert(stream.get_length() > 10.0)
		assert(stream.loop_mode == AudioStreamWAV.LOOP_FORWARD)
		var signature: int = hash(stream.data)
		assert(not signatures.has(signature))
		signatures.append(signature)
