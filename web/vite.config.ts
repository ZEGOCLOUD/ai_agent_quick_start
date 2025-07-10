import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import basicSsl from "@vitejs/plugin-basic-ssl";
import { resolve } from 'path'

// https://vite.dev/config/
export default defineConfig({
  plugins: [vue(), basicSsl(),],
  server: {
    host: true,
  },
  resolve: {
    alias: {
      '@': resolve(__dirname, 'src')
    }
  }
})
