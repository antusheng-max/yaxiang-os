import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

// https://vite.dev/config/
export default defineConfig({
  plugins: [vue()],
  define: {
    // 生产构建时替换环境变量
    'import.meta.env.VITE_APP_MODE': JSON.stringify(process.env.VITE_APP_MODE || 'mock'),
    'import.meta.env.VITE_ADAPTER_MODE': JSON.stringify(process.env.VITE_ADAPTER_MODE || 'mock'),
  },
  build: {
    // 生产构建不生成source map
    sourcemap: false,
    // echarts 体积较大，原型阶段保留单包；调高阈值避免噪音告警
    chunkSizeWarningLimit: 1500,
    rollupOptions: {
      output: {
        manualChunks: {
          vue: ['vue', 'vue-router'],
          'element-plus': ['element-plus', '@element-plus/icons-vue'],
          echarts: ['echarts'],
        },
      },
    },
  },
})
