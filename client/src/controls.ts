import * as THREE from 'three';
import {
  PLAYER_EYE_HEIGHT, PLAYER_RADIUS, SPRINT_SPEED, WALK_SPEED, pushOut, type Box,
} from '@zombie/shared';

const GRAVITY = 22;
const JUMP_SPEED = 7;
const MOUSE_SENS = 0.0022;

/** Pointer-lock FPS controller. Owns the local player's position and view angles. */
export class FpsController {
  readonly pos = new THREE.Vector3();
  yaw = 0;
  pitch = 0;
  speed = 0; // current ground speed, for weapon bob
  firing = false;
  private velY = 0;
  private keys = new Set<string>();

  constructor(private camera: THREE.PerspectiveCamera, private dom: HTMLElement, private boxes: Box[]) {
    addEventListener('keydown', (e) => this.keys.add(e.code));
    addEventListener('keyup', (e) => this.keys.delete(e.code));
    addEventListener('blur', () => this.keys.clear());
    addEventListener('mousemove', (e) => {
      if (!this.locked) return;
      this.yaw -= e.movementX * MOUSE_SENS;
      this.pitch = THREE.MathUtils.clamp(this.pitch - e.movementY * MOUSE_SENS, -1.5, 1.5);
    });
    addEventListener('mousedown', (e) => { if (e.button === 0 && this.locked) this.firing = true; });
    addEventListener('mouseup', (e) => { if (e.button === 0) this.firing = false; });
    document.addEventListener('pointerlockchange', () => { if (!this.locked) this.firing = false; });
  }

  get locked() {
    return document.pointerLockElement === this.dom;
  }

  lock() {
    this.dom.requestPointerLock();
  }

  teleport(x: number, y: number, z: number) {
    this.pos.set(x, y, z);
    this.velY = 0;
  }

  update(dt: number) {
    let fx = 0, fz = 0;
    if (this.locked) {
      if (this.keys.has('KeyW')) fz += 1;
      if (this.keys.has('KeyS')) fz -= 1;
      if (this.keys.has('KeyD')) fx += 1;
      if (this.keys.has('KeyA')) fx -= 1;
    }
    const len = Math.hypot(fx, fz);
    const speed = len > 0 ? (this.keys.has('ShiftLeft') && fz > 0 ? SPRINT_SPEED : WALK_SPEED) : 0;
    if (len > 0) {
      fx /= len; fz /= len;
      const sin = Math.sin(this.yaw), cos = Math.cos(this.yaw);
      // forward = (-sin, -cos), right = (cos, -sin)
      this.pos.x += (-sin * fz + cos * fx) * speed * dt;
      this.pos.z += (-cos * fz - sin * fx) * speed * dt;
    }
    this.speed = speed;

    const onGround = this.pos.y <= 0;
    if (onGround && this.locked && this.keys.has('Space')) this.velY = JUMP_SPEED;
    this.velY -= GRAVITY * dt;
    this.pos.y = Math.max(0, this.pos.y + this.velY * dt);
    if (this.pos.y === 0) this.velY = Math.max(0, this.velY);

    [this.pos.x, this.pos.z] = pushOut(this.pos.x, this.pos.z, PLAYER_RADIUS, this.boxes);

    this.camera.position.set(this.pos.x, this.pos.y + PLAYER_EYE_HEIGHT, this.pos.z);
    this.camera.rotation.set(this.pitch, this.yaw, 0, 'YXZ');
  }
}
