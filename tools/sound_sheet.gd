extends Node
## Writes every world sound (WorldSounds) as a WAV into references/shots/sounds/ so they can be listened
## to, then quits. tools/sound_sheet.py draws their waveforms and spectrograms on one sheet.
##   tools\sounds.ps1 (runs this scene headless, then the sheet)


func _ready() -> void:
	var dir := ProjectSettings.globalize_path("res://references/shots/sounds")
	DirAccess.make_dir_recursive_absolute(dir)
	var names: Array = WorldSounds.ONE_SHOTS.keys() + WorldSounds.LOOPS.keys()
	for sound: String in names:
		var s := Sfx.to_stream(WorldSounds.samples(sound))
		s.save_to_wav(dir.path_join(sound + ".wav"))
	print("[sounds] %d wavs in %s" % [names.size(), dir])
	get_tree().quit()
