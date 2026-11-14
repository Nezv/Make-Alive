import * as THREE from 'three';
import { WEAPON_FIRE_INTERVAL, TICK_RATE, generateMap, type ServerMsg } from '@zombie/shared';
import { buildWorld } from './world';
import { FpsController } from './controls';
import { Net } from './net';
import { Hud } from './hud';
import { createRifle } from './models/rifle';
import { createSurvivor, createZombie } from './models/characters';
import type { Rig } from './models/humanoid';
import { gunshot } from './audio';

const renderer = new THREE.WebGLRenderer({ antialias: true });
renderer.setPixelRatio(Math.min(devicePixelRatio, 2));
renderer.setSize(innerWidth, innerHeight);
renderer.shadowMap.enabled = true;
renderer.shadowMap.type = THREE.PCFSoftShadowMap;
document.body.prepend(renderer.domElement);

const scene = new THREE.Scene();
const camera = new THREE.PerspectiveCamera(75, innerWidth / innerHeight, 0.05, 300);
scene.add(camera);
addEventListener('resize', () => {
  camera.aspect = innerWidth / innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(innerWidth, innerHeight);
});

const hud = new Hud();
const rifle = createRifle();
camera.add(rifle.object);

/** A networked character drawn with smoothing between server snapshots. */
interface Remote {
  rig: Rig;
  target: THREE.Vector3;
  targetYaw: number;
  seen: number;
}
const remotes = new Map<string, Remote>();

function upsertRemote(key: string, make: () => Rig, x: number, y: number, z: number, yaw: number, frame: number) {
  let r = remotes.get(key);
  if (!r) {
    const rig = make();
    rig.root.position.set(x, y, z);
    rig.root.rotation.y = yaw;
    scene.add(rig.root);
    r = { rig, target: new THREE.Vector3(), targetYaw: yaw, seen: frame };
    remotes.set(key, r);
  }
  r.target.set(x, y, z);
  r.targetYaw = yaw;
  r.seen = frame;
}

function nameTag(text: string) {
  const c = document.createElement('canvas');
  c.width = 256; c.height = 64;
  const g = c.getContext('2d')!;
  g.font = 'bold 32px system-ui';
  g.textAlign = 'center';
  g.fillStyle = '#000a';
  g.fillRect(0, 8, 256, 48);
  g.fillStyle = '#fff';
  g.fillText(text, 128, 44);
  const s = new THREE.Sprite(new THREE.SpriteMaterial({ map: new THREE.CanvasTexture(c), depthTest: false }));
  s.scale.set(1.2, 0.3, 1);
  s.position.y = 2.2;
  return s;
}

let controller: FpsController | null = null;
let net: Net | null = null;
let myId = '';
let frame = 0;

function onMessage(msg: ServerMsg) {
  switch (msg.t) {
    case 'welcome': {
      myId = msg.id;
      const map = generateMap(msg.seed);
      buildWorld(scene, map, msg.seed);
      controller = new FpsController(camera, renderer.domElement, map.boxes);
      break;
    }
    case 'respawn':
      controller?.teleport(...msg.pos);
      if (msg.reason === 'died') hud.toast('YOU DIED', '#f44');
      if (msg.reason === 'extracted') hud.toast('EXTRACTED!', '#4f8');
      break;
    case 'hit':
      hud.hitMarker();
      break;
    case 'feed':
      hud.pushFeed(msg.text);
      break;
    case 'snapshot': {
      frame++;
      for (const p of msg.players) {
        if (p.id === myId) {
          hud.setHp(p.hp);
          hud.setExtract(p.extract);
          hud.setInfo(msg.players.length, msg.zombies.length, p.kills);
          continue;
        }
        upsertRemote(`p:${p.id}`, () => {
          const rig = createSurvivor(p.id);
          rig.root.add(nameTag(p.name));
          return rig;
        }, p.pos[0], p.pos[1], p.pos[2], p.yaw, frame);
      }
      for (const z of msg.zombies) {
        upsertRemote(`z:${z.id}`, () => createZombie(z.id), z.pos[0], z.pos[1], z.pos[2], z.yaw, frame);
      }
      // Anything not in this snapshot is gone (killed / disconnected).
      for (const [key, r] of remotes) {
        if (r.seen !== frame) { scene.remove(r.rig.root); remotes.delete(key); }
      }
      break;
    }
  }
}

// --- Menu -------------------------------------------------------------------
const overlay = document.getElementById('overlay')!;
const nameInput = document.getElementById('name') as HTMLInputElement;
nameInput.value = localStorage.getItem('name') ?? `Survivor${Math.floor(Math.random() * 900 + 100)}`;

document.getElementById('play')!.addEventListener('click', () => {
  if (!net) {
    localStorage.setItem('name', nameInput.value);
    net = new Net(nameInput.value);
    net.onMessage = onMessage;
    net.onClose = () => {
      overlay.style.display = 'flex';
      overlay.querySelector('p')!.textContent = 'Disconnected from server. Refresh to rejoin.';
    };
    nameInput.style.display = 'none';
    (document.getElementById('play') as HTMLButtonElement).textContent = 'RESUME';
  }
  renderer.domElement.requestPointerLock();
});
document.addEventListener('pointerlockchange', () => {
  overlay.style.display = document.pointerLockElement ? 'none' : 'flex';
});

// --- Loop -------------------------------------------------------------------
const clock = new THREE.Clock();
const tmpDir = new THREE.Vector3();
let sendTimer = 0;
let fireTimer = 0;

function tick() {
  const dt = Math.min(clock.getDelta(), 0.1);

  if (controller && net) {
    controller.update(dt);

    fireTimer -= dt;
    if (controller.firing && fireTimer <= 0) {
      fireTimer = WEAPON_FIRE_INTERVAL;
      rifle.fire();
      gunshot();
      camera.getWorldDirection(tmpDir);
      const o = camera.position;
      net.send({ t: 'shoot', origin: [o.x, o.y, o.z], dir: [tmpDir.x, tmpDir.y, tmpDir.z] });
      controller.pitch += 0.008; // recoil
    }

    sendTimer -= dt;
    if (sendTimer <= 0) {
      sendTimer = 1 / TICK_RATE;
      const p = controller.pos;
      net.send({ t: 'input', pos: [p.x, p.y, p.z], yaw: controller.yaw, pitch: controller.pitch });
    }
  }
  rifle.update(dt, controller?.speed ?? 0);

  const k = 1 - Math.exp(-dt * 12);
  for (const r of remotes.values()) {
    const root = r.rig.root;
    const before = root.position.clone();
    root.position.lerp(r.target, k);
    let dy = r.targetYaw - root.rotation.y;
    dy = Math.atan2(Math.sin(dy), Math.cos(dy)); // shortest turn
    root.rotation.y += dy * k;
    const moved = Math.hypot(root.position.x - before.x, root.position.z - before.z);
    r.rig.update(dt, dt > 0 ? moved / dt : 0);
  }

  renderer.render(scene, camera);
  requestAnimationFrame(tick);
}
tick();
