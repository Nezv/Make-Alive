import type { WebSocket } from 'ws';
import {
  EXTRACT_TIME, PLAYER_HP, PLAYER_RADIUS, WEAPON_DAMAGE, WEAPON_FIRE_INTERVAL,
  WEAPON_RANGE, ZOMBIE_AGGRO_RANGE, ZOMBIE_ATTACK_COOLDOWN, ZOMBIE_ATTACK_RANGE, ZOMBIE_DAMAGE,
  ZOMBIE_HP, ZOMBIE_MAX, ZOMBIE_RADIUS, ZOMBIE_SPAWN_INTERVAL, ZOMBIE_SPEED, MAP_SIZE,
  generateMap, pushOut, raySphere, rayBox,
  type MapData, type PlayerState, type ServerMsg, type Vec3, type ZombieState, type ClientMsg,
} from '@zombie/shared';

export interface Player extends PlayerState {
  ws: WebSocket;
  ignoreInputUntil: number;
  lastShot: number;
}

interface Zombie extends ZombieState {
  attackCd: number;
  speed: number;
  wander: [number, number];
}

/**
 * Authoritative game state. The server owns zombies, damage, kills and extraction.
 * Player movement is client-reported (fine on a trusted LAN), clamped by collision here.
 */
export class Game {
  readonly seed = (Math.random() * 2 ** 31) | 0;
  readonly map: MapData = generateMap(this.seed);
  private players = new Map<string, Player>();
  private zombies: Zombie[] = [];
  private nextZombieId = 1;
  private nextPlayerId = 1;
  private spawnTimer = 0;
  private now = 0;

  join(ws: WebSocket, name: string): Player {
    const p: Player = {
      id: `p${this.nextPlayerId++}`,
      name: name.trim().slice(0, 20) || 'Survivor',
      ws, pos: [0, 0, 0], yaw: 0, pitch: 0, hp: PLAYER_HP, extract: 0, kills: 0,
      ignoreInputUntil: 0, lastShot: -1,
    };
    this.players.set(p.id, p);
    this.send(p, { t: 'welcome', id: p.id, seed: this.seed });
    this.respawn(p, 'spawn');
    this.broadcast({ t: 'feed', text: `${p.name} joined` });
    return p;
  }

  leave(p: Player) {
    this.players.delete(p.id);
    this.broadcast({ t: 'feed', text: `${p.name} left` });
  }

  handle(p: Player, msg: ClientMsg) {
    if (msg.t === 'input') {
      if (this.now < p.ignoreInputUntil) return;
      const [x, z] = pushOut(msg.pos[0], msg.pos[2], PLAYER_RADIUS, this.map.boxes);
      p.pos = [x, msg.pos[1], z];
      p.yaw = msg.yaw;
      p.pitch = msg.pitch;
    } else if (msg.t === 'shoot') {
      this.shoot(p, msg.origin, msg.dir);
    }
  }

  private shoot(p: Player, origin: Vec3, dir: Vec3) {
    if (this.now - p.lastShot < WEAPON_FIRE_INTERVAL * 0.8) return; // light rate limit
    p.lastShot = this.now;
    const len = Math.hypot(dir[0], dir[1], dir[2]) || 1;
    const d: Vec3 = [dir[0] / len, dir[1] / len, dir[2] / len];

    // Walls block bullets.
    let bestT = WEAPON_RANGE;
    for (const b of this.map.boxes) {
      const t = rayBox(origin, d, b);
      if (t >= 0 && t < bestT) bestT = t;
    }
    let best: Zombie | null = null;
    for (const z of this.zombies) {
      // Two spheres approximate the body: torso and head.
      for (const [y, r] of [[1.1, 0.45], [1.65, 0.25]] as const) {
        const t = raySphere(origin, d, [z.pos[0], y, z.pos[2]], r);
        if (t >= 0 && t < bestT) { bestT = t; best = z; }
      }
    }
    if (!best) return;
    const hit = best;
    hit.hp -= WEAPON_DAMAGE;
    const killed = hit.hp <= 0;
    if (killed) {
      this.zombies = this.zombies.filter((z) => z !== hit);
      p.kills++;
    }
    this.send(p, { t: 'hit', killed });
  }

  private respawn(p: Player, reason: 'spawn' | 'died' | 'extracted') {
    const a = Math.random() * Math.PI * 2;
    const [x, z] = pushOut(
      this.map.spawn.x + Math.cos(a) * 3, this.map.spawn.z + Math.sin(a) * 3,
      PLAYER_RADIUS, this.map.boxes,
    );
    p.pos = [x, 0, z];
    p.hp = PLAYER_HP;
    p.extract = 0;
    p.ignoreInputUntil = this.now + 0.3; // drop in-flight inputs from the old position
    this.send(p, { t: 'respawn', pos: p.pos, reason });
  }

