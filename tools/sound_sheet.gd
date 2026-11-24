extends Node
## Writes every world sound (WorldSounds) as a WAV into references/shots/sounds/ so they can be listened
## to, then every other sound the game registers (guns, handling, zombies, UI...) into
## references/shots/sounds/game/ with an index.json (name -> bus, loop), then quits.
## tools/sound_sheet.py draws the world sounds' waveforms and spectrograms on one sheet;
## tools/verify_page.py puts all of them on the verification page.
##   tools\sounds.ps1 (runs this scene headless, then the sheet)


func _ready() -> void:
	var dir := ProjectSettings.globalize_path("res://references/shots/sounds")
	DirAccess.make_dir_recursive_absolute(dir)
	var names: Array = WorldSounds.ONE_SHOTS.keys() + WorldSounds.LOOPS.keys()
	for sound: String in names:
		var s := Sfx.to_stream(WorldSounds.samples(sound))
		s.save_to_wav(dir.path_join(sound + ".wav"))
	print("[sounds] %d wavs in %s" % [names.size(), dir])

	var game_dir := dir.path_join("game")
	DirAccess.make_dir_recursive_absolute(game_dir)
	Sfx.stream("gunshot") # registers the built-in sounds, the gun voices and the handling
	var index := {}
	for sound: String in Sfx._defs.keys():
		if sound in names:
			continue
		var s := Sfx.stream(sound)
		if s == null:
			continue
		s.save_to_wav(game_dir.path_join(sound + ".wav"))
		index[sound] = { "bus": Sfx._defs[sound].bus, "loop": Sfx._defs[sound].get("loop", false) }
	var f := FileAccess.open(game_dir.path_join("index.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(index, "\t", true))
	f.close()
	print("[sounds] %d more wavs in %s" % [index.size(), game_dir])
	get_tree().quit()
