class_name Sfx
## Procedural sounds, no audio files needed. Swap for real samples in res://assets/ later.

static var _shot: AudioStreamWAV


static func gunshot() -> AudioStreamWAV:
	if _shot:
		return _shot
	var rate := 22050
	var n := int(rate * 0.25)
	var data := PackedByteArray()
	data.resize(n * 2)
	var lp := 0.0
	for i in n:
		var env := pow(1.0 - float(i) / n, 3.0)
		lp = lerpf(lp, randf_range(-1.0, 1.0) * env, 0.35) # crude low-pass on noise
		data.encode_s16(i * 2, int(clampf(lp * 1.8, -1.0, 1.0) * 32767.0))
	_shot = AudioStreamWAV.new()
	_shot.format = AudioStreamWAV.FORMAT_16_BITS
	_shot.mix_rate = rate
	_shot.stereo = false
	_shot.data = data
	return _shot
