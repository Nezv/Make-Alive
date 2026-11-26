# To verify by a human

Things that are quick for a person to judge by eye or ear and that no test can: looks, sounds, feel.
Open the page: `python tools/verify_page.py` writes `references/verify.html` from this file and the
pictures and sounds on disk (make them first with `tools\shots.ps1` and `tools\sounds.ps1`). Each check
there has OK / Issue buttons and a note; "Copy verdicts" puts them on the clipboard as Markdown to paste
back here or into chat.

## Format (verify_page.py reads it)

- `## name` is a section of the page.
- `- [ ] **id** · title (step) — what to judge` is one check; `[x]` once a person has passed it.
- Indented under a check: `- see: glob, glob` (pictures, `.wav` sounds, `.html` pages to show, paths from
  the project folder), `- ref: glob` (reference photos shown beside them), `- make: command` (how to
  remake what it shows), `- src: glob` (the sources: the page flags a picture older than them as stale),
  `- note: text` (what the person found).
- **Every step that makes something to look at or listen to adds its checks here before it is closed**,
  adds its shots to `tools\shots.ps1` or its sounds to `tools/sound_sheet.gd` when they are not there yet,
  and reruns `python tools/verify_page.py`. A check stays open until a person ticks it.

## Zombies

- [ ] **bodies** · Generic bodies, male and female (S136) — the faces read angry (V brow over sunk sockets, glowing slit eyes, downturned mouth with teeth); proportions and colours match `zombies.png`; female narrower at waist and shoulders; nothing gapes where two pieces meet.
  - see: references/shots/model_body.png, references/shots/model_body_*.png, references/shots/body_faces.png, references/shots/sketch_body.png, references/shots/sketch_face.png
  - ref: references/zombies.png, references/shots/measure_zombies.png
  - make: tools\blender.ps1 tools\models\body.py
  - src: tools/models/body.py, tools/models/poly.py
- [ ] **bodies_posed** · Bodies in the game, still and in poses (S136) — the torso break stays closed in walk and attack; no spikes or inverted faces at shoulders, hips, knees.
  - see: references/shots/body_rack*.png
  - make: tools\shots.ps1 body_rack
  - src: assets/models/zombie_body_*.glb
- [ ] **skeleton** · Skeleton model (S136) — reads as a skeleton at a glance; skull sockets sit behind the eyes; ribs, pelvis and limbs in proportion; nothing pokes out of the male body when fitted.
  - see: references/shots/model_skeleton*.png
  - make: tools\blender.ps1 tools\models\skeleton.py
  - src: tools/models/skeleton.py
- [ ] **outfits** · Nine outfits on both bodies (S137) — each reads as its job at a glance (civilian, worker, nurse, doctor, cop, soldier, firefighter, office, prisoner); no skin poking through cloth; hats sit on the head; colours plain per garment (details come with S139 / S235).
  - see: references/shots/model_outfits.png, references/shots/model_zombie_*_front.png, references/shots/model_zombie_*_three_quarter.png, references/shots/model_zombie_*_back.png
  - make: tools\blender.ps1 tools\models\outfits.py
  - src: tools/models/clothes.py, tools/models/outfits.py
- [ ] **outfits_posed** · Outfits bending in the game's poses (S137) — no pinched or folded cloth at shoulders, elbows, hips and knees in walk, run and attack.
  - see: references/shots/outfit_rack_1.png, references/shots/outfit_rack_2.png, references/shots/outfit_rack_3.png, references/shots/outfit_rack_1_back.png, references/shots/outfit_rack_*_walk.png, references/shots/outfit_rack_*_run.png, references/shots/outfit_rack_*_attack.png, references/shots/sketch_outfit_*.png
  - make: tools\shots.ps1 outfit_rack
  - src: assets/models/zombie_*_m.glb, assets/models/zombie_*_f.glb
- [ ] **stumps** · Severed arm, leg and head on the outfits (S137) — every stump closed by a wound, no see-through holes, bone stub showing.
  - see: references/shots/outfit_rack_*_stumps*.png, references/shots/outfit_rack_1_headless.png
  - make: tools\shots.ps1 stumps
