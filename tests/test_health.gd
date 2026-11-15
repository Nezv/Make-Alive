extends TestCase


func test_low_fires_once_when_crossing_threshold() -> void:
	var h := Health.new(100, 0.3)
	var lows := [0]
	h.low.connect(func(): lows[0] += 1)
	h.damage(50)
	assert_eq(lows[0], 0, "not low at 50")
	h.damage(25)
	assert_eq(lows[0], 1, "low at 25")
	h.damage(5)
	assert_eq(lows[0], 1, "doesn't re-fire while still low")


func test_low_can_fire_again_after_healing() -> void:
	var h := Health.new(100, 0.3)
	var lows := [0]
	h.low.connect(func(): lows[0] += 1)
	h.damage(80)
	h.heal(50)
	h.damage(50)
	assert_eq(lows[0], 2)


func test_died_fires_at_zero_and_hp_never_negative() -> void:
	var h := Health.new(100, 0.3)
	var died := [0]
	h.died.connect(func(): died[0] += 1)
	h.damage(250)
	assert_eq(h.hp, 0)
	assert_eq(died[0], 1)
	h.damage(10)
	assert_eq(died[0], 1, "dead things don't die twice")


func test_heal_caps_at_max() -> void:
	var h := Health.new(100, 0.3)
	h.damage(10)
	h.heal(500)
	assert_eq(h.hp, 100)
