class_name PuzzleLogicTests
extends Node

const Board = preload("res://scripts/puzzle_board.gd")

func test_scrambles_preserve_tiles() -> void:
	for n: int in [3, 4, 5, 6]:
		var board: MemoryPuzzleBoard = Board.new()
		board.setup(n, null, null, Color.WHITE, 180)
		assert(board.tiles.size() == n * n)
		assert(board.tiles[board.blank] == n * n - 1)
		assert(not board.is_solved())
		var sorted: Array[int] = board.tiles.duplicate()
		sorted.sort()
		for i: int in range(n * n):
			assert(sorted[i] == i)
		board.free()

func test_no_row_wrap_neighbors() -> void:
	var board: MemoryPuzzleBoard = Board.new()
	board.dimension = 3
	assert(not board.neighbors(2).has(3))
	assert(board.neighbors(0) == [1, 3])
	assert(board.neighbors(4).size() == 4)
	board.free()

func test_scramble_solvable_parity() -> void:
	for n: int in [3, 4, 5, 6]:
		for trial: int in range(20):
			var board: MemoryPuzzleBoard = Board.new()
			board.setup(n, null, null, Color.WHITE, 100)
			var inversions: int = 0
			for i: int in range(board.tiles.size()):
				for j: int in range(i + 1, board.tiles.size()):
					if board.tiles[i] != n * n - 1 and board.tiles[j] != n * n - 1 and board.tiles[i] > board.tiles[j]:
						inversions += 1
			if n % 2 == 1:
				assert(inversions % 2 == 0)
			else:
				var row_from_bottom: int = n - board.blank / n
				assert((inversions + row_from_bottom) % 2 == 1)
			board.free()
