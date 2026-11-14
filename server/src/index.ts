import http from 'node:http';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { WebSocketServer } from 'ws';
import { PORT, TICK_RATE, type ClientMsg } from '@zombie/shared';
import { Game, type Player } from './game';

const port = Number(process.env.PORT) || PORT;
const DIST = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../../client/dist');
const MIME: Record<string, string> = {
  '.html': 'text/html', '.js': 'text/javascript', '.css': 'text/css', '.json': 'application/json',
  '.png': 'image/png', '.jpg': 'image/jpeg', '.svg': 'image/svg+xml', '.glb': 'model/gltf-binary',
  '.gltf': 'model/gltf+json', '.mp3': 'audio/mpeg', '.ogg': 'audio/ogg', '.wav': 'audio/wav',
};

// Serves the built client (npm run build) so LAN players only need a browser.
const server = http.createServer((req, res) => {
  const url = decodeURIComponent((req.url ?? '/').split('?')[0]);
  let file = path.join(DIST, url === '/' ? 'index.html' : url);
  if (!file.startsWith(DIST)) { res.writeHead(403).end(); return; }
  if (!fs.existsSync(file) || fs.statSync(file).isDirectory()) file = path.join(DIST, 'index.html');
  if (!fs.existsSync(file)) {
    res.writeHead(503, { 'content-type': 'text/plain' })
      .end('Client not built. Run `npm run build`, or use `npm run dev` and open port 5173.');
    return;
  }
  res.writeHead(200, { 'content-type': MIME[path.extname(file)] ?? 'application/octet-stream' });
  fs.createReadStream(file).pipe(res);
});

const game = new Game();
const wss = new WebSocketServer({ server, path: '/ws' });

wss.on('connection', (ws) => {
  let player: Player | null = null;
  ws.on('message', (raw) => {
    let msg: ClientMsg;
    try { msg = JSON.parse(raw.toString()); } catch { return; }
    if (msg.t === 'hello') {
      if (!player) player = game.join(ws, String(msg.name ?? ''));
      return;
    }
    if (player) game.handle(player, msg);
  });
  ws.on('close', () => { if (player) game.leave(player); });
});

setInterval(() => game.step(1 / TICK_RATE), 1000 / TICK_RATE);

server.listen(port, '0.0.0.0', () => {
  console.log(`Zombie server on port ${port} (map seed ${game.seed})`);
  for (const nets of Object.values(os.networkInterfaces())) {
    for (const n of nets ?? []) {
      if (n.family === 'IPv4' && !n.internal) console.log(`  LAN: http://${n.address}:${port}`);
    }
  }
});
