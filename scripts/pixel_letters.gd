class_name KnightPixelLetters
extends RefCounted

# Original 5x7 bitmap alphabet. No system-font or network dependency.
const GLYPHS = {
"A":[14,17,17,31,17,17,17], "B":[30,17,17,30,17,17,30],
"C":[14,17,16,16,16,17,14], "D":[30,17,17,17,17,17,30],
"E":[31,16,16,30,16,16,31], "F":[31,16,16,30,16,16,16],
"G":[14,17,16,23,17,17,15], "H":[17,17,17,31,17,17,17],
"I":[14,4,4,4,4,4,14], "J":[7,2,2,2,18,18,12],
"K":[17,18,20,24,20,18,17], "L":[16,16,16,16,16,16,31],
"M":[17,27,21,21,17,17,17], "N":[17,25,21,19,17,17,17],
"O":[14,17,17,17,17,17,14], "P":[30,17,17,30,16,16,16],
"Q":[14,17,17,17,21,18,13], "R":[30,17,17,30,20,18,17],
"S":[15,16,16,14,1,1,30], "T":[31,4,4,4,4,4,4],
"U":[17,17,17,17,17,17,14], "V":[17,17,17,17,17,10,4],
"W":[17,17,17,21,21,21,10], "X":[17,17,10,4,10,17,17],
"Y":[17,17,10,4,4,4,4], "Z":[31,1,2,4,8,16,31],
"0":[14,17,19,21,25,17,14], "1":[4,12,4,4,4,4,14],
"2":[14,17,1,2,4,8,31], "3":[30,1,1,14,1,1,30],
"4":[2,6,10,18,31,2,2], "5":[31,16,16,30,1,1,30],
"6":[14,16,16,30,17,17,14], "7":[31,1,2,4,8,8,8],
"8":[14,17,17,14,17,17,14], "9":[14,17,17,15,1,1,14],
".":[0,0,0,0,0,12,12], ",":[0,0,0,0,4,4,8],
":":[0,12,12,0,12,12,0], ";":[0,12,12,0,4,4,8],
"!":[4,4,4,4,4,0,4], "?":[14,17,1,2,4,0,4],
"'":[4,4,8,0,0,0,0],
"-":[0,0,0,31,0,0,0],
"/":[1,2,2,4,8,8,16], "(":[2,4,8,8,8,4,2],
")":[8,4,2,2,2,4,8], "[":[14,8,8,8,8,8,14],
"]":[14,2,2,2,2,2,14], "+":[0,4,4,31,4,4,0],
"=":[0,0,31,0,31,0,0], ">":[16,8,4,2,4,8,16],
"<":[1,2,4,8,4,2,1], "&":[12,18,20,8,21,18,13],
"%":[25,25,2,4,8,19,19], "_":[0,0,0,0,0,0,31],
"\"":[10,10,0,0,0,0,0], " ":[0,0,0,0,0,0,0]
}

static func build() -> FontFile:
	var image: Image = Image.create(128, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var font: FontFile = FontFile.new()
	font.font_name = "Wandering Runes"
	font.fixed_size = 8
	font.fixed_size_scale_mode = TextServer.FIXED_SIZE_SCALE_INTEGER_ONLY
	font.allow_system_fallback = false
	font.set_cache_ascent(0, 8, 7)
	font.set_cache_descent(0, 8, 1)
	for code: int in range(32, 127):
		var letter: String = String.chr(code).to_upper()
		var rows: Array = GLYPHS.get(letter, GLYPHS["?"])
		var origin: Vector2i = Vector2i((code - 32) % 16 * 8, floori((code - 32) / 16.0) * 8)
		for y: int in range(7):
			for x: int in range(5):
				if (int(rows[y]) & (1 << (4 - x))) != 0:
					image.set_pixel(origin.x + x, origin.y + y, Color.WHITE)
		font.set_glyph_advance(0, 8, code, Vector2(6, 0))
		font.set_glyph_offset(0, Vector2i(8, 0), code, Vector2(0, -7))
		font.set_glyph_size(0, Vector2i(8, 0), code, Vector2(5, 7))
		font.set_glyph_uv_rect(0, Vector2i(8, 0), code, Rect2(origin, Vector2(5, 7)))
		font.set_glyph_texture_idx(0, Vector2i(8, 0), code, 0)
	font.set_texture_image(0, Vector2i(8, 0), 0, image)
	return font
