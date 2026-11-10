import { defineConfig } from 'vite'
import { tanstackStart } from '@tanstack/react-start/plugin/vite'
import viteReact from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
  plugins: [
    tanstackStart({
      router: { generatedRouteTree: '../routeTree.gen.ts', routeTreeFileHeader: [] },
      prerender: { enabled: true },
      pages: [{ path: '/' }],
    }),
    viteReact(),
    tailwindcss(),
  ],
})
