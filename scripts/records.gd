class_name Records
## Best times, per mission and difficulty, kept in `user://records.cfg`. Tests point `path` at a
## file of their own and never touch the real one.

static var path := "user://records.cfg"


static func best_time(mission: String, difficulty := "normal") -> float:
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return -1.0
	return float(cfg.get_value(mission, difficulty, -1.0))


## Record a finished run. True if it beat the best time (or was the first).
static func submit(mission: String, seconds: float, difficulty := "normal") -> bool:
	if mission == "" or seconds <= 0.0:
		return false
	var cfg := ConfigFile.new()
	cfg.load(path) # a missing or broken file is just no records yet
	var best := float(cfg.get_value(mission, difficulty, -1.0))
	if best > 0.0 and best <= seconds:
		return false
	cfg.set_value(mission, difficulty, seconds)
	cfg.save(path)
	return true
