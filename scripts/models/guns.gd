class_name Guns
## The nine guns, built from boxes. Squarish on purpose, but with the real silhouettes:
## the P90's top magazine, the AK's curved one, the Val's fat suppressor, the SPAS heat shield...
##
## Colours carry shininess in their alpha: 1.0 = bare metal, 0.0 = matte wood or plastic.
## Adding a gun: add it to Weapons.DEFS, write `_name(m, b, mg, a)` here, add it to `build`.
##   b = fixed body · mg = magazine (comes out on reload) · a = the part that moves when it cycles

const STEEL := Color(0.10, 0.105, 0.115, 0.9)
const STEEL_LIGHT := Color(0.21, 0.22, 0.24, 0.95)
const POLY := Color(0.035, 0.035, 0.04, 0.12)
const POLY_GREY := Color(0.09, 0.095, 0.1, 0.15)
const WOOD := Color(0.30, 0.14, 0.05, 0.05)
const WOOD_DARK := Color(0.2, 0.09, 0.035, 0.05)
const OLIVE := Color(0.13, 0.16, 0.09, 0.3)
const TAN := Color(0.32, 0.27, 0.17, 0.1)
const BAKELITE := Color(0.33, 0.1, 0.03, 0.2)
const GLASS := Color(0.04, 0.1, 0.18, 1.0)

const SHADER := "
shader_type spatial;
void fragment() {
	ALBEDO = COLOR.rgb;
	METALLIC = COLOR.a;
	ROUGHNESS = mix(0.52, 0.27, COLOR.a);
	SPECULAR = 0.6;
}
"

static var _mat: ShaderMaterial


## Shared by every gun part: vertex colour is the paint, vertex alpha is how metallic it is.
static func material() -> ShaderMaterial:
	if _mat == null:
		var sh := Shader.new()
		sh.code = SHADER
		_mat = ShaderMaterial.new()
		_mat.shader = sh
	return _mat


static func build(id: int) -> GunModel:
	var m := GunModel.new()
	m.name = "Gun%d" % id
	var b := MeshKit.Builder.new()
	var mg := MeshKit.Builder.new()
	var a := MeshKit.Builder.new()
	match id:
		Weapons.P19: _p19(m, b, mg, a)
		Weapons.P90: _p90(m, b, mg, a)
		Weapons.TYPE95: _type95(m, b, mg, a)
		Weapons.AK47: _ak47(m, b, mg, a)
		Weapons.ASVAL: _asval(m, b, mg, a)
		Weapons.USAS12: _usas12(m, b, mg, a)
		Weapons.SPAS12: _spas12(m, b, mg, a)
		Weapons.T5000: _t5000(m, b, mg, a)
		Weapons.DRAGUNOV: _dragunov(m, b, mg, a)
	m.body = b.instance(material(), false)
	m.add_child(m.body)
	if mg.count > 0:
		m.mag = mg.instance(material(), false)
		m.add_child(m.mag)
	if a.count > 0:
		m.action = a.instance(material(), false)
		m.add_child(m.action)
	return m


## Tilt around the sideways axis. Negative rakes a grip back; positive sweeps a magazine forward
## or droops a stock.
static func rx(angle: float) -> Basis:
	return Basis(Vector3.RIGHT, angle)


static func V(x: float, y: float, z: float) -> Vector3:
	return Vector3(x, y, z)


