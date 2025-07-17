import { createApp } from 'vue'
import ElementPlus from 'element-plus'
import 'element-plus/dist/index.css'
import 'normalize.css'
import App from './App.vue'
import router from './router'
// 导入配置检查工具（仅在开发模式下运行）
import './utils/config-checker'

const app = createApp(App)

app.use(ElementPlus)
app.use(router)
app.mount('#app')
