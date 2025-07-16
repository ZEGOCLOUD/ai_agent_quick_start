<template>
  <div class="container" v-loading="loading">
    <div class="im-chat">
      <!-- 页面头部 -->
      <PageHeader :title="agentName">
        <template #right>
          <el-button text class="header-btn" @click="handleCall">
            <el-icon><Phone /></el-icon>
          </el-button>
        </template>
      </PageHeader>

      <!-- 聊天消息区域 -->
      <div class="chat-container">
        <ChatMessage :messages="messages" />
      </div>

      <!-- 输入区域 -->
      <div class="input-area">
        <el-input
          v-model="inputMessage"
          placeholder="随便问问..."
          type="text"
          @keyup.enter="handleSendMessage"
        >
          <template #append>
            <el-button @click="handleSendMessage">发送</el-button>
          </template>
        </el-input>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref } from "vue";
import { Phone } from "@element-plus/icons-vue";
import ChatMessage from "@/components/ChatMessage.vue";
import PageHeader from "@/components/PageHeader.vue";
import { useImChat } from "@/hooks/useImChat";
import { ElMessage } from "element-plus";
import { useRouter } from "vue-router";

const router = useRouter();
const { messages, initSDK, login, queryHistoryMessages, sendMessage } = useImChat();

// 生成随机用户信息
const generateRandomUserInfo = () => {
  const timestamp = Date.now().toString().slice(-6);
  const randomSuffix = Math.random().toString(36).substring(2, 6);
  
  return {
    userId: `user_id_${timestamp}_${randomSuffix}`,
    userName: `用户_${timestamp}`,
    roomId: `room_${timestamp}_${randomSuffix}`,
    agentUserId: `agent_user_${timestamp}_${randomSuffix}`,
    userStreamId: `user_stream_${timestamp}_${randomSuffix}`,
  };
};

// 获取或生成用户信息
const getUserInfo = () => {
  try {
    const stored = localStorage.getItem('ai_agent_user_info');
    if (stored) {
      return JSON.parse(stored);
    }
  } catch (error) {
    console.warn('读取用户信息失败:', error);
  }
  
  const newUserInfo = generateRandomUserInfo();
  localStorage.setItem('ai_agent_user_info', JSON.stringify(newUserInfo));
  return newUserInfo;
};

const userInfo = getUserInfo();
const userId = ref(userInfo.userId);
const userName = ref(userInfo.userName);
const agentName = ref("李悦然")
const conversationID = "@RBT#1530_chuyiyun_726988837747";

const inputMessage = ref("");
const loading = ref(false);


const handleSendMessage = async () => {
  if (!inputMessage.value.trim()) return;
  try {
    await sendMessage(inputMessage.value, conversationID);
  } catch (error) {
    ElMessage.error((error as Error).message);
  }
  // 清空输入框
  inputMessage.value = "";
};

const init = async () => {
  try {
    loading.value = true;
    await initSDK();
    await login(userId.value, userName.value);
    await queryHistoryMessages(conversationID);
  } catch (error) {
    console.error(error);
    ElMessage.error("初始化失败");
  } finally {
    loading.value = false;
  }
};

const handleCall = () => {
  // 跳转到语音聊天页面
  router.push({
    path: "/voice-chat",
    query: {
      fromIM: "true",
    },
  });
};

onMounted(() => {
  init();
});
</script>

<style scoped>
.container {
  width: 100%;
  height: 100vh;
  padding: 20px;
  box-sizing: border-box;
  background-color: #f5f7fa;
}

.im-chat {
  max-width: 600px;
  margin: 0 auto;
  display: flex;
  flex-direction: column;
  height: 100%;
  background: white;
  border-radius: 16px;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.1);
  overflow: hidden;
}

.chat-container {
  flex: 1;
  overflow: hidden;
}

.input-area {
  padding: 16px;
  border-top: 1px solid #eee;
  background: #fff;
}

:deep(.el-input-group__append) {
  padding: 0;
}

:deep(.el-input-group__append button) {
  border: none;
  margin: 0;
  height: 32px;
  padding: 0 16px;
}

.header-btn {
  font-size: 20px;
  padding: 8px;
}

@media screen and (max-width: 768px) {
  .container {
    padding: 0;
  }

  .voice-chat-section {
    border-radius: 8px;
  }
}
</style>
