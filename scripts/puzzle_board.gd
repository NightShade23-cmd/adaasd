class_name MemoryPuzzleBoard
extends Control

signal moved(count: int)
signal solved

var dimension: int = 3
var tiles: Array[int] = []
var blank: int = 8
var selected: int = -1
var moves: int = 0
var front: Texture2D
var back: Texture2D
var accent: Color = Color("c6df99")
var numbers: bool = false
var blocked: bool = false
var complete: bool = false
var moving_id: int = -1
var moving_from: Vector2 = Vector2.ZERO
var moving_to: Vector2 = Vector2.ZERO
var progress: float = 1.0
var font: Font = ThemeDB.fallback_font

func setup(n: int, a: Texture2D, b: Texture2D, color: Color, depth: int) -> void:
	dimension = n
	front = a
	back = b
	accent = color
	blank = n * n - 1
	tiles.clear()
	for i: int in range(n * n):
		tiles.append(i)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	if depth == 10:
		rng.seed = 173
	else:
		rng.randomize()
	var previous: int = -1
	for step: int in range(depth):
		var options: Array[int] = neighbors(blank)
		options.erase(previous)
		var next: int = options[rng.randi_range(0, options.size() - 1)]
		previous = blank
		tiles[blank] = tiles[next]
		tiles[next] = n * n - 1
		blank = next
	if is_solved():
		var next: int = neighbors(blank)[0]
		tiles[blank] = tiles[next]
		tiles[next] = n * n - 1
		blank = next
	queue_redraw()

@warning_ignore("integer_division")
func neighbors(index: int) -> Array[int]:
	var result: Array[int] = []
	for i: int in range(dimension * dimension):
		if absi(i % dimension - index % dimension) + absi(floori(i / float(dimension)) - floori(index / float(dimension))) == 1:
			result.append(i)
	return result

func is_solved() -> bool:
	for i: int in range(tiles.size()):
		if tiles[i] != i:
			return false
	return true

func cell_position(index: int) -> Vector2:
	return Vector2(index % dimension, floori(index / float(dimension))) * (size.x / dimension)

func _gui_input(event: InputEvent) -> void:
	if blocked or complete or progress < 1.0:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse: Vector2 = event.position
		var index: int = int(mouse.y / (size.x / dimension)) * dimension + int(mouse.x / (size.x / dimension))
		if index < 0 or index >= tiles.size() or index == blank:
			return
		if selected == tiles[index] and neighbors(blank).has(index):
			slide(index)
		else:
			selected = tiles[index]
			queue_redraw()
		accept_event()

func slide(index: int) -> void:
	if blocked or complete or progress < 1.0 or not neighbors(blank).has(index):
		return
	selected = tiles[index]
	moving_id = selected
	moving_from = cell_position(index)
	moving_to = cell_position(blank)
	tiles[blank] = tiles[index]
	tiles[index] = dimension * dimension - 1
	blank = index
	moves += 1
	progress = 0.0
	moved.emit(moves)
	var tween: Tween = create_tween()
	tween.tween_property(self, "progress", 1.0, 0.17).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_finish_slide)

func _finish_slide() -> void:
	moving_id = -1
	if is_solved():
		complete = true
		solved.emit()
	queue_redraw()

func _process(_delta: float) -> void:
	if progress < 1.0:
		queue_redraw()

func _draw() -> void:
	if front == null:
		return
	draw_rect(Rect2(Vector2(-10, -10), size + Vector2(20, 20)), Color("090f15"))
	draw_rect(Rect2(Vector2(-10, -10), size + Vector2(20, 20)), accent.darkened(0.45), false, 2)
	var width: float = size.x / dimension
	for i: int in range(tiles.size()):
		var id: int = tiles[i]
		if id == dimension * dimension - 1 and not complete:
			draw_rect(Rect2(cell_position(i) + Vector2(3, 3), Vector2.ONE * (width - 6)), Color(0.015, 0.025, 0.04, 0.85))
			continue
		var pos: Vector2 = cell_position(i)
		if id == moving_id:
			pos = moving_from.lerp(moving_to, progress)
		var rect: Rect2 = Rect2(pos + Vector2(3, 3), Vector2.ONE * (width - 6))
		var active: bool = id == selected or complete
		draw_rect(rect, Color("18252c"))
		var source: Rect2 = Rect2(Vector2(id % dimension, floori(id / float(dimension))) * (front.get_width() / float(dimension)), Vector2.ONE * (front.get_width() / float(dimension)))
		var inset: float = 0.0 if active else width * 0.10
		draw_texture_rect_region(front if active else back, rect.grow(-inset), source)
		draw_rect(rect, accent if active else accent.darkened(0.65), false, 2.0)
		if numbers and not complete:
			draw_rect(Rect2(pos + Vector2(7, 7), Vector2(29, 25)), Color(0.02, 0.04, 0.06, 0.85))
			draw_string(font, pos + Vector2(12, 26), str(id + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("fff0ce"))
