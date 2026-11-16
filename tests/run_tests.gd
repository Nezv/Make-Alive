extends Node
## Test runner. Finds res://tests/test_*.gd, runs every test_* method, prints a report,
## and exits with code 1 if anything failed. Optional filter: `-- --filter=zombie`.

func _ready() -> void:
	Settings.path = "user://test_run_settings.cfg" # never read or write the player's own file
	Settings.apply_to_engine = false
	Settings.reset_to_defaults(false)
	var filter := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--filter="):
			filter = a.trim_prefix("--filter=").to_lower()

	var files: Array[String] = []
	for f in DirAccess.get_files_at("res://tests"):
		if f.begins_with("test_") and f.ends_with(".gd") and f != "test_case.gd":
			files.append(f)
	files.sort()

	var passed := 0
	var failed := 0
	var total_asserts := 0
	var started := Time.get_ticks_msec()
	for f in files:
		var script: GDScript = load("res://tests/" + f)
		if script == null or not script.can_instantiate(): # a parse error must fail the run, not hang it
			print("FAIL  %s  (script failed to load)" % f)
			failed += 1
			continue
		var probe: TestCase = script.new()
		var methods: Array[String] = []
		for m in probe.get_method_list():
			var mname: String = m.name
			if mname.begins_with("test_"):
				methods.append(mname)
		probe.free()
		for mname in methods:
			var label := "%s::%s" % [f.trim_suffix(".gd"), mname]
			if filter != "" and not label.to_lower().contains(filter):
				continue
			var t: TestCase = script.new()
			add_child(t)
			await t.before_each()
			await t.call(mname)
			await t.after_each()
			t.cleanup()
			total_asserts += t.asserts
			if t.failures.is_empty():
				passed += 1
				print("pass  ", label)
			else:
				failed += 1
				print("FAIL  ", label)
				for msg in t.failures:
					print("        ", msg)
			t.free()
			await get_tree().physics_frame
		if script.has_method("after_all"): # a static func that frees whatever the file's tests shared
			script.call("after_all")

	var secs := (Time.get_ticks_msec() - started) / 1000.0
	print("\n%d passed, %d failed, %d asserts, %.1fs" % [passed, failed, total_asserts, secs])
	print("TESTS %s" % ("FAILED" if failed > 0 or passed == 0 else "OK"))
	get_tree().quit(1 if failed > 0 or passed == 0 else 0)
