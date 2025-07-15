import { ref } from "vue";
import { ExpressManager } from "../solution/ExpressManager";
import type ZegoLocalStream from "zego-express-engine-webrtc/sdk/code/zh/ZegoLocalStream.web";
import type { ZegoStreamList } from "zego-express-engine-webrtc/sdk/code/zh/ZegoExpressEntity.web";
import config from "../config";
import { GetZegoToken, Start, StartDigitalHuman, Stop } from "../api/agent";
import type { ZegoRoomStateChangedReason } from "zego-express-engine-webrtc/sdk/code/zh/ZegoExpressEntity.rtm";
import { ErrorHandler, createError } from "../utils/error-handler";
import { logger } from "../utils/logger";

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
    try {
      const { token } = await GetZegoToken({ userId: userID });
      if (!token) {
        throw createError.api("获取 token 失败", { canRetry: true });
      }
      currentToken = token;
      logger.info('ROOM', 'Token 获取成功', { userID });
    } catch (error) {
      logger.error('ROOM', '获取 Token 失败', { userID, error });
      throw ErrorHandler.handle(error, 'useRoom.getToken');
    }
  }

  async function loginRoom(
    type: "normal" | "digitalHuman",
    roomId: string,
    userID: string,
    userName: string,
    userStreamId: string
  ) {
    try {
      logger.info('ROOM', '开始登录房间', { type, roomId, userID });
      
      const login = await zg.loginRoom(roomId, currentToken, {
        userID,
        userName,
      });
      
      if (!login) {
        throw createError.sdk("登录RTC房间失败", { canRetry: true });
      }
      
      await startPublishingStream(userStreamId);
      isLogin.value = true;
      
      logger.info('ROOM', 'RTC房间登录成功', { roomId, userID });
      
      try {
        let res;
        if (type === "digitalHuman") {
          res = await createDigitalHuman(roomId, userID, userStreamId);
          logger.info('ROOM', '数字人创建成功', { roomId, userID });
        } else {
          res = await Start(roomId, userID, userStreamId);
          logger.info('ROOM', 'AI Agent 启动成功', { roomId, userID });
        }
        return res;
      } catch (error: any) {
        logger.error('ROOM', 'AI Agent 服务启动失败', { type, error });
        throw createError.business("并发已满，语音互动启动失败", { 
          canRetry: true,
          context: { type, roomId, userID } 
        });
      }
    } catch (error) {
      logger.error('ROOM', '登录房间失败', { type, roomId, userID, error });
      throw ErrorHandler.handle(error, 'useRoom.loginRoom');
    }
  }

  async function createDigitalHuman(
    roomId: string,
    userID: string,
    userStreamId: string
  ) {
    logger.info('ROOM', '启动数字人服务', { roomId, userID, userStreamId });
    return await StartDigitalHuman(roomId, userID, userStreamId);
  }

  async function startPublishingStream(
    localStreamId: string
  ) {
    try {
      const localStream = await zg.createAudioStream();
      zegoLocalStream.value = localStream;
      logger.info('STREAM', '音频流创建成功', { localStreamId });
      
      // 开始推流
      await zg.startPublishingStream(localStreamId, localStream);
      logger.info('STREAM', '开始推流成功', { localStreamId });
    } catch (error) {
      logger.error('STREAM', '推流失败', { localStreamId, error });
      throw ErrorHandler.handle(error, 'useRoom.startPublishingStream');
    }
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
        logger.webrtc('roomStreamUpdate', { roomID, updateType, streamCount: streamList.length });
        
        if (updateType === "ADD" && streamList.length > 0) {
          try {
            for (const stream of streamList) {
              // 这里调用拉取流的方法，假设方法名为 startPlayingStream
              const mediaStream = await zg.startPlayingStream(stream.streamID);
              remoteView = await zg.createRemoteStreamView(mediaStream);
              if (remoteView) {
                logger.webrtc('remoteView playAudio', { streamID: stream.streamID });
                remoteView.playAudio();  
              }
              logger.info('STREAM', '成功拉取远程流', { streamID: stream.streamID });
              break;
            }
          } catch (error) {
            logger.error('STREAM', '拉取远程流失败', { error });
            ErrorHandler.handle(error, 'useRoom.roomStreamUpdate');
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
        logger.webrtc('remoteCameraStatusUpdate', { streamID, status });
        
        if(status === 'OPEN'){
          if (remoteView) {
            logger.webrtc('remoteView playVideo', { streamID });
            remoteView?.playVideo("remoteSteamView");  
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
        logger.webrtc('roomStateChanged', { roomID, state, errorCode, extendedData });
        
        if (state === "KICKOUT") {
          const kickoutError = createError.business("您已在其他设备登录", {
            code: 'ROOM_KICKOUT',
            severity: 'high'
          });
          ErrorHandler.handle(kickoutError, 'useRoom.roomStateChanged');
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
    try {
      logger.info('ROOM', '开始退出房间', { agentInstanceId });
      
      if (isLogin.value && agentInstanceId) {
        await Stop(agentInstanceId);
        logger.info('ROOM', 'AI Agent 服务停止成功');
      }
      
      await destroy();
      isLogin.value = false;
      
      logger.info('ROOM', '退出房间成功');
    } catch (error) {
      logger.error('ROOM', '退出房间失败', { agentInstanceId, error });
      // 退出房间的错误不阻断操作，只记录日志
      ErrorHandler.updateConfig({ showNotification: false });
      ErrorHandler.handle(error, 'useRoom.logoutRoom');
      ErrorHandler.updateConfig({ showNotification: true });
      
      // 确保状态重置
      isLogin.value = false;
    }
  }

  // 检查设备权限
  async function checkPermission() {
    try {
      const { webRTC, microphone } = await zg.checkSystemRequirements();
      logger.info('PERMISSION', '设备权限检查', { webRTC, microphone });
      
      if (!webRTC || !microphone) {
        const permissionError = createError.permission(
          "系统要求不满足，请检查您的浏览器和麦克风设置", 
          { context: { webRTC, microphone } }
        );
        ErrorHandler.handle(permissionError, 'useRoom.checkPermission');
        permissionValid.value = false;
        return;
      }
      
      permissionValid.value = true;
      logger.info('PERMISSION', '设备权限检查通过');
    } catch (error) {
      logger.error('PERMISSION', '设备权限检查失败', { error });
      ErrorHandler.handle(error, 'useRoom.checkPermission');
      permissionValid.value = false;
    }
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
