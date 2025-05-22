import { createRouter, createWebHistory } from 'vue-router'
import VoiceChat from '../views/VoiceChat.vue'
import ImChat from '../views/ImChat.vue'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: '/',
      redirect: '/im-chat'
    },
    {
      path: '/voice-chat',
      name: 'VoiceChat',
      component: VoiceChat
    },
    {
      path: '/im-chat',
      name: 'ImChat',
      component: ImChat
    }
  ]
})

export default router