- [ ] **bites** · Ten bite variants on the female nurse (S138) — each hole ragged (not a clean cut) with a blood-dark rim; only that region's bones show; you never see through; the right place on the body (abdomen l/r, ribs, chest, shoulder, upper arm, forearm, thigh, calf, neck).
  - see: references/shots/bites_nurse_f.png, references/shots/bites_nurse_f_game.png, references/shots/bite_rack_*.png, references/shots/bite_zombie_nurse_f_b*_close.png, references/shots/bite_zombie_nurse_f_b*_wide.png
  - make: python tools/models/outfits.py --bites nurse --f
  - src: tools/models/bites.py
- [ ] **zombies_ingame** · Every outfit standing in the corridor, front and back, and the demo line-up — lit well enough to read; eyes glow; the feral leaper on the round body does not look out of place next to the models.
  - see: references/shots/zombie_rack_*.png, references/shots/demo_zombies.png
  - make: tools\shots.ps1 zombie_rack

## Survivors and first person

- [ ] **viewmodel** · First-person gun poses (S034, S015, S016) — aim, sprint carry, reload, inspect, shove, heal and downed read clearly; the gun sits naturally in frame. Known gap: the hands are boxes until S142.
  - see: references/shots/view_*.png
  - make: tools\shots.ps1 view_
- [ ] **guns** · The nine gun models side on (S013) — each recognisable (P19, P90, Type 95, AK47, AS Val, USAS-12, SPAS-12, T-5000, Dragunov); blockouts until the gun-model steps (S143..).
  - see: references/shots/gun_rack.png
  - make: tools\shots.ps1 gun_rack
  - src: scripts/models/guns.gd
- [ ] **survivors** · Other players as you see them (S038) — aiming, reloading on the run, shoving, throwing, healing, down: each pose reads from across a room.
  - see: references/shots/survivor_rack.png
  - make: tools\shots.ps1 survivor_rack
- [ ] **wheel** · Item wheel (S014) — eight wedges, icons readable, the lit one clear, counts visible.
  - see: references/shots/item_wheel.png
  - make: tools\shots.ps1 item_wheel
- [ ] **death** · Death camera, the body and zombies feeding (S017) — the body lies believably, the feeding zombies crouch over it, the spectator camera frames it.
  - see: references/shots/feed_death.png
  - make: tools\shots.ps1 feed_death
  - note: agent, 2026-11-24: at 2.2 s the shot shows the spectator camera on a teammate over plain black, no body or feeding zombies in frame; check in the game whether the camera sits above the corridor's ceiling or the shot is just too early.
- [ ] **heli** · Helicopter landing (S024) — rotor blur, skids on the ground, dust, lights; scale right next to a person.
  - see: references/shots/heli_landing.png
  - make: tools\shots.ps1 heli_landing
  - note: agent, 2026-11-24: the shot catches it still 26 m off down the corridor; judge it in the game with `--heli`.

## Effects

