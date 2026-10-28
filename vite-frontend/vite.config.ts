import path from "path";

import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  define: {
    __DX_FV_BUILD__: JSON.stringify(process.env.DX_FV_BUILD || "development"),
  },
  base: "/",
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
    },
  },
  server: {
    port: 3000,
    host: "0.0.0.0",
  },
  build: {
    outDir: "dist",
    sourcemap: false,
    minify: false,
    rollupOptions: {
      treeshake: false,
    },
  },
});
