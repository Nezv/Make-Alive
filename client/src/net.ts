import type { ClientMsg, ServerMsg } from '@zombie/shared';

/** WebSocket connection to the game server (same host that served the page, path /ws). */
export class Net {
  private ws: WebSocket;
  onMessage: (msg: ServerMsg) => void = () => {};
  onClose: () => void = () => {};

  constructor(name: string) {
    const proto = location.protocol === 'https:' ? 'wss' : 'ws';
    this.ws = new WebSocket(`${proto}://${location.host}/ws`);
    this.ws.onopen = () => this.send({ t: 'hello', name });
    this.ws.onmessage = (e) => this.onMessage(JSON.parse(e.data) as ServerMsg);
    this.ws.onclose = () => this.onClose();
  }

  send(msg: ClientMsg) {
    if (this.ws.readyState === WebSocket.OPEN) this.ws.send(JSON.stringify(msg));
  }
}
