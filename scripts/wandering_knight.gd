class_name WanderingKnightGame
extends Control

const Board = preload("res://scripts/puzzle_board.gd")
const NAMES = ["Easy", "Medium", "Hard", "HellDrive"]
const KEYS = ["easy", "medium", "hard", "hell"]
const CHAPTERS = ["The verdant oath", "Where moonlight sleeps", "Eyes beneath the earth", "The last ember"]
const DESCRIPTIONS = ["Beneath a canopy of green,\nevery journey begins with wonder.", "The old forest dreams.\nRemember what the moon reveals.", "Some things in the darkness\nare better left undisturbed.", "Beyond the fire, a secret stirs.\nOnly the relentless may enter."]
const COLORS = [Color("b9d58a"), Color("b4b8fa"), Color("72d5d1"), Color("f6a267")]
const GRIDS = [3, 4, 5, 6]
const DEPTHS = [10, 60, 140, 280]
const FRONT_CAPTIONS = ["A knight beneath the canopy", "A traveler at rest", "A torch against the dark", "Before the obsidian guardian"]
const BACK_CAPTIONS = ["Two lives among the leaves", "The forest shares his dreams", "Something is watching", "A new fire awakens"]

var background: TextureRect
var content: Control
var overlay: Control
var board: MemoryPuzzleBoard
var timer_label: Label
var move_label: Label
var menu_chapter: Label
var menu_description: Label
var menu_tag: Label
var knight: TextureRect
var music: AudioStreamPlayer
var effects: AudioStreamPlayer
var ambience: AudioStreamPlayer
var music_tracks: Array[AudioStreamWAV] = []
var ambient_tracks: Array[AudioStreamWAV] = []
var backgrounds: Array[Texture2D] = []
var fronts: Array[Texture2D] = []
var backs: Array[Texture2D] = []
var level: int = 0
var preview_level: int = 0
var unlocked: int = 0
var elapsed: float = 0.0
var running: bool = false
var paused: bool = false
var in_game: bool = false
var assisted: bool = false
var music_volume: float = 0.45
var sound_volume: float = 0.65
var bests: Dictionary = {}
var clock: float = 0.0
var body_font: Font
var title_font: Font
var slide_sound: AudioStreamWAV
var win_sound: AudioStreamWAV

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	body_font = preload("res://scripts/pixel_letters.gd").build()
	title_font = body_font
	var pixel_theme: Theme = Theme.new()
	pixel_theme.default_font = body_font
	pixel_theme.default_font_size = 16
	theme = pixel_theme
	load_save()
	for key: String in KEYS:
		backgrounds.append(load_art("menu_" + key))
		fronts.append(load_art(key + "_front"))
		backs.append(load_art(key + "_back"))
	background = TextureRect.new()
	background.size = Vector2(1280, 720)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var shade: ColorRect = ColorRect.new()
	shade.color = Color(0.015, 0.03, 0.05, 0.30)
	shade.size = Vector2(1280, 720)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	content = Control.new()
	add_child(content)
	music = AudioStreamPlayer.new()
	effects = AudioStreamPlayer.new()
	ambience = AudioStreamPlayer.new()
	add_child(music)
	add_child(effects)
	add_child(ambience)
	for i: int in range(4):
		music_tracks.append(load("res://assets/audio/chapter_%d.res" % i))
		ambient_tracks.append(make_audio(i + 4, 6.4, true))
	slide_sound = make_audio(8, 0.12, false)
	win_sound = make_audio(9, 1.3, false)
	show_menu()

func load_art(key: String) -> Texture2D:
	var base: String = "res://assets/generated/" + key
	if ResourceLoader.exists(base + ".res"):
		return load(base + ".res")
	return load(base + ".png")

func load_save() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load("user://wandering_knight.cfg") == OK:
		unlocked = clampi(int(config.get_value("journey", "unlocked", 0)), 0, 3)
		bests = config.get_value("journey", "bests", {})
		music_volume = float(config.get_value("audio", "music", 0.45))
		sound_volume = float(config.get_value("audio", "sound", 0.65))

func save() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("journey", "unlocked", unlocked)
	config.set_value("journey", "bests", bests)
	config.set_value("audio", "music", music_volume)
	config.set_value("audio", "sound", sound_volume)
	config.save("user://wandering_knight.cfg")