static func _p19(m: GunModel, b: MeshKit.Builder, mg: MeshKit.Builder, a: MeshKit.Builder) -> void:
	a.box(V(0.028, 0.03, 0.185), V(0, 0.05, -0.045), STEEL)              # slide
	a.box(V(0.03, 0.02, 0.03), V(0, 0.048, 0.03), STEEL_LIGHT)           # slide serrations
	a.box(V(0.006, 0.008, 0.008), V(0, 0.069, -0.13), STEEL_LIGHT)       # front sight
	a.box(V(0.006, 0.008, 0.008), V(-0.009, 0.069, 0.04), STEEL_LIGHT)   # rear sight
	a.box(V(0.006, 0.008, 0.008), V(0.009, 0.069, 0.04), STEEL_LIGHT)
	b.box(V(0.014, 0.014, 0.02), V(0, 0.05, -0.142), STEEL_LIGHT)        # barrel crown
	b.box(V(0.027, 0.024, 0.165), V(0, 0.023, -0.04), POLY)              # frame
	b.box(V(0.022, 0.012, 0.05), V(0, 0.008, -0.1), POLY)                # rail
	b.box(V(0.027, 0.105, 0.048), V(0, -0.04, 0.03), POLY, rx(-0.22))    # grip
	b.box(V(0.01, 0.006, 0.055), V(0, -0.02, -0.03), POLY)               # trigger guard
	b.box(V(0.01, 0.03, 0.006), V(0, -0.006, -0.058), POLY)
	b.box(V(0.006, 0.02, 0.006), V(0, -0.004, -0.025), STEEL_LIGHT, rx(0.3)) # trigger
	mg.box(V(0.02, 0.1, 0.034), V(0, -0.045, 0.031), STEEL, rx(-0.22))   # magazine
	mg.box(V(0.029, 0.01, 0.052), V(0, -0.094, 0.042), POLY_GREY, rx(-0.22)) # base plate
	m.muzzle = V(0, 0.05, -0.155)
	m.sight = V(0, 0.076, 0.04)
	m.grip = V(0, -0.05, 0.035)
	m.support = V(-0.025, -0.07, 0.03)
	m.mag_at = V(0, -0.08, 0.04)
	m.mag_out = V(0, -0.28, 0.06)
	m.action_travel = V(0, 0, 0.035)
	m.hip = V(0.15, -0.15, -0.5)
	m.ads_dist = 0.4


static func _p90(m: GunModel, b: MeshKit.Builder, mg: MeshKit.Builder, a: MeshKit.Builder) -> void:
	b.box(V(0.052, 0.075, 0.44), V(0, 0.02, 0.04), POLY)                 # shell
	b.box(V(0.05, 0.07, 0.13), V(0, -0.05, 0.19), POLY)                  # butt
	b.box(V(0.053, 0.1, 0.012), V(0, -0.03, 0.262), POLY_GREY)           # butt plate
	b.box(V(0.04, 0.03, 0.12), V(0, -0.075, 0.07), POLY)                 # thumbhole bar
	b.box(V(0.04, 0.085, 0.04), V(0, -0.055, 0.0), POLY, rx(-0.2))       # rear grip
	b.box(V(0.04, 0.08, 0.04), V(0, -0.055, -0.11), POLY, rx(0.25))      # front grip
	b.box(V(0.04, 0.025, 0.15), V(0, -0.095, -0.055), POLY)              # guard loop
	b.box(V(0.046, 0.05, 0.07), V(0, 0.0, -0.19), POLY)                  # front shroud
	b.box(V(0.02, 0.02, 0.07), V(0, 0.02, -0.25), STEEL)                 # flash hider
	b.box(V(0.03, 0.014, 0.2), V(0, 0.09, -0.08), STEEL)                 # top rail
	b.box(V(0.008, 0.03, 0.012), V(0, 0.108, -0.16), STEEL)              # front post
	b.box(V(0.022, 0.03, 0.012), V(0, 0.108, 0.0), STEEL)                # rear sight
	mg.box(V(0.046, 0.024, 0.27), V(0, 0.07, 0.09), TAN)                 # see-through top magazine
	mg.box(V(0.048, 0.03, 0.04), V(0, 0.068, -0.05), POLY_GREY)          # feed end
	a.box(V(0.066, 0.012, 0.02), V(0, 0.035, -0.12), STEEL_LIGHT)        # charging handle
	m.muzzle = V(0, 0.02, -0.29)
	m.sight = V(0, 0.126, 0.0)
	m.grip = V(0, -0.06, 0.0)
	m.support = V(0, -0.06, -0.11)
	m.mag_at = V(0, 0.08, 0.1)
	m.mag_out = V(-0.05, 0.14, 0.18)
	m.action_travel = V(0, 0, 0.05)
	m.hip = V(0.17, -0.16, -0.45)
	m.ads_dist = 0.3
	m.reload_rot = V(-0.2, 0.25, 0.35)