- [ ] **fx** · Every effect looping in a row (S004, S029..S032) — blood, gibs, impacts per surface, muzzle flash, smoke, sparks: each reads as what it is; nothing is a flat white quad.
  - see: references/shots/fx_rack.png
  - make: tools\shots.ps1 fx_rack
  - src: scripts/fx/*.gd

## Elements

- [ ] **hydrant** · The hydrant, last review round (S140) — beside the photos: shape, red paint, wear, the four states.
  - see: references/elements/reviews/hydrant_rfinal.jpg, references/shots/prop_rack_hydrant.png, references/shots/review_hydrant_*.png, references/shots/sketch_hydrant.png
  - ref: references/elements/hydrant/*.jpg
  - make: python tools/models/review.py hydrant --round=final
- [ ] **kit** · The detail kit's board, last round, in every state (S141) — bricks, setts, tiles, plaster, glass, lettering, wear: each sample reads as its material beside the photos; clean, abandoned, damaged and burnt differ clearly.
  - see: references/elements/reviews/kit_r5*.jpg, references/shots/prop_rack_kit.png, references/shots/sketch_kit*.png
  - ref: references/elements/kit/*.jpg
  - make: python tools/models/review.py kit --round=5
- [ ] **window_french** · The French casement, round 2 (S157) — the cast garde-corps (oval, rosette, scrolls, lattice) reads as tall_railing's; pentures and pins on the persiennes, the catch; jet d'eau on the leaves; the sill's drip; persiennes open flat against the wall without passing through it.
  - see: references/elements/reviews/window_french_r2*.*, references/shots/sketch_window_french.png
  - ref: references/elements/window_french/*.jpg
  - make: python tools/models/review.py window_french --round=2
  - src: tools/models/props/windows.py
- [ ] **shopfront** · The shopfront, round 2 (S158) — fluted pilasters with console capitals, the fascia's rosette blocks, the rolled striped store, studded night shutters with hooked bars, letterbox and kick plate, counter and shelves behind the glass; nothing reads as a box.
  - see: references/elements/reviews/shopfront_r2*.*, references/shots/sketch_shopfront.png
  - ref: references/elements/shopfront/*.jpg
  - make: python tools/models/review.py shopfront --round=2
  - src: tools/models/props/shopfronts.py
- [ ] **chimney_stacks** · Chimney stacks, round 2 (S159) — the extension pipes and hats, the cowl, the broken pot, the aerial on the long stack read as pots_antennas and stacks_rows; the render band and rungs.
  - see: references/elements/reviews/chimney_stack*_r2*.*, references/shots/sketch_chimney_stack*.png
  - ref: references/elements/chimney_stack/*.jpg
  - make: python tools/models/review.py chimney_stack_long --round=2
  - src: tools/models/props/roofs.py
- [ ] **dormer** · The zinc dormer, round 2 (S159) — leaves open into the room clear of the frame; standing seams and the cornice's drip on the cap; the jambs' panels; the flashing on the slope.
  - see: references/elements/reviews/dormer_r2*.*, references/shots/sketch_dormer.png
  - ref: references/elements/dormer/*.jpg
  - make: python tools/models/review.py dormer --round=2
  - src: tools/models/props/roofs.py
- [ ] **balcony** · Stone balconies on consoles, round 1 (S159) — the slab's moulding and rounded ends, the consoles' volutes, the railing's hearts read as consoles_front; the long one across three bays; at 50 m the railing still reads as bars.
  - see: references/elements/reviews/balcony*_r1*.*, references/shots/sketch_balcony*.png
  - ref: references/elements/balcony/*.jpg
  - make: python tools/models/review.py balcony --round=1
  - src: tools/models/props/roofs.py
- [ ] **mansard** · The mansard bay, round 1 (S159) — slates in rows with a few missing, the zinc roll at the break, the terrasson's seams, the gutter's lip, the tabatière; slates not a checkerboard; at 80 m the slope still reads as slate.
  - see: references/elements/reviews/mansard_r1*.*, references/shots/sketch_mansard.png
  - ref: references/elements/mansard/*.jpg
  - make: python tools/models/review.py mansard --round=1
  - src: tools/models/props/roofs.py, tools/models/surfaces.py
- [ ] **manholes** · Manhole covers and the gas valve, round 1 (S155) — the round cover in its square frame reads as round_ballu (rings, EAUX / ÉGOUTS the right way round, the studs' checker in the bake); the square one's diamonds; GAZ; the cover pried off beside an open shaft.
  - see: references/elements/reviews/manhole*_r1*.*, references/elements/reviews/valve_cover_r1*.*, references/shots/sketch_manhole*.png
  - ref: references/elements/manhole/*.jpg
  - make: python tools/models/review.py manhole --round=1
  - src: tools/models/props/road.py
- [ ] **lamps** · The candélabre and the wall lantern, round 1 (S166) — the post's sections in louvre's proportions (pedestal, bell, collar, fluted shaft, capital), the lantern's shape; the wall bracket's scrolls; the glass glows warm at night.
  - see: references/elements/reviews/lamp_post_r1*.*, references/elements/reviews/wall_lantern_r1*.*, references/shots/sketch_lamp_post.png, references/shots/sketch_wall_lantern.png
  - ref: references/elements/lamp_post/*.jpg
  - make: python tools/models/review.py lamp_post --round=1
  - src: tools/models/props/lamps.py

## Sounds

- [ ] **world_sounds** · World sounds (S084) — listen to each: doors, barricade, lootbox, pickups, glass, vehicles, UI, generators; each sounds like what it says (the line under each), loops join without a click; they were only checked on the spectrogram sheet, never by ear. Then once in the corridor (doors, lootbox).
  - see: references/shots/sounds/*.wav, references/shots/sounds/sheet.png
  - make: tools\sounds.ps1
  - src: scripts/world_sounds.gd
- [ ] **gun_voices** · Every gun's shot near, far and suppressed, and the three room tails (S033) — each gun distinct (P19 pop, P90 buzzy snap, AK heavier than Type 95, shotguns boom, T-5000 rolls on); far loses the crack; suppressed is a thud.
  - see: references/shots/sounds/game/shot_*.wav, references/shots/sounds/game/tail_*.wav
  - make: tools\sounds.ps1
  - src: scripts/gun_voice.gd
- [ ] **handling** · Reload and handling sounds (S034) — mag release, out, in, slap, bolt, shells, pump, draw, holster, inspect, low-ammo click: metallic, short, not clipped.
  - see: references/shots/sounds/game/h_*.wav, references/shots/sounds/game/low_ammo_click.wav, references/shots/sounds/game/dry_fire.wav
  - make: tools\sounds.ps1
- [ ] **other_sounds** · The engine's own sounds (S005, S015, S030, S031) — whiz, tink, thud, siren, beep, breath, heartbeat, wet sever, the old gunshot.
  - see: references/shots/sounds/game/whiz.wav, references/shots/sounds/game/tink.wav, references/shots/sounds/game/thud.wav, references/shots/sounds/game/siren.wav, references/shots/sounds/game/beep.wav, references/shots/sounds/game/breath.wav, references/shots/sounds/game/heartbeat.wav, references/shots/sounds/game/sever_wet.wav, references/shots/sounds/game/gunshot.wav
  - make: tools\sounds.ps1

## The town

- [ ] **street_plan** · Street network 2, the traced rework (S040, uncommitted) — the streets follow Joinville's (orange over the map), main streets where the bus routes run, junction shapes clean (no slivers or overlaps in the core close-up), the hill road reaches the Mirante.
  - see: references/city_plan.png, references/city_core.png, references/city_on_reference.png, references/streets_on_reference.png
  - ref: references/joinville.png, references/joinville_main_streets.png
  - make: $a = @('--headless','--','--city-plan=C:/Users/Nez/Desktop/GitHub/Make Alive/references'); tools\godot.ps1 @a
  - src: scripts/world/street_net.gd, scripts/world/city_data.gd, scripts/world/city_streets.gd
- [ ] **pois** · The five missions' start and place (placeholders until P06) — you start in a street, the place is in view, nothing floats or sinks into the hill.
  - see: references/shots/*_street.png, references/shots/*_landmark.png
  - make: tools\shots.ps1 _street
- [ ] **sky_presets** · Sky and time of day (S050) — clear, overcast, dusk, night and storm each read at a glance and sit beside their reference photo; clouds look like clouds (no blocks, streaks or ripples); stars are points; no line or seam where the town's geometry ends at 1200 m and the painted backdrop goes on; the hill and the smoke columns stand on the horizon from the roofs.
  - see: references/shots/sky_marche_*.png, references/shots/sky_roofs_*.png, references/shots/sky_hill_*.png, references/elements/reviews/sky_rfinal.jpg
  - ref: references/elements/sky/*.jpg
  - make: python tools/sky_review.py final --missions
  - src: scripts/fx/sky_shader.gd, scripts/fx/sky_dome.gd, scripts/time_of_day.gd
- [ ] **sky_town_below** · The town seen from the Mirante (S050) — by day roofs and streets readable into the haze; at night streets as lines of lamps, the far town glowing up to the horizon; the western ridge only to the west.
  - see: references/shots/sky_hill_*.png
  - ref: references/elements/sky/overcast_montmartre.jpg, references/elements/sky/night_paris.jpg
  - make: python tools/sky_review.py final --view=hill
  - src: scripts/fx/sky_shader.gd
- [ ] **sky_storm** · A lightning strike (S050) — one part of the deck lit from inside, not the whole sky white; the town brightens for a moment. Also play `tools\godot.ps1 -- --host --time=storm` for a minute: strikes every few seconds, the clouds race.
  - see: references/shots/sky_*_storm.png
  - ref: references/elements/sky/storm_night.jpg
  - make: python tools/sky_review.py final
- [ ] **sky_missions** · Each mission's own sky from its start (S050) — terminal dusk, hospital night, prefeitura storm, batalhão overcast, mirante night; nothing in the sky looks wrong behind the placeholder buildings.
  - see: references/shots/sky_start_*.png, references/elements/reviews/sky_rfinal_missions.jpg
  - make: python tools/sky_review.py final --missions
- [ ] **corridor** · The corridor's map data drawn (S002) — zones, closets out of sight, routes reaching the play area.
  - see: references/shots/corridor_zones.png
  - make: tools\shots.ps1 corridor_zones