func make_audio(kind: int, duration: float, loop: bool) -> AudioStreamWAV:
	var rate: int = 16000
	var count: int = int(rate * duration)
	var data: PackedByteArray = PackedByteArray()
	data.resize(count * 2)
	var scales: Array = [[0, 7, 12, 4, 7, 16, 12, 7], [0, 7, 10, 3, 7, 15, 10, 7], [0, 1, 7, 3, 0, 8, 7, 1], [0, 3, 7, 1, 0, 6, 7, 10]]
	for i: int in range(count):
		var t: float = i / float(rate)
		var value: float = 0.0
		if kind < 4:
			var step: int = int(t / 0.4) % 8
			var note: float = 174.61 * pow(2.0, float(scales[kind][step]) / 12.0)
			var env: float = exp(-fmod(t, 0.4) * 7.0)
			value = (sin(TAU * note * t) + 0.23 * sin(TAU * note * 2.0 * t)) * env * 0.15
			value += sin(TAU * 87.305 * pow(2.0, kind / 12.0) * t) * 0.045 * sin(PI * t / duration)
		elif kind < 8:
			value = randf_range(-0.025, 0.025) + sin(t * TAU * (55.0 if kind >= 6 else 110.0)) * 0.03
			value *= 0.55 + 0.45 * sin(TAU * t / duration)
		elif kind == 8:
			value = sin(TAU * (500.0 * t - 900.0 * t * t)) * exp(-t * 35.0) * 0.4
		else:
			var note: float = [261.63, 329.63, 392.0, 523.25][mini(int(t / 0.23), 3)]
			value = sin(TAU * note * t) * exp(-fmod(t, 0.23) * 6.0) * 0.2 * (1.0 - t / duration)
		data.encode_s16(i * 2, int(clampf(value, -1, 1) * 32767))
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = data
	if loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = count
	return stream

func update_audio(index: int) -> void:
	if music.stream != music_tracks[index]:
		music.stream = music_tracks[index]
		music.play()
		ambience.stream = ambient_tracks[index]
		ambience.play()
	music.volume_db = linear_to_db(maxf(music_volume, 0.0001))
	ambience.volume_db = linear_to_db(maxf(sound_volume * 0.6, 0.0001))
	effects.volume_db = linear_to_db(maxf(sound_volume, 0.0001))

func clear_content() -> void:
	for child: Node in content.get_children():
		content.remove_child(child)
		child.queue_free()
	knight = null
	board = null
	timer_label = null
	move_label = null

func label_at(parent: Node, text: String, x: float, y: float, width: float, font_size: int = 18, color: Color = Color("e4e7d7"), heading: bool = false) -> Label:
	var node: Label = Label.new()
	node.text = text
	node.position = Vector2(x, y)
	node.size.x = width
	node.add_theme_font_override("font", title_font if heading else body_font)
	var pixel_size: int = maxi(8, roundi(font_size / 8.0) * 8)
	var longest: float = 0.0
	for line: String in text.split("\n"):
		longest = maxf(longest, body_font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, pixel_size).x)
	while longest > width and pixel_size > 8:
		longest *= (pixel_size - 8.0) / pixel_size
		pixel_size -= 8
	node.add_theme_font_size_override("font_size", pixel_size)
	node.add_theme_color_override("font_color", color)
	node.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	node.add_theme_constant_override("shadow_offset_y", 2)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node

func style(color: Color, fill: Color) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = color
	box.set_border_width_all(1)
	box.border_width_left = 3
	box.content_margin_left = 18
	box.content_margin_right = 18
	return box

func button_skin(index: int, tint: Color) -> StyleBoxTexture:
	var box: StyleBoxTexture = StyleBoxTexture.new()
	box.texture = load_art("chapter_buttons_v2")
	box.region_rect = Rect2(80, index * 64, 352, 64)
	box.texture_margin_left = 48
	box.texture_margin_right = 48
	box.texture_margin_top = 12
	box.texture_margin_bottom = 12
	box.content_margin_left = 52
	box.content_margin_right = 20
	box.modulate_color = tint
	return box

func skin_button(node: Button, index: int) -> void:
	node.add_theme_stylebox_override("normal", button_skin(index, Color.WHITE))
	node.add_theme_stylebox_override("hover", button_skin(index, Color(1.3, 1.3, 1.3)))
	node.add_theme_stylebox_override("pressed", button_skin(index, Color(0.75, 0.75, 0.75)))
	node.add_theme_stylebox_override("focus", button_skin(index, Color(1.15, 1.15, 1.15)))
	node.add_theme_color_override("font_hover_color", COLORS[index].lightened(0.3))

func icon_texture(index: int) -> AtlasTexture:
	var atlas: AtlasTexture = AtlasTexture.new()
	atlas.atlas = load_art("chapter_icons_v2")
	atlas.region = Rect2(54 + index * 50, 0, 50, 64)
	return atlas

