<!-- 聊天内容组件 -->
<template>
  <div class="chat">
    <div ref="messageContainer" :class="['chat-message']" @scroll="handleScroll">
      <template v-for="(message, index) in messages" :key="index">
        <!-- Bot messages on the left -->
        <div v-if="message.sender === 'bot'">
          <div class="message bot-message">
            <div class="message-content">{{ message.content }}</div>
          </div>
        </div>

        <!-- User messages on the right -->
        <div v-else class="message user-message">
          <div class="message-content">{{ message.content }}</div>
        </div>
      </template>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUpdated } from 'vue';
import type { Message } from '../hooks/useChat';

const props = withDefaults(
  defineProps<{
    messages: Message[];
  }>(),
  {
    messages: () => [],
  }
)
const emit = defineEmits(["sendMessage"]);

const messageContainer = ref<any>(null);
const isUserScrolling = ref(false);
let scrollTimeout: NodeJS.Timeout | null = null;

const scrollToBottom = () => {
  if (messageContainer.value) {
    messageContainer.value.scrollTop = messageContainer.value.scrollHeight;
  }
};

const handleScroll = () => {
  scrollTimeout && clearTimeout(scrollTimeout);
  
  if (messageContainer.value) {
    const isScrolledToBottom =
      messageContainer.value.scrollHeight - messageContainer.value.scrollTop ===
      messageContainer.value.clientHeight;
    isUserScrolling.value = !isScrolledToBottom;
    
    scrollTimeout = setTimeout(() => {
      isUserScrolling.value = false;
    }, 100);
  }

};

onMounted(scrollToBottom);
onUpdated(scrollToBottom);
</script>

<style scoped>
.chat {
  border-radius: 14px;
  padding: 0 16px;
  overflow: hidden;
  scrollbar-width: thin;
  scrollbar-color: rgba(255, 255, 255, 0.3) transparent;
  scroll-behavior: smooth;
  font-family: "PingFang SC", sans-serif;
  font-size: 14px;
  font-weight: 400;
  line-height: 22px;
  display: flex;
  flex-direction: column;
  width: 100%;
  height: 200px;
  background-color: rgba(255, 255, 255, 0.05);
  box-sizing: border-box;
}

.chat-message {
  flex: 1;
  overflow-x: hidden;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding: 16px 4px;
}

/* Webkit 浏览器滚动条样式 */
.chat-message::-webkit-scrollbar {
  width: 6px;
}

.chat-message::-webkit-scrollbar-track {
  background: transparent;
}

.chat-message::-webkit-scrollbar-thumb {
  background-color: rgba(255, 255, 255, 0.3);
  border-radius: 3px;
}

.message {
  border-radius: 12px;
  width: fit-content;
  max-width: 85%;
  padding: 10px 14px;
  color: #ffffff;
  font-family: "PingFang SC", sans-serif;
  font-size: 14px; 
  font-style: normal;
  font-weight: 400;
  line-height: 20px;
}

.message-content{
  text-align: left;
  word-break: break-word;
}

.bot-message {
  align-self: flex-start;
  margin-right: auto;
  background-color: #424656;
}
.user-message {
  align-self: flex-end;
  margin-left: auto;
  background: #3478fc;
}
</style>