static func _type95(m: GunModel, b: MeshKit.Builder, mg: MeshKit.Builder, a: MeshKit.Builder) -> void:
	b.box(V(0.05, 0.075, 0.34), V(0, 0.01, 0.12), POLY)                  # receiver and butt
	b.box(V(0.052, 0.11, 0.05), V(0, -0.005, 0.31), POLY_GREY)           # butt pad
	b.box(V(0.046, 0.06, 0.2), V(0, 0.0, -0.14), POLY)                   # handguard
	b.box(V(0.02, 0.016, 0.26), V(0, 0.115, -0.02), POLY)                # carry handle
	b.box(V(0.02, 0.055, 0.025), V(0, 0.08, -0.135), POLY)
	b.box(V(0.02, 0.055, 0.025), V(0, 0.08, 0.095), POLY)
	b.box(V(0.014, 0.02, 0.014), V(0, 0.133, 0.09), STEEL)               # rear sight
	b.box(V(0.034, 0.09, 0.04), V(0, -0.07, -0.02), POLY, rx(-0.2))      # grip
	b.box(V(0.02, 0.012, 0.15), V(0, -0.112, -0.1), POLY)                # full-hand guard
	b.box(V(0.03, 0.085, 0.028), V(0, -0.07, -0.175), POLY)
	b.box(V(0.018, 0.018, 0.2), V(0, 0.012, -0.33), STEEL)               # barrel
	b.box(V(0.012, 0.12, 0.02), V(0, 0.078, -0.3), STEEL)                # front sight tower
	b.box(V(0.024, 0.024, 0.05), V(0, 0.012, -0.45), STEEL_LIGHT)        # muzzle device
	mg.box(V(0.028, 0.09, 0.06), V(0, -0.07, 0.17), POLY_GREY, rx(0.12)) # magazine, behind the grip
	mg.box(V(0.028, 0.08, 0.06), V(0, -0.14, 0.155), POLY_GREY, rx(0.35))
	a.box(V(0.012, 0.012, 0.03), V(0, 0.06, -0.05), STEEL_LIGHT)         # charging handle
	m.muzzle = V(0, 0.012, -0.48)
	m.sight = V(0, 0.147, 0.09)
	m.grip = V(0, -0.075, -0.015)
	m.support = V(0, -0.07, -0.175)
	m.mag_at = V(0, -0.12, 0.16)
	m.mag_out = V(0, -0.3, 0.04)
	m.hip = V(0.17, -0.17, -0.4)
	m.ads_dist = 0.3


