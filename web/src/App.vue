<template>
  <div class="app-container">
    <ErrorBoundary @error="handleGlobalError">
      <Chat />
    </ErrorBoundary>
  </div>
</template>

<script setup lang="ts">
import Chat from './components/Chat.vue';
import ErrorBoundary from './components/ErrorBoundary.vue';
import { logger } from './utils/logger';

// 全局错误处理
function handleGlobalError(error: Error, instance: any, errorInfo: string) {
  logger.error('APP', '应用级错误', { error, instance, errorInfo });
}
</script>
<style scoped>
.app-container {
  width: 100%;
  height: 100vh;
  margin: 0 auto;
  padding: 0;
  overflow: hidden;
}
</style>
