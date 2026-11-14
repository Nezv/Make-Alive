// Headless test clients: `npx tsx scripts/bots.ts [count] [host:port]`.
// Each bot joins, wanders, and shoots at the nearest zombie. Useful for testing LAN load and netcode.
import WebSocket from 'ws';
import type { ServerMsg, ZombieState } from '@zombie/shared';

const count = Number(process.argv[2] ?? 2);
const host = process.argv[3] ?? 'localhost:3000';
const duration = Number(process.env.BOT_SECONDS ?? 0); // 0 = run forever

for (let i = 0; i < count; i++) {
  const ws = new WebSocket(`ws://${host}/ws`);
  const name = `Bot${i + 1}`;
  let pos: [number, number, number] = [0, 0, 0];
  let zombies: ZombieState[] = [];
  const stats = { snapshots: 0, hits: 0, kills: 0 };
  ws.on('open', () => ws.send(JSON.stringify({ t: 'hello', name })));
  ws.on('message', (raw) => {
    const m = JSON.parse(raw.toString()) as ServerMsg;
    if (m.t === 'respawn') pos = m.pos;
    if (m.t === 'snapshot') { stats.snapshots++; zombies = m.zombies; }
    if (m.t === 'hit') { stats.hits++; if (m.killed) stats.kills++; }
    if (m.t === 'feed') console.log(`[${name}] feed: ${m.text}`);
  });
  let a = Math.random() * Math.PI * 2;
  const timer = setInterval(() => {
    if (ws.readyState !== WebSocket.OPEN) return;
    a += (Math.random() - 0.5) * 0.3;
    pos = [pos[0] + Math.cos(a) * 0.15, 0, pos[2] + Math.sin(a) * 0.15];
    ws.send(JSON.stringify({ t: 'input', pos, yaw: a, pitch: 0 }));
    const z = zombies[0];
    if (z) {
      const o: [number, number, number] = [pos[0], 1.65, pos[2]];
      const d = [z.pos[0] - o[0], 1.1 - o[1], z.pos[2] - o[2]];
      ws.send(JSON.stringify({ t: 'shoot', origin: o, dir: d }));
    }
  }, 150);
  if (duration) {
    setTimeout(() => {
      clearInterval(timer);
      console.log(`[${name}] snapshots=${stats.snapshots} hits=${stats.hits} kills=${stats.kills}`);
      ws.close();
    }, duration * 1000);
  }
}
