<template>
  <div class="quickstart-container">
    <!-- 步骤导航 -->
    <div class="steps-container">
      <div
        v-for="(step, index) in steps"
        :key="index"
        :class="[
          'step',
          { active: currentStep === index, completed: currentStep > index },
        ]"
      >
        <div class="step-number">{{ index + 1 }}</div>
        <div class="step-title">{{ step.title }}</div>
      </div>
    </div>

    <!-- 步骤内容 -->
    <div class="step-content">
      <!-- 步骤1: 注册智能体 -->
      <div v-if="currentStep === 0" class="step-panel">
        <h2>第一步: 注册智能体</h2>
        <div class="form-group">
          <label>智能体名称:</label>
          <input
            v-model="agentName"
            type="text"
            placeholder="请输入智能体名称"
          />
        </div>
        <div class="form-actions">
          <button
            @click="registerAgent"
            :disabled="isLoading || !agentName"
            class="primary-button"
          >
            {{ isLoading ? "注册中..." : "注册智能体" }}
          </button>
        </div>
      </div>

      <!-- 步骤2: 创建智能体实例并进入RTC房间 -->
      <div v-if="currentStep === 1" class="step-panel">
        <h2>第二步: 创建智能体实例并进入RTC房间</h2>
        <div class="form-actions">
          <button
            @click="createInstance"
            :disabled="isLoading || !agentId"
            class="primary-button"
          >
            {{ isLoading ? "创建中..." : "创建实例并进入房间" }}
          </button>
        </div>
      </div>

      <!-- 步骤3: 销毁智能体实例并退出RTC房间 -->
      <div v-show="currentStep === 2" class="step-panel">
        <h2>第三步: 销毁智能体实例并退出RTC房间</h2>
        <!-- <p>当前智能体实例ID: {{ agentInstanceId || "未创建实例" }}</p> -->
        <!-- 可以开始互动状态 -->
        <div v-show="inInteraction" class="interaction-tip">
          <InteractStatus :status="signalStatus" :name="agentName" />
          <ChatMessage :messages="messages" />
        </div>
        <!-- 智能体音频流容器 -->
        <div v-show="false" id="remoteSteamView"></div>
        <div class="form-actions">
          <button
            @click="deleteInstance"
            :disabled="isLoading || !agentInstanceId"
            class="primary-button"
          >
            {{ isLoading ? "销毁中..." : "销毁实例并退出房间" }}
          </button>
        </div>
      </div>

      <!-- 步骤4: 销毁智能体 -->
      <div v-if="currentStep === 3" class="step-panel">
        <h2>第四步: 销毁智能体</h2>
        <p>当前智能体ID: {{ agentId || "未创建智能体" }}</p>
        <div class="form-actions">
          <button
            @click="deleteAgent"
            :disabled="isLoading || !agentId"
            class="primary-button"
          >
            {{ isLoading ? "销毁中..." : "销毁智能体" }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
import { ref, computed, onMounted } from "vue";
import {
  RegisterAgent,
  DeleteAgent,
  CreateAgentInstance,
  DeleteAgentInstance,
} from "../api/agent";
import type { CreateAgentReq, CreateAgentInstanceReq } from "../types/http";
import config from "../keycenter";
import { ExpressManager } from "../solution/ExpressManager";
import type { ZegoStreamList } from "zego-express-engine-webrtc/sdk/code/zh/ZegoExpressEntity.web";
import { generateToken } from "../utils/helper";
import type ZegoLocalStream from "zego-express-engine-webrtc/sdk/code/zh/ZegoLocalStream.web";
import InteractStatus from "./InteractStatus.vue";
import ChatMessage from "./ChatMessage.vue";
import { useChat } from "../hooks/useChat";

const zg = ExpressManager.getInstance();
const { signalStatus, messages, setupEventListeners, clearMessages } = useChat(zg);
// 步骤定义
const steps = [
  { title: "注册智能体" },
  { title: "创建实例并进入房间" },
  { title: "销毁实例并退出房间" },
  { title: "销毁智能体" },
];

// 状态管理
const currentStep = ref(0);
const isLoading = ref(false);

// 步骤1: 注册智能体
const agentName = ref("");
const agentId = ref("");

// 步骤2: 创建智能体实例
const roomId = ref("");
const localStreamId = ref<ZegoLocalStream>();
const agentInstanceId = ref("");

// 步骤3: 销毁智能体实例
const inInteraction = ref(false);

// 步骤4: 销毁状态
const instanceDeleted = ref(false);

// 计算属性：是否可以进行下一步
const canProceed = computed(() => {
  switch (currentStep.value) {
    case 0:
      return !!agentId.value;
    case 1:
      return !!agentInstanceId.value;
    case 2:
      return instanceDeleted.value;
    default:
      return true;
  }
});

// 步骤导航
function goToStep(step: number) {
  // 只允许导航到已完成步骤或下一个待完成步骤
  if (
    step <= currentStep.value ||
    (step === currentStep.value + 1 && canProceed.value)
  ) {
    currentStep.value = step;
  }
}

function nextStep() {
  if (currentStep.value < steps.length - 1 && canProceed.value) {
    currentStep.value++;
  }
}

// 步骤1: 注册智能体
async function registerAgent() {
  if (isLoading.value) return;

  isLoading.value = true;
  try {
    const AgentId = "agent_" + Date.now();
    const params: CreateAgentReq = {
      AgentId, // 生成一个临时ID
      AgentConfig: {
        Name: agentName.value,
        LLM: {
          Url: config.llm.url,
          ApiKey: config.llm.key,
          Model: config.llm.model,
          SystemPrompt: `你的名字是${agentName.value}。`,
        },
        TTS: {
          Vendor: config.tts.vendor,
          Params: config.tts.params,
        },
      },
    };

    const response = await RegisterAgent(params);
    if (response.Code === 0) {
      agentId.value = AgentId;
      nextStep();
    } else {
      alert(`注册失败: ${response.Message}`);
    }
  } catch (error) {
    console.error("注册智能体失败:", error);
    alert("注册智能体失败，请查看控制台获取详细信息");
  } finally {
    isLoading.value = false;
  }
}

// 步骤2: 创建智能体实例并进入RTC房间
async function createInstance() {
  if (isLoading.value || !agentId.value) return;

  isLoading.value = true;
  try {
    roomId.value = `room_${Date.now()}`;
    const userId = `user_${Date.now()}`;
    const agentStreamId = `${agentId.value}_${Date.now()}`;
    const userStreamId = `${userId}_${Date.now()}`;
    const token = generateToken(userId, config.appId, config.serverSecret);
    await zg.loginRoom(roomId.value, token, {
      userID: userId,
      userName: "",
    });
    const params: CreateAgentInstanceReq = {
      UserId: userId,
      AgentId: agentId.value,
      RtcInfo: {
        RoomId: roomId.value,
        AgentStreamId: agentStreamId,
        AgentUserId: agentId.value,
        UserStreamId: userStreamId,
      },
    };

    const response = await CreateAgentInstance(params);
    if (response.Code === 0) {
      // 创建本地音频流
      localStreamId.value = await zg.createAudioStream();
      if (localStreamId.value) {
        // 推本地流
        await zg.startPublishingStream(userStreamId, localStreamId.value);
        // 开始ai降噪
        await zg.enableAiDenoise(localStreamId.value, true);
      }

      agentInstanceId.value = response.Data.AgentInstanceId;
      nextStep();
    } else {
      alert(`创建实例失败: ${response.Message}`);
    }
  } catch (error) {
    console.error("创建智能体实例失败:", error);
    alert("创建智能体实例失败，请查看控制台获取详细信息");
  } finally {
    isLoading.value = false;
  }
}

// 步骤3: 销毁智能体实例并退出RTC房间
async function deleteInstance() {
  if (isLoading.value || !agentInstanceId.value) return;

  isLoading.value = true;
  try {
    localStreamId.value && (await zg.destroyLocalStream(localStreamId.value));
    await zg.logoutRoom(roomId.value);
    const response = await DeleteAgentInstance({
      AgentInstanceId: agentInstanceId.value,
    });

    if (response.Code === 0) {
      instanceDeleted.value = true;
      inInteraction.value = false;
      clearMessages()
      nextStep();
    } else {
      alert(`销毁实例失败: ${response.Message}`);
    }
  } catch (error) {
    console.error("销毁智能体实例失败:", error);
    alert("销毁智能体实例失败，请查看控制台获取详细信息");
  } finally {
    isLoading.value = false;
  }
}

// 步骤4: 销毁智能体
async function deleteAgent() {
  if (isLoading.value || !agentId.value) return;

  isLoading.value = true;
  try {
    const response = await DeleteAgent({
      AgentId: agentId.value,
    });

    if (response.Code === 0) {
      // 重置状态
      agentId.value = "";
      agentInstanceId.value = "";
      roomId.value = "";
      goToStep(0);
    } else {
      alert(`销毁智能体失败: ${response.Message}`);
    }
  } catch (error) {
    console.error("销毁智能体失败:", error);
    alert("销毁智能体失败，请查看控制台获取详细信息");
  } finally {
    isLoading.value = false;
  }
}

// 注册事件
const setupEvent = () => {
  setupEventListeners()
  // 监听远端推流事件
  zg.on(
    "roomStreamUpdate",
    async (
      roomID: string,
      updateType: "DELETE" | "ADD",
      streamList: ZegoStreamList[]
    ) => {
      if (updateType === "ADD" && streamList.length > 0) {
        try {
          for (const stream of streamList) {
            // 拉智能体流
            const mediaStream = await zg.startPlayingStream(stream.streamID);
            if (!mediaStream) return;
            const remoteView = await zg.createRemoteStreamView(mediaStream);
            if (remoteView) {
              remoteView.play("remoteSteamView", {
                enableAutoplayDialog: false,
              });
              inInteraction.value = true;
            }
            console.log(`成功拉取流: ${stream.streamID}`);
          }
        } catch (error) {
          console.error("onStreamUpdate", error);
        }
      }
    }
  );
};

// 初始化SDK
const initSDK = async () => {
  zg.initSDK(config.appId, config.server);
  const { webRTC, microphone } = await zg.checkSystemRequirements();
  console.log(webRTC, microphone);
  if (!webRTC || !microphone) {
    alert("系统要求不满足，请检查您的浏览器和麦克风设置。");
    return;
  }
  setupEvent();
};

onMounted(() => {
  initSDK();
});
</script>

<style scoped>
.quickstart-container {
  max-width: 800px;
  margin: 0 auto;
  padding: 20px;
}

h1 {
  text-align: center;
  margin-bottom: 30px;
  color: #333;
}

.steps-container {
  display: flex;
  justify-content: space-between;
  margin-bottom: 30px;
  position: relative;
}

.steps-container::before {
  content: "";
  position: absolute;
  top: 25px;
  left: 0;
  right: 0;
  height: 2px;
  background-color: #e0e0e0;
  z-index: 1;
}

.step {
  display: flex;
  padding: 0 10px;
  flex-direction: column;
  align-items: center;
  position: relative;
  z-index: 2;
  transition: all 0.3s;
}

.step-number {
  width: 50px;
  height: 50px;
  border-radius: 50%;
  background-color: #e0e0e0;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: bold;
  margin-bottom: 10px;
  transition: all 0.3s;
}

.step.active .step-number {
  background-color: #1976d2;
  color: white;
}

.step.completed .step-number {
  background-color: #4caf50;
  color: white;
}

.step-title {
  font-size: 14px;
  text-align: center;
  color: #666;
}

.step.active .step-title,
.step.completed .step-title {
  color: #333;
  font-weight: bold;
}

.step-content {
  background-color: #f9f9f9;
  border-radius: 8px;
  padding: 20px;
  margin-bottom: 20px;
  min-height: 300px;
}

.interaction-tip {
  font-size: 18px;
  font-weight: bold;
}

.step-panel {
  animation: fadeIn 0.5s;
}

.form-group {
  margin-bottom: 15px;
}

label {
  display: block;
  margin-bottom: 5px;
  font-weight: bold;
}

input {
  width: 100%;
  padding: 10px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 16px;
  box-sizing: border-box;
}

.form-actions {
  margin-top: 20px;
}

.primary-button {
  background-color: #1976d2;
  color: white;
  border: none;
  padding: 10px 20px;
  border-radius: 4px;
  cursor: pointer;
  font-size: 16px;
  transition: background-color 0.3s;
}

.primary-button:hover {
  background-color: #1565c0;
}

.primary-button:disabled {
  background-color: #b0bec5;
  cursor: not-allowed;
}

.navigation-buttons {
  display: flex;
  justify-content: space-between;
}

.nav-button {
  background-color: #f5f5f5;
  border: 1px solid #ddd;
  padding: 10px 20px;
  border-radius: 4px;
  cursor: pointer;
  font-size: 16px;
  transition: all 0.3s;
}

.nav-button:hover {
  background-color: #e0e0e0;
}

.nav-button:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.result-box {
  margin-top: 20px;
  padding: 15px;
  background-color: #e8f5e9;
  border-radius: 4px;
  border-left: 4px solid #4caf50;
}

@keyframes fadeIn {
  from {
    opacity: 0;
  }
  to {
    opacity: 1;
  }
}
</style>
