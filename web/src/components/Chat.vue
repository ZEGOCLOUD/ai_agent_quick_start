<template>
  <div class="container">
    <!-- 语音聊天区域 -->
    <div class="voice-chat-section">
      <div class="header">Chat</div>

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
          </div>

          <!-- 登录/退出按钮 -->
          <div class="controls-container">
            <el-button
              v-if="!isLogin"
              :loading="loading"
              type="primary"
              class="login-btn"
              @click="handleLogin('normal')"
            >
            Start AI Audio Call
            </el-button>
            <el-button
              v-if="!isLogin"
              :loading="digitalHumanLoading"
              type="primary"
              class="login-btn"
              @click="handleLogin('digitalHuman')">
              Start Digital Human Call
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
      <div class="room-container"> 
        <div class="stream-container">
          <RemoteSteamView />
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
    </div>
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
  getToken
} = useRoom();
const {
  messages,
  setupEventListeners: setupChatEventListeners,
  clearMessages,
} = useChat(zg);
// 用户信息
function randomId(prefix: string) {
  return prefix + Math.random().toString(36).substring(2, 10);
}

const roomId = ref(randomId("room_"));
const userId = ref(randomId("user_"));
const userName = ref(randomId("user_name_"));
const userStreamId = ref(randomId("stream_user_"));



// 状态管理
const loading = ref(false);
const digitalHumanLoading = ref(false);
const activeCollapse = ref(["chat"]);
const isDigitalHuman = ref(false);
let agentInstanceId = ref("");

// 处理登录房间
const handleLogin = async (type: "normal" | "digitalHuman") => {
  try {
    type === "normal" ? (loading.value = true) : (digitalHumanLoading.value = true);
    const res = await loginRoom(
      type,
      roomId.value,
      userId.value,
      userName.value,
      userStreamId.value,
    );
    console.log("mytag demo 执行了 handleLogin",res);
    isDigitalHuman.value = type === "digitalHuman";
    agentInstanceId.value = res.agent_instance_id || "";
  } catch (error: any) {
    console.error("登录失败", error);
    ElMessage.error(error.message || "登录失败");
  } finally {
    type === "normal" ? (loading.value = false) : (digitalHumanLoading.value = false);
  }
};

// 处理退出房间
const handleLogout = async () => {
  try {
    loading.value = true;
    isDigitalHuman.value = false;
    console.log("mytag demo 执行了 handleLogout");
    await logoutRoom(agentInstanceId.value);
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
  await getToken(userId.value);
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
  max-width: 800px;
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
.room-container {
  display: flex;
}
.stream-container {
  padding: 0 0 0 20px;
}

.chat-container {
  padding: 0 20px;
  flex: 1;
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
