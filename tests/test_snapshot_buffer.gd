extends TestCase


func test_interpolates_between_two_samples() -> void:
	var b := SnapshotBuffer.new()
	b.push(Vector3(0, 0, 0), 0.0, 1000)
	b.push(Vector3(10, 0, 0), 1.0, 1100)
	var s := b.sample(1050 + Config.INTERP_DELAY_MS)
	assert_near((s[0] as Vector3).x, 5.0)
	assert_near(s[1], 0.5)


func test_holds_last_sample_when_starved() -> void:
	var b := SnapshotBuffer.new()
	b.push(Vector3(1, 2, 3), 0.25, 1000)
	var s := b.sample(99999)
	assert_eq(s[0], Vector3(1, 2, 3))


func test_keeps_a_bounded_history() -> void:
	var b := SnapshotBuffer.new()
	for i in 50:
		b.push(Vector3(i, 0, 0), 0.0, i * 50)
	assert_lt(b.size(), 12)
