# Zombie Extraction

A LAN multiplayer zombie extraction FPS. You play it in the browser.

## Play on your LAN
```bash
npm install
npm run build
npm start
```
The server prints `LAN: http://192.168.x.x:3000`. Everyone on the same network opens that URL. They don't install anything.

On Windows, allow Node.js through the firewall on **Private networks** the first time it asks. If friends can't connect, check this first.

## Develop
```bash
npm run dev
```
Then open http://localhost:5173. Edits hot-reload. To test multiplayer alone, run `npx tsx scripts/bots.ts 3`.

Controls: WASD to move, Shift to sprint, Space to jump, hold left mouse to shoot, Esc for the menu.

See [CLAUDE.md](CLAUDE.md) for the architecture and conventions.
