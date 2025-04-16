<!-- 互动状态组件 -->
<template>
  <div v-if="status" :class="['interact-status']">
    <p class="bot-name">{{ name }}</p>
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
  margin-bottom: 10px;
  text-align: center;
  min-width: 184px;
  padding: 10px;
  background-color: rgba(0, 0, 0, 0.2);
  border-radius: 8px;
}

.bot-name{
  font-size: 18px !important;
  font-weight: 500;
  overflow: hidden;
  white-space: nowrap;
  text-overflow: ellipsis;
  -o-text-overflow:ellipsis;
  width: 50%;
  transform: translate(50%);
}
</style>