func button_at(parent: Node, text: String, rect: Rect2, callback: Callable, color: Color = Color("bed995")) -> Button:
	var node: Button = Button.new()
	node.text = text
	node.position = rect.position
	node.size = rect.size
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	node.add_theme_font_override("font", body_font)
	node.add_theme_font_size_override("font_size", 16)
	node.add_theme_color_override("font_color", Color("f8efce"))
	node.add_theme_color_override("font_shadow_color", Color.BLACK)
	node.add_theme_constant_override("shadow_offset_y", 2)
	var index: int = COLORS.find(color)
	node.set_meta("adaptive_skin", index < 0)
	if index < 0:
		index = level if in_game else preview_level
	skin_button(node, index)
	var icon_index: int = index
	if text.contains("LOCKED"):
		icon_index = 4
	elif text.contains("Settings"):
		icon_index = 5
	elif text.contains("How"):
		icon_index = 6
	elif text.contains("Pause"):
		icon_index = 7
	image_at(node, icon_texture(icon_index), Rect2(18, (rect.size.y - 32) / 2.0, 26, 32))
	node.pressed.connect(callback)
	parent.add_child(node)
	return node

func panel(parent: Node, rect: Rect2, color: Color) -> Panel:
	var node: Panel = Panel.new()
	node.position = rect.position
	node.size = rect.size
	node.add_theme_stylebox_override("panel", style(color.darkened(0.45), Color(0.025, 0.045, 0.06, 0.96)))
	parent.add_child(node)
	return node

func image_at(parent: Node, texture: Texture2D, rect: Rect2) -> TextureRect:
	var image: TextureRect = TextureRect.new()
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.texture = texture
	image.position = rect.position
	image.size = rect.size
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(image)
	return image

func show_menu() -> void:
	close_overlay()
	clear_content()
	in_game = false
	running = false
	paused = false
	panel(content, Rect2(36, 34, 530, 646), COLORS[0])
	label_at(content, "A DUAL-SIDED MEMORY PUZZLE", 68, 60, 450, 14, Color("b9d58a"))
	var animated_title: Control = Control.new()
	animated_title.name = "AnimatedTitle"
	animated_title.position = Vector2(66, 100)
	animated_title.size = Vector2(478, 64)
	animated_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(animated_title)
	# Layered bitmap lettering adds bold weight and a deep pixel shadow.
	label_at(animated_title, "Flip-A-Slide", 5, 6, 470, 48, Color("18251e"), true)
	label_at(animated_title, "Flip-A-Slide", 2, 0, 470, 48, Color("ffe6a2"), true)
	var title_face: Label = label_at(animated_title, "Flip-A-Slide", 0, 0, 470, 48, Color("ffe6a2"), true)
	title_face.name = "TitleFace"
	label_at(content, "Wandering Knight", 68, 180, 460, 24, Color("b9d58a"), true)
	label_at(content, "Two stories. One scattered memory.", 68, 239, 450, 16, Color("aab7ad"))
	label_at(content, "CHOOSE YOUR CHAPTER", 68, 291, 440, 13, Color("b2bdad"))
	for i: int in range(4):
		var lock_text: String = "  >" if i <= unlocked else "  [LOCKED]"
		var text: String = "%02d   %s%s" % [i + 1, NAMES[i], lock_text]
		var b: Button = button_at(content, text, Rect2(68, 322 + i * 64, 466, 54), choose_level.bind(i), COLORS[i])
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.mouse_entered.connect(preview_theme.bind(i))
		b.focus_entered.connect(preview_theme.bind(i))
	button_at(content, "Settings", Rect2(68, 598, 222, 44), show_settings)
	button_at(content, "How to play", Rect2(302, 598, 232, 44), show_help)
	knight = image_at(content, load_art("knight"), Rect2(856, 211, 288, 432))
	menu_tag = label_at(content, "", 635, 93, 580, 14, COLORS[0])
	menu_chapter = label_at(content, "", 635, 120, 600, 34, Color("fff1d7"), true)
	menu_description = label_at(content, "", 638, 170, 550, 16)
	label_at(content, "HOVER TO EXPLORE  /  COMPLETE TO UNLOCK", 635, 660, 610, 13, Color("e0e7d5"))
	preview_theme(mini(level, unlocked))

func preview_theme(index: int) -> void:
	preview_level = index
	background.texture = backgrounds[index]
	menu_tag.text = "CHAPTER %02d  /  %s  /  %d x %d" % [index + 1, NAMES[index].to_upper(), GRIDS[index], GRIDS[index]]
	menu_tag.modulate = COLORS[index]
	menu_chapter.text = CHAPTERS[index]
	menu_description.text = DESCRIPTIONS[index]
	for child: Node in content.get_children():
		if child is Button and child.get_meta("adaptive_skin", false):
			skin_button(child, index)
	update_audio(index)

