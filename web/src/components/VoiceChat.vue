<template>
  <div class="container">
    <!-- 语音聊天区域 -->
    <div class="voice-chat-section">
      <div class="header">VoiceChat</div>

      <!-- 房间信息区域 -->
      <div class="room-info">
        <div class="room-name">RoomId：{{ roomId }}</div>

        <!-- 用户信息展示区 -->
        <div class="user-info-container">
          <div class="user-info">
            <div class="info-card">
              <div class="info-title">用户信息</div>
              <div class="info-content">
                <div class="info-item">
                  <span class="value">UserId: {{ userId }}</span>
                </div>
              </div>
            </div>
            <div class="info-card">
              <div class="info-title">智能体信息</div>
              <div class="info-content">
                <div class="info-item">
                  <span class="value">AgentUserId: {{ agentUserId }}</span>
                </div>
              </div>
            </div>
          </div>

          <!-- 登录/退出按钮 -->
          <div class="controls-container">
            <el-button
              v-if="!isLogin"
              :loading="loading"
              type="primary"
              class="login-btn"
              @click="handleLogin"
            >
              LoginRoom
            </el-button>
            <el-button
              v-else
              type="danger"
              :loading="loading"
              class="logout-btn"
              @click="handleLogout"
            >
              LogoutRoom
            </el-button>
          </div>
        </div>

        <div class="note">
          注意: <br />
          1.同一个 AppID 内，需保证“userlD”全局唯一，否则会互踢。<br />
          2.请先在服务端创建对应的智能体，并在Call时同步创建智能体实例
        </div>
      </div>

      <!-- 聊天组件区域 -->
      <div class="chat-container">
        <el-collapse v-model="activeCollapse">
          <el-collapse-item title="聊天区域" name="chat">
            <div class="chat-section">
              <ChatMessage :messages="messages" />
            </div>
          </el-collapse-item>
        </el-collapse>
      </div>
    </div>
    <RemoteSteamView />
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref } from "vue";
import ChatMessage from "./ChatMessage.vue";
import RemoteSteamView from "./RemoteSteamView.vue";
import { useChat } from "../hooks/useChat";
import { useRoom } from "../hooks/useRoom";
import { ElMessage } from "element-plus";

const {
  zg,
  isLogin,
  initSDK,
  checkPermission,
  setupEventListeners,
  loginRoom,
  logoutRoom,
} = useRoom();
const {
  messages,
  setupEventListeners: setupChatEventListeners,
  clearMessages,
} = useChat(zg);
// 用户信息
const roomId = ref("room_id_1");
const userId = ref("user_id_1");
const userName = ref("user_name_1");
const agentUserId = ref("agent_user_id_1");
const userStreamId = ref("user_stream_id_1");
// const agentStreamId = ref("agent_stream_id_1");

// 状态管理
const loading = ref(false);
const activeCollapse = ref(["chat"]);

// 处理登录房间
const handleLogin = async () => {
  try {
    loading.value = true;
    await loginRoom(
      roomId.value,
      userId.value,
      userName.value,
      userStreamId.value
    );
  } catch (error: any) {
    console.error("登录失败", error);
    ElMessage.error(error.message || "登录失败");
  } finally {
    loading.value = false;
  }
};

// 处理退出房间
const handleLogout = async () => {
  try {
    loading.value = true;
    await logoutRoom();
  } catch (error: any) {
    console.error("退出失败", error);
    ElMessage.error(error.message || "退出失败");
  } finally {
    clearMessages();
    loading.value = false;
  }
};

onMounted(async () => {
  await initSDK();
  setupEventListeners();
  setupChatEventListeners();
  checkPermission();
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

.voice-chat-section {
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

.header {
  background-color: #e4e7ed;
  padding: 12px 20px;
  font-size: 18px;
  font-weight: 600;
}

.room-info {
  padding: 20px;
}

.room-name {
  font-size: 16px;
  font-weight: 500;
  margin-bottom: 20px;
  color: #303133;
}

.user-info-container {
  display: flex;
  flex-direction: column;
  gap: 20px;
  margin-bottom: 20px;
}

.user-info {
  display: flex;
  gap: 20px;
  width: 100%;
}

.info-card {
  background: #f8f9fa;
  border-radius: 8px;
  padding: 16px;
  flex: 1;
}

.info-title {
  font-size: 14px;
  color: #909399;
  margin-bottom: 12px;
}

.info-content {
  background: white;
  border-radius: 6px;
  padding: 12px;
}

.info-item {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.label {
  color: #909399;
  font-size: 12px;
}

.value {
  color: #303133;
  font-size: 14px;
  font-weight: 500;
}

.controls-container {
  display: flex;
  justify-content: center;
}

.login-btn,
.logout-btn {
  height: 36px;
  min-width: 120px;
}

.note {
  color: #909399;
  font-size: 14px;
  padding: 12px;
  background: #fdf6ec;
  border-radius: 4px;
  margin-top: 20px;
}

.chat-container {
  padding: 0 20px;
}

.chat-section {
  flex: 1;
  border-top: 1px solid #e4e7ed;
  display: flex;
  flex-direction: column;
  height: calc(100vh - 500px);
  overflow: hidden;
}

/* 移动端适配 */
@media screen and (max-width: 768px) {
  .container {
    padding: 0;
  }

  .voice-chat-section {
    border-radius: 8px;
  }

  .room-info {
    padding: 15px;
  }

  .user-info-container {
    gap: 15px;
  }

  .user-info {
    /* flex-direction: column; */
    gap: 15px;
  }

  .info-card {
    width: 100%;
    padding: 12px;
  }

  .info-content {
    padding: 10px;
  }

  .info-item {
    gap: 6px;
  }

  .login-btn,
  .logout-btn {
    width: 100%;
    margin-top: 5px;
  }

  .note {
    font-size: 12px;
    padding: 10px;
    margin-top: 15px;
  }

  .chat-section {
    height: calc(100vh - 460px);
  }
}
</style>
