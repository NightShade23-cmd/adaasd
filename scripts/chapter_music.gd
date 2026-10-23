class_name KnightChapterMusic
extends RefCounted

const TITLES = ["Meadow Minuet", "Moonroot Lullaby", "Below the Bones", "Obsidian Heartbeat"]
const STEPS = [0.25, 0.50, 0.625, 0.20]
const ROOTS = [60, 57, 45, 38]
const MELODIES = [
	[0,4,7,12,7,4,2,5,9,12,9,5,4,7,11,14,12,7,4,2,0,4,7,4,5,9,12,9,7,4,2,0],
	[12,-1,7,-1,3,-1,10,-1,14,-1,10,7,3,-1,7,-1,12,-1,15,-1,10,-1,7,-1,3,-1,2,-1,7,-1,0,-1],
	[0,-1,-1,-1,1,-1,-1,-1,7,-1,6,-1,1,-1,-1,-1,0,-1,3,-1,-1,-1,1,-1,6,-1,-1,-1,1,-1,-1,-1],
	[0,0,12,0,3,0,7,6,0,0,12,0,10,7,6,3,0,0,12,15,7,6,3,0,1,1,13,1,7,6,3,1]
]

static func compose(index: int) -> AudioStreamWAV:
	var rate: int = 16000
	var step: float = STEPS[index]
	var duration: float = step * 64.0
	var count: int = int(duration * rate)
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(count * 2)
	for i: int in range(count):
		var t: float = i / float(rate)
		var beat: int = int(t / step)
		var local: float = fmod(t, step)
		var pitch: int = MELODIES[index][beat % 32]
		var note: float = 440.0 * pow(2.0, (ROOTS[index] + pitch - 69) / 12.0)
		var root: float = 440.0 * pow(2.0, (ROOTS[index] - 81) / 12.0)
		var value: float = 0.0
		if index == 0:
			# Bright plucked lute with a dancing bass line.
			value = (sin(TAU * note * local) + 0.35 * sin(TAU * note * 2.0 * local)) * exp(-local * 14.0) * 0.20
			value += sin(TAU * root * (1.5 if beat % 4 == 2 else 1.0) * local) * exp(-local * 10.0) * 0.09
		elif index == 1:
			# Slow, shimmering bells over soft minor chords; deliberate rests.
			if pitch >= 0:
				value = (sin(TAU * note * local) + sin(TAU * note * 2.01 * local) * 0.25) * exp(-local * 5.0) * 0.18
			var swell: float = 0.5 - 0.5 * cos(TAU * t / duration)
			value += (sin(TAU * root * t) + sin(TAU * root * 1.189207 * t)) * swell * 0.035
		elif index == 2:
			# Unsettling low drones, isolated mallet notes and cave pulses.
			if pitch >= 0:
				value = sin(TAU * note * local) * exp(-local * 12.0) * 0.13
			value += (sin(TAU * root * t) + 0.5 * sin(TAU * root * 1.059463 * t)) * 0.06 * (0.6 + 0.4 * sin(TAU * t / duration))
			value += sin(TAU * 39.0 * local) * exp(-local * 22.0) * 0.05
		else:
			# Fast dark ostinato, distorted bass and a kick/snare heartbeat.
			value = tanh(sin(TAU * note * local) * 2.5) * exp(-local * 19.0) * 0.14
			value += sin(TAU * (60.0 * local - 75.0 * local * local)) * exp(-local * 28.0) * (0.20 if beat % 4 == 0 else 0.06)
			if beat % 4 == 2:
				value += sin(TAU * 1800.0 * local) * sin(TAU * 2713.0 * local) * exp(-local * 35.0) * 0.10
			value += sin(TAU * root * local) * exp(-local * 12.0) * 0.06
		var fade: float = minf(1.0, minf(t, duration - t) * 40.0)
		bytes.encode_s16(i * 2, int(clampf(value * fade, -0.9, 0.9) * 32767))
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = bytes
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = count
	return stream