static func _ak47(m: GunModel, b: MeshKit.Builder, mg: MeshKit.Builder, a: MeshKit.Builder) -> void:
	b.box(V(0.04, 0.06, 0.27), V(0, 0.012, 0.02), STEEL)                 # receiver
	b.box(V(0.036, 0.022, 0.21), V(0, 0.052, 0.04), STEEL_LIGHT)         # dust cover
	b.box(V(0.034, 0.065, 0.25), V(0, -0.012, 0.275), WOOD, rx(0.1))     # stock
	b.box(V(0.036, 0.085, 0.015), V(0, -0.025, 0.4), STEEL, rx(0.1))     # butt plate
	b.box(V(0.03, 0.095, 0.042), V(0, -0.062, 0.085), WOOD_DARK, rx(-0.28)) # grip
	b.box(V(0.008, 0.006, 0.07), V(0, -0.042, 0.02), STEEL)              # trigger guard
	b.box(V(0.044, 0.045, 0.17), V(0, 0.004, -0.2), WOOD)                # lower handguard
	b.box(V(0.034, 0.026, 0.14), V(0, 0.04, -0.2), WOOD_DARK)            # upper handguard
	b.box(V(0.022, 0.014, 0.05), V(0, 0.062, -0.1), STEEL)               # rear sight leaf
	b.box(V(0.015, 0.015, 0.13), V(0, 0.045, -0.335), STEEL)             # gas tube
	b.box(V(0.016, 0.016, 0.31), V(0, 0.014, -0.435), STEEL)             # barrel
	b.box(V(0.02, 0.045, 0.02), V(0, 0.03, -0.4), STEEL)                 # gas block
	b.box(V(0.012, 0.058, 0.018), V(0, 0.045, -0.53), STEEL)             # front sight tower
	b.box(V(0.03, 0.01, 0.012), V(0, 0.066, -0.53), STEEL)
	b.box(V(0.022, 0.022, 0.035), V(0, 0.014, -0.6), STEEL_LIGHT)        # muzzle brake
	mg.box(V(0.026, 0.075, 0.058), V(0, -0.05, -0.062), BAKELITE, rx(0.15)) # the banana magazine
	mg.box(V(0.026, 0.07, 0.058), V(0, -0.112, -0.078), BAKELITE, rx(0.4))
	mg.box(V(0.026, 0.065, 0.058), V(0, -0.165, -0.108), BAKELITE, rx(0.68))
	a.box(V(0.022, 0.01, 0.014), V(0.03, 0.04, -0.03), STEEL_LIGHT)      # charging handle
	m.muzzle = V(0, 0.014, -0.62)
	m.sight = V(0, 0.079, -0.1)
	m.grip = V(0, -0.065, 0.09)
	m.support = V(0, -0.03, -0.2)
	m.mag_at = V(0, -0.1, -0.075)
	m.mag_out = V(0, -0.3, -0.06)
	m.action_travel = V(0, 0, 0.08)
	m.hip = V(0.19, -0.19, -0.52)
	m.ads_dist = 0.42


static func _asval(m: GunModel, b: MeshKit.Builder, mg: MeshKit.Builder, a: MeshKit.Builder) -> void:
	b.box(V(0.04, 0.058, 0.21), V(0, 0.012, 0.02), STEEL)                # receiver
	b.box(V(0.036, 0.018, 0.19), V(0, 0.048, 0.02), STEEL_LIGHT)         # top cover
	b.box(V(0.04, 0.04, 0.31), V(0, 0.016, -0.27), STEEL)                # the built-in suppressor
	b.box(V(0.044, 0.044, 0.02), V(0, 0.016, -0.2), STEEL_LIGHT)
	b.box(V(0.044, 0.044, 0.02), V(0, 0.016, -0.415), STEEL_LIGHT)
	b.box(V(0.046, 0.045, 0.1), V(0, -0.004, -0.14), POLY)               # handguard
	b.box(V(0.03, 0.09, 0.042), V(0, -0.06, 0.07), POLY, rx(-0.25))      # grip
	b.box(V(0.008, 0.006, 0.065), V(0, -0.04, 0.01), STEEL)              # trigger guard
	b.box(V(0.012, 0.012, 0.25), V(0, 0.035, 0.25), STEEL)               # skeleton stock
	b.box(V(0.012, 0.012, 0.25), V(0, -0.02, 0.245), STEEL, rx(0.2))
	b.box(V(0.022, 0.11, 0.016), V(0, -0.012, 0.375), STEEL)
	b.box(V(0.02, 0.014, 0.03), V(0, 0.063, -0.05), STEEL)               # rear sight
	b.box(V(0.01, 0.034, 0.012), V(0, 0.052, -0.39), STEEL)              # front sight
	mg.box(V(0.026, 0.07, 0.05), V(0, -0.05, -0.04), POLY_GREY, rx(0.15)) # short magazine
	mg.box(V(0.026, 0.06, 0.05), V(0, -0.105, -0.055), POLY_GREY, rx(0.4))
	a.box(V(0.022, 0.01, 0.014), V(0.03, 0.035, -0.02), STEEL_LIGHT)     # charging handle
	m.muzzle = V(0, 0.016, -0.43)
	m.sight = V(0, 0.074, -0.05)
	m.grip = V(0, -0.06, 0.075)
	m.support = V(0, -0.03, -0.14)
	m.mag_at = V(0, -0.08, -0.05)
	m.mag_out = V(0, -0.28, -0.04)
	m.hip = V(0.19, -0.19, -0.5)
	m.ads_dist = 0.42


