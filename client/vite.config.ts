import { defineConfig } from 'vite';

// Dev: Vite serves the client on :5173 (LAN-visible) and proxies /ws to the game server.
export default defineConfig({
  server: {
    host: true,
    port: 5173,
    proxy: { '/ws': { target: 'ws://localhost:3000', ws: true } },
  },
  build: { outDir: 'dist', emptyOutDir: true },
});
