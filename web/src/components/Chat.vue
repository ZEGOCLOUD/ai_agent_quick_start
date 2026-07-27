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
              v-if="!isLogin"
              :loading="liveDigitalHumanLoading"
              type="primary"
              class="login-btn"
              @click="handleLogin('liveDigitalHuman')">
              Start Live Digital Human
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

        <div v-if="isLogin && currentCallType === 'liveDigitalHuman'" class="tts-panel">
          <el-input
            v-model="ttsText"
            class="tts-input"
            type="textarea"
            :rows="3"
            maxlength="300"
            show-word-limit
            placeholder="输入需要播报的文本"
            @keyup.enter.ctrl="handleSendTTS"
          />
          <el-button
            type="primary"
            class="tts-send-btn"
            :loading="ttsSending"
            :disabled="!ttsText.trim() || !agentInstanceId"
            @click="handleSendTTS"
          >
            Send TTS
          </el-button>
        </div>
      </div>
      <div class="room-container">
        <div class="stream-container">
          <!-- Agent 状态展示 -->
          <div v-if="isLogin" class="agent-status">
            <p v-show="status === AgentStatus.IDLE">空闲中...</p>
            <p v-show="status === AgentStatus.Listening">正在听...</p>
            <p v-show="status === AgentStatus.Thinking">正在想...</p>
            <p v-show="status === AgentStatus.Speaking">正在说...</p>
          </div>
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
import { useRoom, type AgentCallType } from "../hooks/useRoom";
import { SendAgentInstanceTTS } from "../api/agent";
import { ErrorHandler } from "../utils/error-handler";
import { logger } from "../utils/logger";
import { AgentStatus } from "../types/enum";

const {
  zg,
  isLogin,
  agentInstanceStatus: status,
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
const liveDigitalHumanLoading = ref(false);
const ttsSending = ref(false);
const ttsText = ref("");
const activeCollapse = ref(["chat"]);
const isDigitalHuman = ref(false);
const currentCallType = ref<AgentCallType | "">("");
let agentInstanceId = ref("");

function setLoginLoading(type: AgentCallType, value: boolean) {
  if (type === "normal") {
    loading.value = value;
  } else if (type === "digitalHuman") {
    digitalHumanLoading.value = value;
  } else {
    liveDigitalHumanLoading.value = value;
  }
}

// 处理登录房间
const handleLogin = async (type: AgentCallType) => {
  try {
    setLoginLoading(type, true);

    logger.userAction('用户开始登录', { type, roomId: roomId.value, userId: userId.value });

    const res = await loginRoom(
      type,
      roomId.value,
      userId.value,
      userName.value,
      userStreamId.value,
    );

    logger.userAction('用户登录成功', {
      type,
      roomId: roomId.value,
      userId: userId.value,
      agentInstanceId: res.agent_instance_id
    });

    isDigitalHuman.value = type === "digitalHuman";
    currentCallType.value = type;
    agentInstanceId.value = res.agent_instance_id || "";
  } catch (error) {
    logger.userAction('用户登录失败', { type, roomId: roomId.value, userId: userId.value, error });
    ErrorHandler.handle(error, 'Chat.handleLogin');
  } finally {
    setLoginLoading(type, false);
  }
};

// 处理退出房间
const handleLogout = async () => {
  try {
    loading.value = true;
    isDigitalHuman.value = false;
    currentCallType.value = "";
    ttsText.value = "";

    logger.userAction('用户开始退出房间', {
      roomId: roomId.value,
      userId: userId.value,
      agentInstanceId: agentInstanceId.value
    });

    await logoutRoom(agentInstanceId.value);

    logger.userAction('用户退出房间成功', {
      roomId: roomId.value,
      userId: userId.value
    });
  } catch (error) {
    logger.userAction('用户退出房间失败', {
      roomId: roomId.value,
      userId: userId.value,
      error
    });
    ErrorHandler.handle(error, 'Chat.handleLogout');
  } finally {
    clearMessages();
    loading.value = false;
  }
};

const handleSendTTS = async () => {
  const text = ttsText.value.trim();
  if (!text || !agentInstanceId.value) {
    return;
  }

  try {
    ttsSending.value = true;
    logger.userAction('用户发送播报数字人 TTS', {
      roomId: roomId.value,
      agentInstanceId: agentInstanceId.value,
      textLength: text.length,
    });

    const result = await SendAgentInstanceTTS({
      agentInstanceId: agentInstanceId.value,
      text,
    });

    ttsText.value = "";
    logger.userAction('播报数字人 TTS 发送成功', {
      roomId: roomId.value,
      agentInstanceId: agentInstanceId.value,
      requestId: result.request_id,
      round: result.round,
    });
  } catch (error) {
    logger.userAction('播报数字人 TTS 发送失败', {
      roomId: roomId.value,
      agentInstanceId: agentInstanceId.value,
      error,
    });
    ErrorHandler.handle(error, 'Chat.handleSendTTS');
  } finally {
    ttsSending.value = false;
  }
};

onMounted(async () => {
  try {
    logger.info('COMPONENT', 'Chat 组件初始化开始', {
      roomId: roomId.value,
      userId: userId.value
    });

    await initSDK();
    setupEventListeners();
    setupChatEventListeners();
    checkPermission();
    await getToken(userId.value);

    logger.info('COMPONENT', 'Chat 组件初始化完成', {
      roomId: roomId.value,
      userId: userId.value
    });
  } catch (error) {
    logger.error('COMPONENT', 'Chat 组件初始化失败', {
      roomId: roomId.value,
      userId: userId.value,
      error
    });
    ErrorHandler.handle(error, 'Chat.onMounted');
  }
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

.agent-status {
  margin-bottom: 16px;
  padding: 10px 14px;
  background: #ecf5ff;
  border-left: 3px solid #409eff;
  border-radius: 4px;
  font-size: 14px;
  color: #303133;
}

.agent-status p {
  margin: 0;
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
  gap: 12px;
  flex-wrap: wrap;
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

.tts-panel {
  display: flex;
  gap: 12px;
  align-items: flex-end;
  margin-top: 16px;
}

.tts-input {
  flex: 1;
}

.tts-send-btn {
  min-width: 96px;
  height: 36px;
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

  .tts-panel {
    flex-direction: column;
    align-items: stretch;
  }

  .tts-send-btn {
    width: 100%;
  }

  .chat-section {
    height: calc(100vh - 460px);
  }
}
</style>