static func _usas12(m: GunModel, b: MeshKit.Builder, mg: MeshKit.Builder, a: MeshKit.Builder) -> void:
	b.box(V(0.056, 0.09, 0.32), V(0, 0.01, 0.0), POLY)                   # receiver
	b.box(V(0.05, 0.075, 0.24), V(0, 0.005, 0.28), POLY)                 # stock
	b.box(V(0.052, 0.1, 0.02), V(0, 0.0, 0.41), POLY_GREY)               # butt pad
	b.box(V(0.02, 0.016, 0.2), V(0, 0.12, 0.0), POLY)                    # carry handle
	b.box(V(0.02, 0.06, 0.025), V(0, 0.085, -0.09), POLY)
	b.box(V(0.02, 0.06, 0.025), V(0, 0.085, 0.09), POLY)
	b.box(V(0.016, 0.016, 0.014), V(0, 0.136, 0.085), STEEL)             # rear sight
	b.box(V(0.034, 0.095, 0.045), V(0, -0.075, 0.09), POLY, rx(-0.25))   # grip
	b.box(V(0.008, 0.006, 0.07), V(0, -0.045, 0.03), STEEL)              # trigger guard
	b.box(V(0.06, 0.07, 0.24), V(0, 0.0, -0.28), POLY_GREY)              # handguard
	b.box(V(0.028, 0.028, 0.16), V(0, 0.014, -0.47), STEEL)              # fat barrel
	b.box(V(0.014, 0.115, 0.022), V(0, 0.08, -0.4), STEEL)               # front sight tower
	mg.box(V(0.042, 0.19, 0.08), V(0, -0.125, -0.05), STEEL)             # big box magazine
	mg.box(V(0.046, 0.01, 0.084), V(0, -0.09, -0.05), STEEL_LIGHT)
	mg.box(V(0.046, 0.01, 0.084), V(0, -0.16, -0.05), STEEL_LIGHT)
	a.box(V(0.02, 0.012, 0.03), V(0.036, 0.045, -0.08), STEEL_LIGHT)     # charging handle
	m.muzzle = V(0, 0.014, -0.56)
	m.sight = V(0, 0.147, 0.085)
	m.grip = V(0, -0.075, 0.095)
	m.support = V(0, -0.04, -0.28)
	m.mag_at = V(0, -0.13, -0.05)
	m.mag_out = V(0, -0.34, 0.0)
	m.action_travel = V(0, 0, 0.08)
	m.hip = V(0.19, -0.2, -0.5)
	m.ads_dist = 0.3


