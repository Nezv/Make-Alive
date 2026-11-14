const $ = (id: string) => document.getElementById(id)!;

/** DOM overlay: health, info, kill feed, extraction bar, toasts. */
export class Hud {
  private hp = $('hp');
  private info = $('info');
  private feed = $('feed');
  private extract = $('extract');
  private fill = this.extract.querySelector<HTMLElement>('.fill')!;
  private toastEl = $('toast');
  private damage = $('damage');
  private crosshair = $('crosshair');
  private lastHp = 100;
  private timers: Record<string, number> = {};

  setHp(hp: number) {
    this.hp.textContent = `♥ ${Math.max(0, hp)}`;
    this.hp.style.color = hp > 50 ? '#eee' : hp > 25 ? '#fc6' : '#f55';
    if (hp < this.lastHp) this.flash(this.damage, 'damage', 250);
    this.lastHp = hp;
  }

  setInfo(players: number, zombies: number, kills: number) {
    this.info.innerHTML = `Survivors: ${players}<br>Zombies: ${zombies}<br>Kills: ${kills}`;
  }

  setExtract(progress: number) {
    this.extract.style.display = progress > 0 ? 'block' : 'none';
    this.fill.style.width = `${Math.min(progress, 1) * 100}%`;
  }

  hitMarker() {
    this.crosshair.classList.add('hit');
    clearTimeout(this.timers.hit);
    this.timers.hit = window.setTimeout(() => this.crosshair.classList.remove('hit'), 90);
  }

  pushFeed(text: string) {
    const line = document.createElement('div');
    line.textContent = text;
    this.feed.appendChild(line);
    while (this.feed.children.length > 6) this.feed.firstChild!.remove();
    setTimeout(() => line.remove(), 8000);
  }

  toast(text: string, color = '#fff') {
    this.toastEl.textContent = text;
    this.toastEl.style.color = color;
    this.flash(this.toastEl, 'toast', 2000);
  }

  private flash(el: HTMLElement, key: string, ms: number) {
    el.style.opacity = '1';
    clearTimeout(this.timers[key]);
    this.timers[key] = window.setTimeout(() => (el.style.opacity = '0'), ms);
  }
}
