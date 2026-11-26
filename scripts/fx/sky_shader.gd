class_name SkyShader
## The sky's shader (S050), drawn by SkyDome. One pass paints, back to front: the gradient, stars,
## the moon or the sun, two cloud layers (lit by the sun or moon from above and by the town from
## below), the glow of fires on the horizon, their smoke columns, and the far backdrop past the far
## plane: a distant ridge, the town's roofscape and the hill from `profile` (worked out on the CPU
## from the map's heights for where the camera stands), landmark towers, and below the horizon the
## town seen from above (`town`: CityPicture's classes) with its lights at night. Everything past
## the far plane is hazed like the fog that hides it.

const CODE := """
shader_type sky;
render_mode use_debanding;

uniform vec3 zenith : source_color;
uniform vec3 horizon : source_color;
uniform vec3 ground : source_color;
uniform vec3 sun_dir = vec3(0.0, 1.0, 0.0);
uniform vec3 sun_color : source_color;
uniform float sun_size = 0.02;
uniform float is_moon = 0.0;
uniform float stars = 0.0;
uniform float cloud_low = 0.3;
uniform float cloud_high = 0.3;
uniform vec3 cloud_lit : source_color;
uniform vec3 cloud_shade : source_color;
uniform vec3 glow_color : source_color;
uniform float glow = 0.0;
uniform vec2 cloud_offset = vec2(0.0);
uniform float sky_time = 0.0;
uniform vec3 fog_color : source_color;
uniform float fog_begin = 0.0;
uniform float fog_curve = 1.0;
uniform float fog_max = 0.8;
uniform float air = 0.0004;
uniform float flash = 0.0;
uniform float flash_az = 0.0; // where the strike is: it lights its own part of the deck
uniform float cloud_relief = 1.0;
uniform float gain = 1.0; // 1 / the preset's exposure: the sky keeps its own brightness
uniform vec3 cam_pos = vec3(0.0, 2.0, 0.0);
uniform float far_plane = 1200.0;
uniform sampler2D profile : filter_linear, repeat_enable;
uniform vec3 hill_color : source_color;
uniform vec3 roof_color : source_color;
uniform sampler2D town : filter_nearest;
uniform vec4 town_rect = vec4(-2000.0, -1500.0, 4000.0, 3000.0);
uniform float has_town = 0.0;
uniform float lights = 0.0;
uniform vec4 tower_at[6];
uniform vec4 tower_shape[6];
uniform int tower_count = 0;
uniform vec4 smoke_at[4];
uniform int smoke_count = 0;
uniform vec2 wind = vec2(1.0, 0.0);

float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float hash3(vec3 p) {
	vec3 p3 = fract(p * 0.1031);
	p3 += dot(p3, p3.zyx + 31.32);
	return fract((p3.x + p3.y) * p3.z);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p, int octaves) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < octaves; i++) {
		v += a * vnoise(p);
		p = p * 2.03 + vec2(17.1, 9.2);
		a *= 0.5;
	}
	return v;
}

float haze_of(float dist, float density) {
	return 1.0 - exp(-max(dist, 0.0) * density);
}

// The fog the engine lays on geometry at `dist` (depth fog), then thin air past the far plane.
float fog_of(float dist) {
	float t = smoothstep(fog_begin, far_plane, dist);
	float f = pow(t, fog_curve) * fog_max;
	return 1.0 - (1.0 - f) * exp(-max(dist - far_plane, 0.0) * air);
}

float star_hash(vec3 c) {
	return fract(sin(dot(c, vec3(12.9898, 78.233, 37.719))) * 43758.5453);
}

// Compass azimuth (0 north = -Z, east = +X) of a direction, in radians.
float azimuth(vec3 d) {
	return atan(d.x, -d.z);
}

// How much an angle a (radians) lies within half-width w of b, wrapped round the circle.
float ang_diff(float a, float b) {
	return abs(mod(a - b + PI, TAU) - PI);
}

// One cloud layer seen along d: returns (density, lit share) with the layer `h` metres up.
vec2 cloud_layer(vec3 d, float h, float cover, float scale, vec2 drift, int octaves) {
	if (d.y <= 0.0 || cover <= 0.0) {
		return vec2(0.0);
	}
	vec2 p = d.xz / (d.y + 0.06) * h / scale + drift;
	float n = fbm(p, octaves);
	float edge = 1.0 - cover;
	float dens = smoothstep(edge - 0.05, edge + 0.35, n);
	// light: thinner where the sun shines through, darker bellies
	vec2 ps = p + sun_dir.xz * 0.15;
	float lit = clamp(0.5 + (n - fbm(ps, octaves)) * 4.0 * cloud_relief, 0.0, 1.0);
	return vec2(dens, lit);
}

void sky() {
	vec3 d = EYEDIR;
	float el = asin(clamp(d.y, -1.0, 1.0));
	float az = azimuth(d);
	float up = max(d.y, 0.0);

	// 1 gradient: a hazy band at the horizon, the zenith colour overhead, the ground below
	vec3 col = mix(horizon, zenith, pow(up, 0.4));
	float toward_sun = max(dot(d, sun_dir), 0.0);
	if (is_moon < 0.5) {
		// the sky round a low sun takes its colour (dusk), a little everywhere by day
		// a low sun colours a band along the horizon and the sky round itself, not the zenith
		float low_sun = 1.0 - smoothstep(0.0, 0.5, sun_dir.y);
		col = mix(col, sun_color * 1.1, pow(toward_sun, 6.0) * 0.45 * (1.0 - low_sun * 0.6) * step(0.0001, sun_size));
		col = mix(col, sun_color, low_sun * step(0.0001, sun_size) * exp(-up * 7.0) * (0.25 + 0.5 * pow(toward_sun, 2.0)));
	}
	// the town's glow on the haze above it at night
	col += glow_color * glow * 0.5 * exp(-up * 6.0);

	if (AT_CUBEMAP_PASS) {
		// reflections only need the light of the sky: no stars, no backdrop
		vec2 c = cloud_layer(d, 1600.0, cloud_low, 900.0, cloud_offset, 3);
		vec3 cc = mix(cloud_shade, cloud_lit, c.y) + glow_color * glow * 0.3;
		col = mix(col, cc, c.x * 0.9);
		if (d.y < 0.0) {
			col = mix(ground, fog_color, exp(d.y * 6.0));
		}
		COLOR = col * gain;
	} else {
		// 2 stars where the night is clear, twinkling
		if (stars > 0.0 && d.y > 0.0) {
			vec3 q = d * 240.0;
			vec3 c = floor(q);
			float h = star_hash(c);
			vec3 jit = vec3(star_hash(c + 1.7), star_hash(c + 5.3), star_hash(c + 9.1)) * 0.6 + 0.2;
			float dd = length(fract(q) - jit);
			float star = step(0.975, h) * smoothstep(0.2, 0.02, dd) * (0.35 + 0.65 * fract(h * 37.0));
			float twinkle = 0.65 + 0.35 * sin(sky_time * (2.0 + h * 9.0) + h * 80.0);
			col += vec3(0.85, 0.9, 1.0) * star * twinkle * stars * smoothstep(0.03, 0.3, d.y) * 1.6;
		}

		// 3 the moon (a disc with seas) or the sun (a disc with a halo)
		float cosang = dot(d, sun_dir);
		if (sun_size > 0.0) {
			float r = sun_size;
			float disc = smoothstep(cos(r), cos(r * 0.85), cosang);
			if (is_moon > 0.5) {
				vec3 m = d - sun_dir;
				float seas = vnoise(m.xy * 160.0 + 3.0) * 0.5 + vnoise(m.zy * 300.0) * 0.25;
				col = mix(col, vec3(0.92, 0.93, 0.88) * (1.05 - seas * 0.5), disc);
				col += sun_color * pow(max(cosang, 0.0), 900.0) * 0.25;
			} else {
				col = mix(col, sun_color * 6.0, disc);
				col += sun_color * pow(max(cosang, 0.0), 300.0) * 0.8;
			}
		}

		float sun_side = mix(1.0, 0.25 + 0.75 * pow(toward_sun, 1.5), (1.0 - smoothstep(0.0, 0.4, sun_dir.y)) * (1.0 - is_moon));
		// 4 clouds: a high thin layer, then the low one; lit from above, the town from below
		vec2 hi = cloud_layer(d, 6000.0, cloud_high, 2600.0, cloud_offset * 0.6 + vec2(40.0, 11.0), 4);
		vec2 lo = cloud_layer(d, 1500.0, cloud_low, 800.0 * (1.0 + cloud_low), cloud_offset, 5);
		float horizon_fade = smoothstep(0.0, 0.12, d.y);
		vec3 hi_col = mix(cloud_shade, cloud_lit, (0.5 + hi.y * 0.5) * sun_side);
		col = mix(col, hi_col, hi.x * 0.55 * horizon_fade);
		vec3 lo_col = mix(cloud_shade, cloud_lit, lo.y * sun_side);
		if (is_moon < 0.5) {
			// a low sun lights their edges and undersides toward it
			lo_col += sun_color * pow(toward_sun, 4.0) * 0.6 * (1.0 - smoothstep(0.0, 0.4, sun_dir.y)) * step(0.001, sun_size);
		}
		lo_col += glow_color * glow * (0.55 + 0.45 * (1.0 - lo.y)) * (1.0 - smoothstep(0.0, 0.7, d.y) * 0.5);
		float strike = flash * exp(-pow(ang_diff(az, flash_az), 2.0) * 6.0) * exp(-max(d.y - 0.15, 0.0) * 3.0);
		lo_col += vec3(0.62, 0.64, 0.78) * strike * (0.3 + 1.2 * (1.0 - lo.y)) * (0.5 + vnoise(d.xz / (d.y + 0.06) * 3.0));
		float lo_a = lo.x * horizon_fade;
		col = mix(col, lo_col, lo_a);
		col += vec3(0.25, 0.26, 0.32) * strike * (1.0 - lo_a) * 0.4;
		// clouds near the horizon sink into the haze
		col = mix(col, fog_color, (1.0 - smoothstep(0.0, 0.18, d.y)) * 0.55 * step(0.0, d.y));

		// 5 fires on the horizon: a glow on the haze and the clouds above each, then its smoke
		for (int i = 0; i < smoke_count; i++) {
			vec4 s = smoke_at[i];
			vec3 to = vec3(s.x, 0.0, s.y) - cam_pos;
			float dist = length(to.xz);
			float saz = atan(to.x, -to.z);
			float base = atan(-cam_pos.y, dist);
			float da = ang_diff(az, saz);
			float fire_glow = exp(-da * da * 160.0) * exp(-max(el - base, 0.0) * 14.0) * s.z;
			col += glow_color * fire_glow * (0.15 + lights * 0.6) * (1.0 - haze_of(dist, air) * 0.6);
			// the column: rises 400 m, widens, leans with the wind
			float rise = clamp((tan(el) * dist + cam_pos.y) / 420.0, 0.0, 1.0);
			if (el > base - 0.002 && rise < 1.0) {
				vec2 side = normalize(vec2(-to.z, to.x));
				float lean = dot(side, wind) / max(length(wind), 1.0) * min(length(wind), 1.5) * rise * rise * 220.0 / dist;
				float width = (8.0 + rise * 70.0) / dist;
				float t = (ang_diff(az, saz + lean)) / width;
				float n = fbm(vec2(t * 1.5 + s.w, rise * 6.0 - sky_time * 0.08 * s.z), 4);
				float a = (1.0 - smoothstep(0.35, 1.0, t + (n - 0.5) * 0.9)) * (1.0 - smoothstep(0.55, 1.0, rise)) * s.z;
				// smoke is darker than the cloud it rises into, in the same light
				vec3 smoke = mix(cloud_shade, cloud_lit, 0.45) * vec3(0.62, 0.6, 0.58);
				smoke += glow_color * lights * 0.5 * exp(-rise * 6.0);
				smoke = mix(smoke, fog_color, haze_of(dist, air) * 0.7);
				col = mix(col, smoke, clamp(a * 0.85, 0.0, 1.0));
			}
		}

		// 6 the far backdrop, back to front
		vec4 prof = texture(profile, vec2(az / TAU + 0.5, 0.5));
		bool back = false;
		// a distant ridge in the west (the serra), and low hills all round
		float west = smoothstep(0.7, 0.0, ang_diff(az, -1.35));
		float ridge = west * (0.022 + 0.014 * fbm(vec2(az * 7.0, 1.0), 4) + 0.006 * fbm(vec2(az * 40.0, 3.0), 3));
		ridge *= 1.0 - clamp(cam_pos.y / 3000.0, 0.0, 1.0);
		if (el < ridge && el > -0.002) {
			col = mix(mix(hill_color, zenith, 0.25), fog_color, 0.72);
			back = true;
		}
		// the town's roofscape past the far plane: roofs, chimney stacks
		float town_el = prof.z;
		if (prof.w > far_plane * 0.85) {
			float chim = step(0.72, hash(vec2(floor(az * 2400.0), 7.0))) * atan(3.5, prof.w);
			float roofs = atan(2.5, prof.w) * vnoise(vec2(az * 900.0, 2.0));
			float top = town_el + roofs + chim;
			if (el < top && top > -0.006) {
				vec3 r = roof_color * (0.85 + 0.3 * hash(vec2(floor(az * 900.0), 3.0)));
				float lit_window = step(0.985, hash(floor(vec2(az * 3000.0, el * 3000.0)))) * lights;
				r += glow_color * lit_window * 1.5;
				col = mix(r, fog_color, fog_of(prof.w));
				back = true;
			}
		}
		// the hill (its forest's crowns on the skyline) over the town when it is nearer
		if (prof.y > far_plane * 0.85) {
			float crowns = atan(9.0, prof.y) * (0.55 + 0.45 * fbm(vec2(az * 1400.0, 5.0), 3));
			float top = prof.x + crowns;
			if (el < top && (prof.y < prof.w || prof.w < far_plane * 0.85 || el > town_el + atan(4.0, prof.w))) {
				vec3 hc = hill_color * (0.8 + 0.4 * fbm(vec2(az * 600.0, el * 600.0), 3));
				col = mix(hc, fog_color, el > 0.0 ? haze_of(prof.y, air) : fog_of(prof.y));
				back = true;
			}
		}
		// landmark towers: x base y z height; shape: width, kind (0 spire, 1 campanile, 2 tower, 3 mill)
		for (int i = 0; i < tower_count; i++) {
			vec4 t = tower_at[i];
			vec4 sh = tower_shape[i];
			vec3 to = vec3(t.x, t.y, t.z) - cam_pos;
			float dist = length(to.xz);
			if (dist < 30.0) {
				continue;
			}
			float taz = atan(to.x, -to.z);
			float da = ang_diff(az, taz);
			float lo_el = atan(to.y, dist);
			float hi_el = atan(to.y + t.w, dist);
			float f = (el - lo_el) / max(hi_el - lo_el, 0.0001); // 0 at the foot, 1 at the top
			float half_w = atan(sh.x * 0.5, dist);
			float w = half_w;
			float kind = sh.y;
			bool inside = false;
			if (kind < 0.5) { // a church: square tower to 0.55, then a spire to the top
				w = f < 0.55 ? half_w : half_w * (1.0 - (f - 0.55) / 0.45) * 0.8;
				inside = f >= 0.0 && f <= 1.0 && da < w;
			} else if (kind < 1.5) { // a campanile: shaft, belfry with a hipped cap and a lantern
				w = f < 0.8 ? half_w : (f < 0.9 ? half_w * 1.1 * (1.0 - (f - 0.8) * 7.0) : half_w * 0.2);
				inside = f >= 0.0 && f <= 1.0 && da < w;
			} else if (kind < 2.5) { // the telegraph tower: a stone tower, the mast and its arm on top
				bool body = f >= 0.0 && f <= 0.72 && da < half_w * (1.0 - f * 0.12);
				bool mast = f >= 0.72 && f <= 1.0 && da < half_w * 0.08;
				bool arm = abs(f - 0.93) < 0.025 && da < half_w * 0.9;
				inside = body || mast || arm;
			} else { // a windmill: a tapered tower, a cap, four sails turning slowly
				bool body = f >= 0.0 && f <= 0.62 && da < half_w * (0.75 - f * 0.35);
				bool cap = f > 0.62 && f < 0.7 && da < half_w * 0.5;
				vec2 hub = vec2(0.0, 0.66);
				vec2 q = vec2((mod(az - taz + PI, TAU) - PI) / max(half_w, 1e-5) * 0.5, f);
				vec2 r = (q - hub) * vec2(1.0, (hi_el - lo_el) / max(half_w * 2.0, 1e-5));
				float ang = atan(r.y, r.x) + sky_time * 0.25;
				float len = length(r);
				bool sails = len < 0.95 && abs(sin(ang * 2.0)) < 0.16 + 0.06 * step(0.3, len);
				inside = body || cap || sails;
			}
			if (inside) {
				vec3 tc = hill_color * 0.9 + roof_color * 0.25;
				col = mix(tc, fog_color, haze_of(dist, air) * 0.9);
				back = true;
			}
		}

		// 7 below the horizon: the town from above past the far plane, the way the far plane cuts it
		if (d.y < 0.0) {
			float above = max(cam_pos.y, 0.5);
			float dist = above / max(-d.y, 0.0005);
			if (!back) {
				vec3 hit = cam_pos + d * dist;
				vec2 uv = (hit.xz - town_rect.xy) / town_rect.zw;
				float cls = 1.0; // outside the picture: more town
				if (has_town > 0.5 && uv.x > 0.0 && uv.x < 1.0 && uv.y > 0.0 && uv.y < 1.0) {
					cls = texture(town, uv).r * 255.0;
				}
				vec3 g = ground;
				float lamp = 0.0;
				float cell = hash(floor(hit.xz / 7.0));
				if (cls < 0.5) { g = ground; }
				else if (cls < 1.5) {
					// slate, zinc and here and there red tile, lit walls between them
					g = roof_color * (0.7 + 0.6 * cell);
					g = mix(g, vec3(0.42, 0.26, 0.21) * (roof_color.r * 2.2 + 0.1), step(0.78, cell));
					g = mix(g, ground * 1.15, step(0.55, hash(floor(hit.xz / 4.0) + 3.1)) * 0.35);
					lamp = step(0.93, cell) * 0.6;
				}
				else if (cls < 3.5) { g = ground * 0.8; lamp = step(0.45, hash(floor(hit.xz / 14.0))) * 1.3; }
				else if (cls < 4.5) { g = mix(fog_color, zenith, 0.4) * 0.8; }
				else { g = hill_color; }
				// far away the dots blur into a glow
				float blur = smoothstep(800.0, 3000.0, dist);
				lamp = mix(lamp, (0.1 + 0.35 * step(1.5, cls)) * step(0.5, cls) * step(cls, 3.5), blur);
				g += glow_color * lamp * lights * 1.6;
				// the far town's light in the haze over it, up to the horizon
				// far off it becomes the sky's own colour at the horizon, so the two meet without a line
				vec3 sky_edge = mix(horizon + glow_color * glow * 0.5, fog_color, 0.55);
				vec3 haze = mix(fog_color, sky_edge, smoothstep(1500.0, 9000.0, dist));
				col = mix(g, haze, fog_of(dist));
			}
		}

		col += vec3(0.5, 0.55, 0.7) * flash * 0.03;
		COLOR = col * gain;
	}
}
"""
