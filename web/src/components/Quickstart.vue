<template>
  <el-card class="quickstart-container">
    <!-- 步骤导航 -->
    <el-steps
      :active="currentStep"
      finish-status="success"
      align-center
      style="margin-bottom: 30px"
    >
      <el-step
        v-for="(step, index) in steps"
        :key="index"
        :title="step.title"
      ></el-step>
    </el-steps>

    <!-- 步骤内容 -->
    <div class="step-content">
      <!-- 步骤1: 注册智能体 -->
      <div v-if="currentStep === 0" class="step-panel">
        <el-input
          v-model="agentName"
          placeholder="请输入智能体名称"
          clearable
        />
        <el-button
          type="primary"
          @click="registerAgent"
          :loading="isLoading"
          :disabled="!agentName"
        >
          {{ isLoading ? "注册中..." : "注册智能体" }}
        </el-button>
      </div>

      <!-- 步骤2: 创建智能体实例并进入RTC房间 -->
      <div v-if="currentStep === 1" class="step-panel">
        <h2>第二步: 创建智能体实例并进入RTC房间</h2>
        <el-button
          type="primary"
          @click="createInstance"
          :loading="isLoading"
          :disabled="!agentId"
        >
          {{ isLoading ? "创建中..." : "创建实例并进入房间" }}
        </el-button>
      </div>

      <!-- 步骤3: 销毁智能体实例并退出RTC房间 -->
      <div v-show="currentStep === 2" class="step-panel">
        <h2>第三步: 销毁智能体实例并退出RTC房间</h2>
        <!-- 可以开始互动状态 -->
        <div v-show="inInteraction" class="interaction-container">
          <InteractStatus :status="signalStatus" :name="agentName" />
          <ChatMessage :messages="messages" />
        </div>
        <!-- 智能体音频流容器 -->
        <div v-show="false" id="remoteSteamView"></div>
        <el-button
          type="danger"
          @click="deleteInstance"
          :loading="isLoading"
          :disabled="!agentInstanceId"
        >
          {{ isLoading ? "销毁中..." : "销毁实例并退出房间" }}
        </el-button>
      </div>
    </div>
  </el-card>
</template>

<script lang="ts" setup>
import { ref, computed, onMounted } from "vue";
import {
  ElSteps,
  ElStep,
  ElCard,
  ElInput,
  ElButton,
} from "element-plus";
import {
  RegisterAgent,
  CreateAgentInstance,
  DeleteAgentInstance,
  GetZegoToken,
} from "../api/agent";
import type { CreateAgentReq, CreateAgentInstanceReq } from "../types/http";
import config from "../config";
import { ExpressManager } from "../solution/ExpressManager";
import type { ZegoStreamList } from "zego-express-engine-webrtc/sdk/code/zh/ZegoExpressEntity.web";
import type ZegoLocalStream from "zego-express-engine-webrtc/sdk/code/zh/ZegoLocalStream.web";
import InteractStatus from "./InteractStatus.vue";
import ChatMessage from "./ChatMessage.vue";
import { useChat } from "../hooks/useChat";

const zg = ExpressManager.getInstance();
const { signalStatus, messages, setupEventListeners, clearMessages } =
  useChat(zg);
// 步骤定义
const steps = [
  { title: "注册智能体" },
  { title: "创建实例并进入房间" },
  { title: "销毁实例并退出房间" },
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

// 计算属性：是否可以进行下一步
const canProceed = computed(() => {
  switch (currentStep.value) {
    case 0:
      return !!agentId.value;
    case 1:
      return !!agentInstanceId.value;
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

function resetState() {
  agentName.value = "";
  agentId.value = "";
  roomId.value = "";
  localStreamId.value = undefined;
  agentInstanceId.value = "";
  inInteraction.value = false;
  clearMessages();
}

// 步骤1: 注册智能体
async function registerAgent() {
  if (isLoading.value) return;

  isLoading.value = true;
  try {
    const id = "agent_" + Date.now();
    const params: CreateAgentReq = {
      agent_id: id, // 生成一个临时ID
      agent_name: agentName.value,
    };

    const response = await RegisterAgent(params);
    if (response.code === 0) {
      agentId.value = id;
      nextStep();
    } else {
      alert(`注册失败: ${response.message}`);
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
    const agentStreamId = `agentSt_${agentId.value}`;
    const userStreamId = `user_${userId}_${Date.now()}`;
    const { token } = await GetZegoToken({ userId });
    if (!token) {
      alert(`获取token失败`);
      return;
    }
    await zg.loginRoom(roomId.value, token, {
      userID: userId,
      userName: "",
    });
    const params: CreateAgentInstanceReq = {
      room_id: roomId.value,
      agent_id: agentId.value,
      user_id: userId,
      user_stream_id: userStreamId,
      agent_user_id: agentId.value,
      agent_stream_id: agentStreamId,
    };

    const response = await CreateAgentInstance(params);
    if (response.code === 0) {
      // 创建本地音频流
      localStreamId.value = await zg.createAudioStream();
      if (localStreamId.value) {
        // 推本地流
        await zg.startPublishingStream(userStreamId, localStreamId.value);
        // 开始ai降噪
        await zg.enableAiDenoise(localStreamId.value, true);
      }

      agentInstanceId.value = response.agent_instance_id;
      nextStep();
    } else {
      alert(`创建实例失败: ${response.message}`);
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
      agent_instance_id: agentInstanceId.value,
    });

    if (response.code === 0) {
      // 重置状态
      resetState();
      goToStep(0);
    } else {
      alert(`销毁实例失败: ${response.message}`);
    }
  } catch (error) {
    console.error("销毁智能体实例失败:", error);
    alert("销毁智能体实例失败，请查看控制台获取详细信息");
  } finally {
    isLoading.value = false;
  }
}

// 注册事件
const setupEvent = () => {
  setupEventListeners();
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
  width: 800px;
  min-width: 600px;
  max-width: 800px;
  height: 600px;
  min-height: 400px;
  max-height: 800px;
  margin: 40px auto;
  padding: 30px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
  border-radius: 8px;
  overflow: auto;
}

.el-steps {
  margin-bottom: 40px !important;
}

.step-content {
  padding: 10px;
  margin-top: 20px;
  min-height: 300px;
  border: none;
  border-radius: 4px;
  background-color: #f9fafc;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  text-align: center;
}

.step-panel {
  width: 100%;
  max-width: 500px;
  animation: fadeIn 0.5s;
}

.el-form-item {
  margin-bottom: 25px;
}

.el-button {
  margin-top: 15px;
  min-width: 180px;
  padding: 12px 20px;
}

.interaction-container {
  margin-bottom: 30px;
  width: 100%;
  background-color: #f0f2f5;
  border-radius: 8px;
  box-sizing: border-box;
}

h2 {
  margin-bottom: 30px;
  color: #303133;
  font-weight: 500;
  font-size: 1.3em;
}

@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
</style>