func choose_level(index: int) -> void:
	if index > unlocked:
		show_message("The path is sealed", "Complete " + NAMES[index - 1] + " to unlock this chapter.")
		return
	level = index
	start_level()

func start_level() -> void:
	close_overlay()
	clear_content()
	in_game = true
	running = false
	paused = false
	assisted = false
	elapsed = 0.0
	background.texture = backgrounds[level]
	update_audio(level)
	panel(content, Rect2(24, 22, 1232, 66), COLORS[level])
	button_at(content, "Pause", Rect2(38, 34, 150, 42), show_settings, COLORS[level])
	label_at(content, NAMES[level].to_upper() + "  /  " + CHAPTERS[level], 220, 42, 720, 20, COLORS[level])
	timer_label = label_at(content, "00:00.0", 1070, 36, 170, 30)
	panel(content, Rect2(32, 116, 340, 566), COLORS[level])
	label_at(content, "CHAPTER %02d" % (level + 1), 58, 140, 280, 14, COLORS[level])
	label_at(content, "Remember\nboth worlds.", 56, 172, 300, 36, Color("f3ead2"), true)
	label_at(content, "1. Click to reveal.\n\n2. Click again beside\n   the gap to slide.\n\nOnly the selected tile\nshows the knight.\nSmaller backs form\nthe hidden story.", 58, 278, 295, 16)
	move_label = label_at(content, "MOVES  000", 58, 494, 280, 22, COLORS[level])
	var hints: Button = button_at(content, "Numbers: OFF", Rect2(56, 550, 290, 48), func() -> void: pass, COLORS[level])
	hints.toggle_mode = true
	hints.toggled.connect(func(enabled: bool) -> void:
		toggle_numbers(enabled)
		hints.text = "Numbers: ON" if enabled else "Numbers: OFF"
	)
	label_at(content, "NO PREVIEWS.\nFULL IMAGES ARE REVEALED\nONLY AFTER COMPLETION.", 58, 616, 290, 12, COLORS[level])
	board = Board.new()
	board.name = "PuzzleBoard"
	board.position = Vector2(526, 132)
	board.size = Vector2(512, 512)
	board.font = body_font
	content.add_child(board)
	board.setup(GRIDS[level], fronts[level], backs[level], COLORS[level], DEPTHS[level])
	board.blocked = true
	board.moved.connect(on_move)
	board.solved.connect(on_solved)
	label_at(content, "SELECT  >  REMEMBER  >  SLIDE", 526, 671, 610, 14, COLORS[level])
	begin_run()

func toggle_numbers(enabled: bool) -> void:
	if is_instance_valid(board):
		board.numbers = enabled
		board.queue_redraw()
		if enabled:
			assisted = true

func on_move(count: int) -> void:
	move_label.text = "MOVES  %03d" % count
	effects.stream = slide_sound
	effects.play()

func format_time(value: float) -> String:
	return "%02d:%04.1f" % [floori(value / 60.0), fmod(value, 60.0)]

func _process(delta: float) -> void:
	clock += delta
	if is_instance_valid(knight):
		knight.position.y = 211.0 + sin(clock * 1.5) * 3.0
	if not in_game:
		var animated_title: Control = content.get_node_or_null("AnimatedTitle") as Control
		if animated_title != null:
			# Whole-pixel motion keeps the bitmap letters crisp.
			animated_title.position.y = 100.0 + roundf(sin(clock * 1.7) * 3.0)
			var face: Label = animated_title.get_node("TitleFace") as Label
			face.modulate = Color.WHITE.lerp(Color("fff3cf"), (sin(clock * 1.1) + 1.0) * 0.25)
	if running and not paused:
		elapsed += delta
		if is_instance_valid(timer_label):
			timer_label.text = format_time(elapsed)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if is_instance_valid(overlay):
			if overlay.get_meta("dismissible", true):
				resume()
		elif in_game:
			show_settings()

func new_overlay(dismissible: bool = true) -> Control:
	close_overlay()
	overlay = Control.new()
	overlay.name = "Modal"
	overlay.set_meta("dismissible", dismissible)
	overlay.size = Vector2(1280, 720)
	add_child(overlay)
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.005, 0.012, 0.025, 0.86)
	dim.size = Vector2(1280, 720)
	overlay.add_child(dim)
	return overlay

func close_overlay() -> void:
	if is_instance_valid(overlay):
		remove_child(overlay)
		overlay.queue_free()
	overlay = null

