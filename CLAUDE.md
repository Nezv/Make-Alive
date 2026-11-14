# Zombie Extraction — LAN multiplayer FPS

Browser 3D FPS. Three.js + TypeScript client, Node WebSocket server, npm workspaces.

## Commands
- `npm run dev` — server (:3000, auto-restart) + Vite client (:5173, hot reload). Open http://localhost:5173. LAN friends use http://<host-ip>:5173.
- `npm run build && npm start` — "release" mode: server serves the built client on :3000. Friends open http://<host-ip>:3000.
- `npm run typecheck` — run after every change.
- `npx tsx scripts/bots.ts 4` — headless bot players for multiplayer testing (`BOT_SECONDS=10` to auto-stop and print stats).

## Layout
- `shared/src/` — code both sides import as `@zombie/shared`
  - `constants.ts` — every gameplay tuning number. Tune here, never inline.
  - `protocol.ts` — `ClientMsg` / `ServerMsg` unions. Adding a message = add it here first, then handle on both sides.
  - `map.ts` — seeded procedural map (server sends the seed, clients rebuild the identical map).
  - `collision.ts` — circle-vs-box push-out and ray tests, used by both client and server.
- `server/src/game.ts` — authoritative sim at `TICK_RATE`: zombie AI, hit detection, damage, extraction, respawn.
- `server/src/index.ts` — HTTP static server for `client/dist` + WebSocket at `/ws`.
- `client/src/main.ts` — renderer, net message handling, snapshot interpolation, game loop.
- `client/src/controls.ts` — pointer-lock FPS movement (local player is client-predicted).
- `client/src/models/` — **all 3D models are code**: `kit.ts` (box/cyl/joint/mat helpers), `humanoid.ts` (jointed rig + walk anim), `characters.ts`, `props.ts`, `rifle.ts`.
- `client/public/` — drop static assets (.glb models, sounds, textures) here; load with `GLTFLoader` from `three/examples/jsm/loaders/GLTFLoader.js`.

## Conventions
- Models: stand on y=0, face **-Z**, 1 unit = 1 m. Yaw 0 looks down -Z; `yaw = atan2(-dx, -dz)`.
- Visual props must fit inside their collision `Box` from `map.ts`.
- Anything random that must match across clients is seeded (`mulberry32`, entity ids).
- Network trust model: LAN/friends. Clients report their own position (server clamps with collision); the server owns zombies, hits, HP, kills and extraction. Don't move game rules to the client.
- Snapshots are full state as JSON at 20 Hz. Fine for ~8 players and ~50 zombies; switch to delta/binary only if profiling says so.

## Gameplay loop (current)
Spawn at center → zombies spawn from map edges and chase the nearest player → shoot them → reach the green beam (a random corner) and stand in it for `EXTRACT_TIME` → "extracted", score resets, respawn. Dying respawns you at center.