  private spawnZombie() {
    const half = MAP_SIZE / 2 - 2;
    const side = Math.random() * 4;
    const s = (Math.random() * 2 - 1) * half;
    const edge: [number, number] =
      side < 1 ? [s, -half] : side < 2 ? [s, half] : side < 3 ? [-half, s] : [half, s];
    const [x, z] = pushOut(edge[0], edge[1], ZOMBIE_RADIUS, this.map.boxes);
    this.zombies.push({
      id: this.nextZombieId++, pos: [x, 0, z], yaw: 0, hp: ZOMBIE_HP,
      attackCd: 0, speed: ZOMBIE_SPEED * (0.8 + Math.random() * 0.5), wander: [x, z],
    });
  }

  step(dt: number) {
    this.now += dt;
    if (this.players.size === 0) return;

    this.spawnTimer -= dt;
    if (this.spawnTimer <= 0 && this.zombies.length < ZOMBIE_MAX) {
      this.spawnZombie();
      this.spawnTimer = ZOMBIE_SPAWN_INTERVAL;
    }

    const players = [...this.players.values()];
    for (const z of this.zombies) this.stepZombie(z, players, dt);
    this.separateZombies();

    const ex = this.map.extraction;
    for (const p of players) {
      if (p.hp <= 0) {
        this.broadcast({ t: 'feed', text: `${p.name} was eaten` });
        this.respawn(p, 'died');
        continue;
      }
      if (Math.hypot(p.pos[0] - ex.x, p.pos[2] - ex.z) < ex.r) {
        p.extract += dt / EXTRACT_TIME;
        if (p.extract >= 1) {
          this.broadcast({ t: 'feed', text: `${p.name} extracted with ${p.kills} kills!` });
          p.kills = 0;
          this.respawn(p, 'extracted');
        }
      } else {
        p.extract = 0;
      }
    }

    this.broadcast({
      t: 'snapshot',
      players: players.map(({ id, name, pos, yaw, pitch, hp, extract, kills }) =>
        ({ id, name, pos, yaw, pitch, hp, extract, kills })),
      zombies: this.zombies.map(({ id, pos, yaw, hp }) => ({ id, pos, yaw, hp })),
    });
  }

  private stepZombie(z: Zombie, players: Player[], dt: number) {
    z.attackCd -= dt;
    let target: Player | null = null;
    let best = ZOMBIE_AGGRO_RANGE;
    for (const p of players) {
      const d = Math.hypot(p.pos[0] - z.pos[0], p.pos[2] - z.pos[2]);
      if (d < best) { best = d; target = p; }
    }
    let tx: number, tz: number;
    let speed = z.speed;
    if (target) {
      tx = target.pos[0];
      tz = target.pos[2];
    } else {
      if (Math.hypot(z.wander[0] - z.pos[0], z.wander[1] - z.pos[2]) < 1) {
        z.wander = [(Math.random() - 0.5) * MAP_SIZE * 0.8, (Math.random() - 0.5) * MAP_SIZE * 0.8];
      }
      [tx, tz] = z.wander;
      speed *= 0.35;
    }
    const dx = tx - z.pos[0];
    const dz = tz - z.pos[2];
    const dist = Math.hypot(dx, dz);
    if (target && dist < ZOMBIE_ATTACK_RANGE) {
      if (z.attackCd <= 0) {
        target.hp -= ZOMBIE_DAMAGE;
        z.attackCd = ZOMBIE_ATTACK_COOLDOWN;
      }
    } else if (dist > 0.01) {
      z.pos[0] += (dx / dist) * speed * dt;
      z.pos[2] += (dz / dist) * speed * dt;
    }
    if (dist > 0.01) z.yaw = Math.atan2(-dx, -dz); // models face -Z
  }

  /** Keep zombies from stacking, then push them out of walls. */
  private separateZombies() {
    const min = ZOMBIE_RADIUS * 2;
    for (let i = 0; i < this.zombies.length; i++) {
      const a = this.zombies[i];
      for (let j = i + 1; j < this.zombies.length; j++) {
        const b = this.zombies[j];
        const dx = b.pos[0] - a.pos[0];
        const dz = b.pos[2] - a.pos[2];
        const d = Math.hypot(dx, dz);
        if (d > 0.001 && d < min) {
          const push = (min - d) / 2;
          a.pos[0] -= (dx / d) * push; a.pos[2] -= (dz / d) * push;
          b.pos[0] += (dx / d) * push; b.pos[2] += (dz / d) * push;
        }
      }
      [a.pos[0], a.pos[2]] = pushOut(a.pos[0], a.pos[2], ZOMBIE_RADIUS, this.map.boxes);
    }
  }

  private send(p: Player, msg: ServerMsg) {
    if (p.ws.readyState === p.ws.OPEN) p.ws.send(JSON.stringify(msg));
  }

  private broadcast(msg: ServerMsg) {
    const data = JSON.stringify(msg);
    for (const p of this.players.values()) if (p.ws.readyState === p.ws.OPEN) p.ws.send(data);
  }
}
