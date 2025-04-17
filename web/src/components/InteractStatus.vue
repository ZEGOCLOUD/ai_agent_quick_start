<!-- 互动状态组件 -->
<template>
  <div :class="['interact-status']">
    <p class="bot-name">智能体名称：{{ name }}</p>
    <p v-show="status === SignalStatus.Listening">正在听...</p>
    <p v-show="status === SignalStatus.Thinking">正在想...</p>
    <p v-show="status === SignalStatus.Speaking">可以随时说话打断我</p>
  </div>
</template>

<script setup lang="ts">
import { SignalStatus } from '../types/enum';

const props = defineProps<{
  status?: SignalStatus;
  name: string;
}>();

</script>

<style scoped>
.interact-status {
  margin-bottom: 15px;
  text-align: center;
  min-width: 184px;
  padding: 12px 15px;
  background-color: rgba(255, 255, 255, 0.05);
  border-radius: 10px;
  font-size: 14px;
}

.bot-name{
  font-size: 16px !important;
  font-weight: 500;
  margin-bottom: 8px;
}

.interact-status p {
  margin: 0;
  line-height: 1.4;
}
</style>