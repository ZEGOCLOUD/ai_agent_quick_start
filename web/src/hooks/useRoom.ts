import { ref } from "vue";
import { ExpressManager } from "../solution/ExpressManager";
import type ZegoLocalStream from "zego-express-engine-webrtc/sdk/code/zh/ZegoLocalStream.web";
import type { ZegoStreamList } from "zego-express-engine-webrtc/sdk/code/zh/ZegoExpressEntity.web";
import config from "../config";
import { GetZegoToken, Start, Stop } from "../api/agent";
import { ElMessage } from "element-plus";
import type { ZegoRoomStateChangedReason } from "zego-express-engine-webrtc/sdk/code/zh/ZegoExpressEntity.rtm";

export function useRoom() {
  const zg = ExpressManager.getInstance();
  const zegoLocalStream = ref<ZegoLocalStream | null>();
  const isLogin = ref(false);
  const permissionValid = ref(false);
  const agentInstanceId = ref("")

  async function initSDK() {
    return zg.initSDK(config.zego.appId, config.zego.server);
  }

  async function loginRoom(
    roomId: string,
    userID: string,
    userName: string,
    localStreamId: string
  ) {
    console.log("loginRoom");
    const { token } = await GetZegoToken({ userId: userID });
    if (!token) {
      throw new Error("获取 token 失败");
    }
    const login = await zg.loginRoom(roomId, token, {
      userID,
      userName,
    });
    console.log("loginRoom", isLogin.value);
    if (!login) throw new Error("登录RTC房间失败");
    await startPublishingStream(localStreamId);
    const res = await Start(roomId, userID, localStreamId);
    if (res.code !== 0) {
      destroy();
      throw new Error("登录失败");
    }
    agentInstanceId.value = res.agent_instance_id
    isLogin.value = true;
    return res;
  }

  async function startPublishingStream(
    localStreamId: string
  ) {
    const localStream = await zg.createAudioStream();
    zegoLocalStream.value = localStream;
    console.log("createAudioStream", localStream);
    // 开始推流
    await zg.startPublishingStream(localStreamId, localStream);
  }

  /**
   * 设置事件监听
   */
  function setupEventListeners() {
    // 流更新监听
    zg.on(
      "roomStreamUpdate",
      async (
        roomID: string,
        updateType: "DELETE" | "ADD",
        streamList: ZegoStreamList[]
      ) => {
        console.log("流更新 roomStreamUpdate", updateType, streamList);

        if (updateType === "ADD" && streamList.length > 0) {
          try {
            for (const stream of streamList) {
              // 这里调用拉取流的方法，假设方法名为 startPlayingStream
              const mediaStream = await zg.startPlayingStream(stream.streamID);
              const remoteView = await zg.createRemoteStreamView(mediaStream);
              if (remoteView) {
                remoteView.play("remoteSteamView");
              }
              console.log(`成功拉取流: ${stream.streamID}`);
              break;
            }
          } catch (error) {
            console.error("onStreamUpdate", error);
          }
        }
      }
    );
    zg.on(
      "roomStateChanged",
      (
        roomID: string,
        state: ZegoRoomStateChangedReason,
        errorCode: number,
        extendedData: string
      ) => {
        console.log("roomStateChanged", roomID, state, errorCode, extendedData);
        if (state === "KICKOUT") {
          ElMessage.error("您已在其他设备登录");
          // destroy();
          isLogin.value = false;
        }
      }
    );
  }

  async function destroy() {
    if (zegoLocalStream.value) {
      zg.destroyLocalStream(zegoLocalStream.value);
      zegoLocalStream.value = null;
    }
    console.log('mytag 退出 rtc 房间')
    await zg.logoutRoom();
  }
  /*
   * 退出房间
   */
  async function logoutRoom() {
    isLogin.value && (await Stop(agentInstanceId.value));
    await destroy();
    isLogin.value = false;
    agentInstanceId.value = ""
  }

  // 检查设备权限
  async function checkPermission() {
    const { webRTC, microphone } = await zg.checkSystemRequirements();
    console.log("checkPermission", webRTC, microphone);
    if (!webRTC || !microphone) {
      ElMessage.error("系统要求不满足，请检查您的浏览器和麦克风设置。");
      permissionValid.value = false;
      return;
    }
    permissionValid.value = true;
  }

  return {
    zg,
    isLogin,
    zegoLocalStream,
    initSDK,
    checkPermission,
    startPublishingStream,
    setupEventListeners,
    loginRoom,
    logoutRoom,
  };
}