static func _spas12(m: GunModel, b: MeshKit.Builder, _mg: MeshKit.Builder, a: MeshKit.Builder) -> void:
	b.box(V(0.046, 0.075, 0.23), V(0, 0.012, 0.03), STEEL)               # receiver
	b.box(V(0.042, 0.034, 0.36), V(0, 0.034, -0.265), STEEL)             # heat shield over the barrel
	for i in 5:
		b.box(V(0.044, 0.008, 0.03), V(0, 0.046, -0.13 - i * 0.06), POLY) # its vent slots
	b.box(V(0.026, 0.026, 0.4), V(0, -0.006, -0.285), STEEL_LIGHT)       # tube magazine
	b.box(V(0.022, 0.022, 0.05), V(0, 0.034, -0.47), STEEL_LIGHT)        # muzzle
	b.box(V(0.033, 0.095, 0.045), V(0, -0.07, 0.09), POLY, rx(-0.25))    # grip
	b.box(V(0.008, 0.006, 0.07), V(0, -0.04, 0.03), STEEL)               # trigger guard
	b.box(V(0.014, 0.014, 0.27), V(0, 0.03, 0.275), STEEL)               # folding stock arm
	b.box(V(0.03, 0.11, 0.014), V(0, 0.0, 0.41), STEEL)                  # butt plate
	b.box(V(0.03, 0.012, 0.06), V(0, -0.055, 0.385), STEEL)              # the hook
	b.box(V(0.016, 0.012, 0.02), V(0, 0.056, 0.02), STEEL)               # rear sight
	b.box(V(0.006, 0.016, 0.01), V(0, 0.059, -0.43), STEEL_LIGHT)        # front blade
	a.box(V(0.052, 0.05, 0.15), V(0, -0.008, -0.23), POLY)               # pump
	for i in 4:
		a.box(V(0.056, 0.053, 0.012), V(0, -0.008, -0.185 - i * 0.03), POLY_GREY)
	m.muzzle = V(0, 0.034, -0.5)
	m.sight = V(0, 0.071, 0.02)
	m.grip = V(0, -0.07, 0.095)
	m.support = V(0, -0.04, -0.23)
	m.port = V(0, -0.045, -0.02)
	m.action_travel = V(0, 0, 0.085)
	m.hip = V(0.19, -0.2, -0.5)
	m.ads_dist = 0.38
	m.reload_rot = V(0.35, 0.15, -0.7)


static func _t5000(m: GunModel, b: MeshKit.Builder, mg: MeshKit.Builder, a: MeshKit.Builder) -> void:
	b.box(V(0.046, 0.05, 0.34), V(0, 0.0, -0.08), OLIVE)                 # chassis
	b.box(V(0.036, 0.036, 0.26), V(0, 0.042, 0.03), STEEL)               # action
	b.box(V(0.024, 0.024, 0.5), V(0, 0.042, -0.35), STEEL)               # heavy barrel
	b.box(V(0.04, 0.03, 0.07), V(0, 0.042, -0.63), STEEL_LIGHT)          # muzzle brake
	b.box(V(0.033, 0.095, 0.045), V(0, -0.07, 0.13), POLY, rx(-0.2))     # grip
	b.box(V(0.02, 0.02, 0.22), V(0, 0.03, 0.27), OLIVE)                  # skeleton stock
	b.box(V(0.02, 0.02, 0.2), V(0, -0.045, 0.32), OLIVE, rx(0.15))
	b.box(V(0.038, 0.03, 0.13), V(0, 0.058, 0.3), POLY)                  # cheek rest
	b.box(V(0.042, 0.13, 0.025), V(0, -0.005, 0.43), POLY_GREY)          # butt pad
	b.box(V(0.028, 0.03, 0.25), V(0, 0.118, 0.02), STEEL)                # scope tube
	b.box(V(0.046, 0.046, 0.08), V(0, 0.118, -0.14), STEEL)              # objective bell
	b.box(V(0.04, 0.04, 0.06), V(0, 0.118, 0.16), STEEL)                 # eyepiece
	b.box(V(0.04, 0.04, 0.004), V(0, 0.118, -0.182), GLASS)
	b.box(V(0.034, 0.034, 0.004), V(0, 0.118, 0.192), GLASS)
	b.box(V(0.018, 0.022, 0.022), V(0, 0.146, 0.02), STEEL_LIGHT)        # turrets
	b.box(V(0.022, 0.018, 0.022), V(0.026, 0.118, 0.02), STEEL_LIGHT)
	b.box(V(0.034, 0.05, 0.016), V(0, 0.085, -0.05), STEEL)              # scope rings
	b.box(V(0.034, 0.05, 0.016), V(0, 0.085, 0.09), STEEL)
	mg.box(V(0.03, 0.075, 0.075), V(0, -0.055, 0.02), STEEL)             # box magazine
	a.box(V(0.045, 0.012, 0.012), V(0.04, 0.042, 0.11), STEEL_LIGHT)     # bolt handle
	a.box(V(0.02, 0.022, 0.022), V(0.066, 0.036, 0.11), POLY)            # bolt knob
	m.muzzle = V(0, 0.042, -0.67)
	m.sight = V(0, 0.118, 0.2)
	m.grip = V(0, -0.07, 0.135)
	m.support = V(0, -0.03, -0.12)
	m.mag_at = V(0, -0.06, 0.02)
	m.mag_out = V(0, -0.25, 0.0)
	m.action_travel = V(0, 0, 0.09)
	m.hip = V(0.19, -0.2, -0.55)
	m.ads_dist = 0.07


