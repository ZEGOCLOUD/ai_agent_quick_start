<template>
  <div v-if="!hasError">
    <slot />
  </div>
  <div v-else class="error-boundary">
    <div class="error-container">
      <div class="error-icon">⚠️</div>
      <h2 class="error-title">出现了一些问题</h2>
      <p class="error-message">{{ errorMessage }}</p>
      
      <div class="error-actions">
        <button @click="handleRetry" class="retry-btn">重试</button>
        <button @click="handleRefresh" class="refresh-btn">刷新页面</button>
        <button @click="handleReset" class="reset-btn">重置应用</button>
      </div>
      
      <details v-if="isDevelopment && errorDetails" class="error-details">
        <summary>错误详情（开发模式）</summary>
        <pre>{{ errorDetails }}</pre>
      </details>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import { ErrorHandler } from '../utils/error-handler'
import { logger } from '../utils/logger'

const hasError = ref(false)
const errorMessage = ref('应用遇到了意外错误，请稍后重试')
const errorDetails = ref('')
const isDevelopment = ref(import.meta.env.MODE === 'development')

// 错误处理函数
const handleError = (error: Error, errorInfo?: any) => {
  hasError.value = true
  errorMessage.value = error.message || '应用遇到了意外错误，请稍后重试'
  
  if (isDevelopment.value) {
    errorDetails.value = `
错误: ${error.message}
堆栈: ${error.stack}
信息: ${errorInfo ? JSON.stringify(errorInfo, null, 2) : '无'}
    `.trim()
  }
  
  // 使用统一错误处理器
  ErrorHandler.handle(error, {
    context: 'ErrorBoundary',
    showNotification: false, // 错误边界已经显示UI，不需要额外通知
    logError: true
  })
}

// 重试操作
const handleRetry = () => {
  hasError.value = false
  errorMessage.value = ''
  errorDetails.value = ''
  logger.info('ErrorBoundary', '用户触发错误边界重试')
}

// 刷新页面
const handleRefresh = () => {
  logger.info('ErrorBoundary', '用户触发页面刷新')
  window.location.reload()
}

// 重置应用
const handleReset = () => {
  logger.info('ErrorBoundary', '用户触发应用重置')
  // 清除本地存储
  localStorage.clear()
  sessionStorage.clear()
  // 刷新页面
  window.location.reload()
}

// 全局错误监听
const handleGlobalError = (event: ErrorEvent) => {
  handleError(new Error(event.message), {
    filename: event.filename,
    lineno: event.lineno,
    colno: event.colno
  })
}

const handleUnhandledRejection = (event: PromiseRejectionEvent) => {
  handleError(new Error(`未处理的Promise拒绝: ${event.reason}`), {
    reason: event.reason
  })
}

// 组件挂载时添加全局错误监听
onMounted(() => {
  window.addEventListener('error', handleGlobalError)
  window.addEventListener('unhandledrejection', handleUnhandledRejection)
})

// 组件卸载时移除监听器
onUnmounted(() => {
  window.removeEventListener('error', handleGlobalError)
  window.removeEventListener('unhandledrejection', handleUnhandledRejection)
})

// Vue 3 的错误处理
import { getCurrentInstance } from 'vue'

const instance = getCurrentInstance()
if (instance?.appContext?.app) {
  instance.appContext.app.config.errorHandler = (error: Error, vm: any, info: string) => {
    handleError(error, { component: vm?.$options?.name || 'Unknown', info })
  }
}
</script>

<style scoped>
.error-boundary {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 400px;
  padding: 2rem;
  background-color: #f8f9fa;
}

.error-container {
  max-width: 500px;
  text-align: center;
  background: white;
  border-radius: 8px;
  padding: 2rem;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
}

.error-icon {
  font-size: 3rem;
  margin-bottom: 1rem;
}

.error-title {
  color: #e74c3c;
  margin-bottom: 1rem;
  font-size: 1.5rem;
}

.error-message {
  color: #666;
  margin-bottom: 2rem;
  line-height: 1.5;
}

.error-actions {
  display: flex;
  gap: 1rem;
  justify-content: center;
  flex-wrap: wrap;
}

.retry-btn,
.refresh-btn,
.reset-btn {
  padding: 0.5rem 1rem;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 0.9rem;
  transition: background-color 0.2s;
}

.retry-btn {
  background-color: #3498db;
  color: white;
}

.retry-btn:hover {
  background-color: #2980b9;
}

.refresh-btn {
  background-color: #95a5a6;
  color: white;
}

.refresh-btn:hover {
  background-color: #7f8c8d;
}

.reset-btn {
  background-color: #e74c3c;
  color: white;
}

.reset-btn:hover {
  background-color: #c0392b;
}

.error-details {
  margin-top: 2rem;
  text-align: left;
}

.error-details summary {
  cursor: pointer;
  color: #666;
  margin-bottom: 0.5rem;
}

.error-details pre {
  background-color: #f8f9fa;
  padding: 1rem;
  border-radius: 4px;
  overflow-x: auto;
  font-size: 0.8rem;
  color: #333;
}
</style> 