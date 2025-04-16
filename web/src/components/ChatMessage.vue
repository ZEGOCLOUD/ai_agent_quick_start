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
  scrollbar-width: 1px;
  scroll-behavior: smooth;
  font-family: "PingFang SC";
  font-size: 14px;
  font-weight: 400;
  line-height: 22px;
  display: flex;
  flex-direction: column;
}

.chat {
  width: 100%;
  height: 300px;
  background-color: rgba(0, 0, 0, 0.2);
  box-sizing: border-box;
}

.chat-title {
  position: -webkit-sticky; /* For Safari */
  position: sticky;
  top: 0;
  z-index: 10;
  height: 50px;
  font-family: "PingFang SC";
  font-weight: 500;
  font-size: 16px;
  line-height: 50px;
  color: #fff;
  background: #1c1f2e; /* 确保背景色与聊天框一致 */
  padding-right: 16px;
  border-bottom: 1px solid #3d4054;
}

.chat-message {
  flex: 1;
  overflow-x: hidden;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  gap: 16px;
  margin: 16px 0;
  animation: bubble-in 0.3s ease-in-out;
}

.message {
  border-radius: 8px;
  width: fit-content;
  max-width: 90%;
  animation: bubble-in 0.2s ease-in-out;
  padding: 10px 12px;
  background-color: #303341;
  color: #fff;
  font-family: "PingFang SC";
  font-size: 15px !important;
  font-style: normal;
  font-weight: 400 !important;
  line-height: 22px !important;
}

.message-content{
  text-align: left;
  max-width: 240px;
  word-break: break-word;
}

.duration {
  display: inline-block;
  padding: 0 6px;
  margin-top: 5px;
  height: 20px;
  flex-shrink: 0;
  border-radius: 4px;
  background: #ffffff0a;
  font-size: 12px;
  font-style: normal;
  font-weight: 400;
  text-align: center;
  color: rgba(255, 255, 255, 0.5);
}

.bot-message {
  align-self: flex-start;
  margin-right: auto;
  background-color: #303341;
  color: #fff;
}
.user-message {
  align-self: flex-end;
  margin-left: auto;
  background: #3478fc;
}

.bottom {
  margin-bottom: 10px;
  display: flex;
}

.send-button {
  margin-left: 10px;
}

@keyframes bubble-in {
  0% {
    transform: scale(0.5);
    opacity: 0.5;
  }
  80% {
    transform: scale(1.05);
    opacity: 1;
  }
  100% {
    transform: scale(1);
  }
}

</style>