static func _dragunov(m: GunModel, b: MeshKit.Builder, mg: MeshKit.Builder, a: MeshKit.Builder) -> void:
	b.box(V(0.038, 0.058, 0.27), V(0, 0.012, 0.02), STEEL)               # receiver
	b.box(V(0.034, 0.02, 0.22), V(0, 0.05, 0.03), STEEL_LIGHT)           # cover
	b.box(V(0.044, 0.05, 0.21), V(0, 0.014, -0.22), WOOD)                # handguard
	for i in 3:
		b.box(V(0.046, 0.01, 0.03), V(0, 0.02, -0.165 - i * 0.055), WOOD_DARK) # its slots
	b.box(V(0.016, 0.016, 0.46), V(0, 0.02, -0.55), STEEL)               # long thin barrel
	b.box(V(0.02, 0.04, 0.02), V(0, 0.035, -0.4), STEEL)                 # gas block
	b.box(V(0.014, 0.014, 0.09), V(0, 0.05, -0.36), STEEL)
	b.box(V(0.012, 0.055, 0.018), V(0, 0.047, -0.7), STEEL)              # front sight
	b.box(V(0.022, 0.022, 0.075), V(0, 0.02, -0.79), STEEL_LIGHT)        # flash hider
	b.box(V(0.032, 0.03, 0.3), V(0, 0.022, 0.3), WOOD)                   # thumbhole stock: top
	b.box(V(0.032, 0.095, 0.04), V(0, -0.055, 0.14), WOOD, rx(-0.3))     # grip
	b.box(V(0.032, 0.03, 0.22), V(0, -0.082, 0.3), WOOD, rx(-0.08))      # bottom
	b.box(V(0.034, 0.14, 0.03), V(0, -0.03, 0.45), WOOD_DARK)            # butt
	b.box(V(0.036, 0.02, 0.12), V(0, 0.047, 0.3), POLY)                  # cheek pad
	b.box(V(0.01, 0.045, 0.11), V(-0.024, 0.07, 0.02), STEEL)            # side scope mount
	b.box(V(0.03, 0.03, 0.2), V(0, 0.108, 0.02), STEEL)                  # scope
	b.box(V(0.04, 0.04, 0.07), V(0, 0.108, -0.11), STEEL)
	b.box(V(0.036, 0.036, 0.05), V(0, 0.108, 0.14), POLY)                # rubber eyecup
	b.box(V(0.034, 0.034, 0.004), V(0, 0.108, -0.147), GLASS)
	b.box(V(0.03, 0.03, 0.004), V(0, 0.108, 0.167), GLASS)
	b.box(V(0.016, 0.02, 0.02), V(0, 0.133, 0.0), STEEL_LIGHT)           # turret
	mg.box(V(0.028, 0.1, 0.07), V(0, -0.065, -0.045), STEEL, rx(0.12))   # magazine
	mg.box(V(0.03, 0.01, 0.074), V(0, -0.113, -0.052), STEEL_LIGHT, rx(0.12))
	a.box(V(0.022, 0.01, 0.014), V(0.03, 0.04, -0.03), STEEL_LIGHT)      # charging handle
	m.muzzle = V(0, 0.02, -0.83)
	m.sight = V(0, 0.108, 0.17)
	m.grip = V(0, -0.06, 0.145)
	m.support = V(0, -0.02, -0.22)
	m.mag_at = V(0, -0.08, -0.05)
	m.mag_out = V(0, -0.3, -0.03)
	m.action_travel = V(0, 0, 0.09)
	m.hip = V(0.19, -0.2, -0.55)
	m.ads_dist = 0.07