func begin_run() -> void:
	close_overlay()
	paused = false
	running = true
	board.blocked = false

func show_settings() -> void:
	paused = true
	if is_instance_valid(board):
		board.blocked = true
	var modal: Control = new_overlay()
	panel(modal, Rect2(390, 116, 500, 490), COLORS[preview_level if not in_game else level])
	label_at(modal, "Rest a moment" if in_game else "Settings", 430, 146, 440, 38, Color("f6efd7"), true)
	label_at(modal, "The timer is paused." if in_game else "Make the journey your own.", 432, 202, 430, 16, Color("aabbb3"))
	label_at(modal, "Music volume", 432, 252, 410, 17)
	add_slider(modal, Vector2(432, 286), music_volume, true)
	label_at(modal, "Ambient sound & effects", 432, 338, 410, 17)
	add_slider(modal, Vector2(432, 372), sound_volume, false)
	button_at(modal, "Resume journey" if in_game else "Back", Rect2(430, 436, 420, 46), resume)
	if in_game:
		button_at(modal, "Restart", Rect2(430, 506, 196, 46), start_level)
		button_at(modal, "Main menu", Rect2(646, 506, 204, 46), show_menu)

func add_slider(parent: Node, pos: Vector2, initial: float, is_music: bool) -> void:
	var slider: HSlider = HSlider.new()
	slider.position = pos
	slider.size = Vector2(416, 28)
	slider.min_value = 0
	slider.max_value = 1
	slider.step = 0.01
	slider.value = initial
	slider.value_changed.connect(func(value: float) -> void:
		if is_music:
			music_volume = value
		else:
			sound_volume = value
		update_audio(level if in_game else preview_level)
		save()
	)
	parent.add_child(slider)

func resume() -> void:
	close_overlay()
	paused = false
	if is_instance_valid(board):
		board.blocked = false
	save()

func show_help() -> void:
	show_message("One tile. Two memories.", "Discover the images one fragment at a time.\n\nClick any tile to reveal its front. Other tiles\nshow smaller fragments of the hidden story.\n\nClick the selected tile again to slide it into\nan adjacent gap. Both faces move together.\n\nRestore the layout with the gap at bottom right.\nThe full images appear ONLY after completion.\n\nGrids: 3x3 / 4x4 / 5x5 / 6x6.\nOptional numbers mark your run as assisted.")

func show_message(title: String, text: String) -> void:
	var modal: Control = new_overlay()
	panel(modal, Rect2(300, 100, 680, 520), COLORS[preview_level])
	label_at(modal, title, 338, 132, 620, 32, Color("f5ecd3"), true)
	label_at(modal, text, 340, 198, 620, 16)
	button_at(modal, "Back to the journey", Rect2(450, 550, 380, 44), resume)

func on_solved() -> void:
	running = false
	unlocked = maxi(unlocked, mini(level + 1, 3))
	var key: String = str(level) + ("_assisted" if assisted else "_pure")
	var record: bool = elapsed < float(bests.get(key, 1.0e12))
	if record:
		bests[key] = elapsed
	save()
	effects.stream = win_sound
	effects.play()
	var modal: Control = new_overlay(false)
	var card: Panel = panel(modal, Rect2(270, 102, 740, 530), COLORS[level])
	card.pivot_offset = card.size / 2.0
	card.scale = Vector2(0.86, 0.86)
	card.modulate.a = 0.0
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(card, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "modulate:a", 1.0, 0.35)
	label_at(card, "MEMORY RESTORED", 40, 28, 650, 14, COLORS[level])
	label_at(card, "Puzzle Solved", 38, 60, 660, 46, Color("fff1d5"), true)
	image_at(card, fronts[level], Rect2(42, 133, 190, 190))
	image_at(card, backs[level], Rect2(250, 133, 190, 190))
	label_at(card, format_time(elapsed), 472, 148, 240, 32, COLORS[level])
	label_at(card, "%d moves\n%s\n\n%s" % [board.moves, "Assisted journey" if assisted else "Pure memory", "PERSONAL BEST" if record else "Best: " + format_time(float(bests[key]))], 472, 202, 245, 15)
	label_at(card, "The next path is open: " + NAMES[level + 1] if level < 3 else "All four memories restored. The legend is yours.", 42, 356, 680, 18, COLORS[level])
	button_at(card, "Next chapter" if level < 3 else "Journey complete", Rect2(40, 418, 320, 52), next_level, COLORS[level])
	button_at(card, "Main menu", Rect2(380, 418, 320, 52), show_menu, COLORS[level])

func next_level() -> void:
	if level < 3:
		level += 1
		start_level()
	else:
		show_menu()
