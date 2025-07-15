import { ref } from "vue";
import { ExpressManager } from "../solution/ExpressManager";
import type ZegoLocalStream from "zego-express-engine-webrtc/sdk/code/zh/ZegoLocalStream.web";
import type { ZegoStreamList } from "zego-express-engine-webrtc/sdk/code/zh/ZegoExpressEntity.web";
import config from "../config";
import { GetZegoToken, Start, StartDigitalHuman, Stop } from "../api/agent";
import { ElMessage } from "element-plus";
import type { ZegoRoomStateChangedReason } from "zego-express-engine-webrtc/sdk/code/zh/ZegoExpressEntity.rtm";

export function useRoom() {
  const zg = ExpressManager.getInstance();
  const zegoLocalStream = ref<ZegoLocalStream | null>();
  const isLogin = ref(false);
  const permissionValid = ref(false);
  let currentToken = "";
  async function initSDK() {
    return zg.initSDK(config.zego.appId, config.zego.server);
  }

  async function getToken(userID: string) {
    const { token } = await GetZegoToken({ userId: userID });
    if (!token) {
      throw new Error("获取 token 失败");
    }
    currentToken = token;
  }

  async function loginRoom(
    type: "normal" | "digitalHuman",
    roomId: string,
    userID: string,
    userName: string,
    userStreamId: string
  ) {
    const login = await zg.loginRoom(roomId, currentToken, {
      userID,
      userName,
    });
    console.log("loginRoom", isLogin.value);
    if (!login) throw new Error("登录RTC房间失败");
    await startPublishingStream(userStreamId);
    isLogin.value = true;
    try {
      if (type === "digitalHuman") {
        const res = await createDigitalHuman(roomId, userID, userStreamId);
        console.log("createDigitalHuman", res); 
        return res;
      }else{
        const res = await Start(roomId, userID, userStreamId);
        return res;
      }
    } catch (error: any) {
     throw new Error("并发已满，且语音互动启动失败");
    }
  }

  async function createDigitalHuman(
    roomId: string,
    userID: string,
    userStreamId: string
  ) {
    console.log("StartDigitalHuman");
    return await StartDigitalHuman(roomId, userID, userStreamId);
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
  let remoteView:any = null;
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
        console.log("mytag demo 流更新 roomStreamUpdate", roomID, updateType, streamList);
        if (updateType === "ADD" && streamList.length > 0) {
          try {
            for (const stream of streamList) {
              // 这里调用拉取流的方法，假设方法名为 startPlayingStream
              const mediaStream = await zg.startPlayingStream(stream.streamID);
              remoteView = await zg.createRemoteStreamView(mediaStream);
              if (remoteView) {
                console.log("mytag demo remoteView playAudio");
                remoteView.playAudio();  
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
    // 拉流摄像头状态回调，所拉流的摄像头状态 'OPEN'表示开启 'MUTE'表示关闭
    zg.on(
      "remoteCameraStatusUpdate",
      (
        streamID: string, status: 'OPEN' | 'MUTE'
      ) => {
        console.log("mytag demo remoteCameraStatusUpdate", streamID, status);
        if(status === 'OPEN'){
          if (remoteView) {
            console.log("mytag demo remoteView playVideo");
            remoteView?.playVideo
            ("remoteSteamView");  
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
          destroy();
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
    await zg.logoutRoom();
  }
  /*
   * 退出房间
   */
  async function logoutRoom(agentInstanceId: string) {
    console.log("mytag demo 执行了 logoutRoom");
    isLogin.value && (await Stop(agentInstanceId));
    await destroy();
    isLogin.value = false;
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
    getToken,
  };
}
