// Procedural sound effects (no audio files needed). Swap for samples in client/public/ later.
let ctx: AudioContext | null = null;
let noise: AudioBuffer | null = null;

function audio() {
  if (!ctx) {
    ctx = new AudioContext();
    noise = ctx.createBuffer(1, ctx.sampleRate * 0.3, ctx.sampleRate);
    const d = noise.getChannelData(0);
    for (let i = 0; i < d.length; i++) d[i] = (Math.random() * 2 - 1) * Math.pow(1 - i / d.length, 3);
  }
  return ctx;
}

export function gunshot() {
  const a = audio();
  const src = a.createBufferSource();
  src.buffer = noise;
  const filter = a.createBiquadFilter();
  filter.type = 'lowpass';
  filter.frequency.value = 1800 + Math.random() * 600;
  const gain = a.createGain();
  gain.gain.value = 0.35;
  src.connect(filter).connect(gain).connect(a.destination);
  src.start();
}
