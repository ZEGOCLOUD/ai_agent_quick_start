import { ExpressManager } from "../solution/ExpressManager";
import type ZegoLocalStream from "zego-express-engine-miniprogram/sdk/code/zh/ZegoLocalStream.web";
import type { ZegoStreamList } from "zego-express-engine-miniprogram/sdk/code/zh/ZegoExpressEntity.web";
import config from "../config/config";
import { GetZegoToken, Start, Stop } from "../api/agent";
import type { ZegoRoomStateChangedReason } from "zego-express-engine-miniprogram/sdk/code/zh/ZegoExpressEntity.rtm";
import { ErrorHandler, createError } from "../utils/error-handler";
import { logger } from "../utils/logger";

export function useRoom() {
  const zg = ExpressManager.getInstance();
  let zegoLocalStream : ZegoLocalStream | null = null;
  let isLogin = false;
  let permissionValid = false;
  let currentToken = "";
  let zegoPlayerList: any[] = [];
  let wxContext: any = null;

  async function initSDK(context: any) {
    wxContext = context;
    return zg.initSDK(config.zego.appId, config.zego.server, context);
  }

  async function getToken(userID: string) {
    try {
      const { token } = await GetZegoToken({ userId: userID });
      if (!token) {
        throw createError.api("获取 token 失败", { canRetry: true });
      }
      currentToken = token;
      logger.info('ROOM', 'Token 获取成功', { userID, token });
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
    logger.info('ROOM', '开始登录房间', { type, roomId, userID });
    
    const login = await zg.loginRoom(roomId, currentToken, {
      userID,
      userName,
    });
    
    if (!login) {
      throw createError.sdk("登录RTC房间失败", { canRetry: true });
    }
    
    isLogin = true;
    logger.info('ROOM', 'RTC房间登录成功', { roomId, userID });
    try {
      let res = await Start(roomId, userID, userStreamId);
      logger.info('ROOM', 'AI Agent 启动成功', { roomId, userID });
      return res;
    } catch (error: any) {
      logger.error('ROOM', 'AI Agent 服务启动失败', { type, error });
      throw createError.business("并发已满，语音互动启动失败", { 
        canRetry: true,
        context: { type, roomId, userID } 
      });
    }
  }

  async function startPublishingStream(
    localStreamId: string,
    config?: any
  ) {
    try {
      logger.info('STREAM', '音频流创建成功', { localStreamId });
      // 开始推流
      const zegoPusher = wxContext.selectComponent("#zegoPusher");
      await zg.startPublishingStream(zegoPusher, localStreamId, config);
      logger.info('STREAM', '开始推流成功', { localStreamId });
    } catch (error) {
      logger.error('STREAM', '推流失败', { localStreamId, error });
      throw ErrorHandler.handle(error, 'useRoom.startPublishingStream');
    }
  }
  /**
   * 设置事件监听
   */
  function setupEventListeners() {
    // 流更新监听
    zg.on("roomStreamUpdate", async (
        roomID: string,
        updateType: "DELETE" | "ADD",
        streamList: ZegoStreamList[]
      ) => {
        logger.webrtc('roomStreamUpdate', { roomID, updateType, streamCount: streamList.length });
        if (updateType === "ADD" && streamList.length > 0) {
          try {
            for (const stream of streamList) {
              // 设置 zego-player 组件属性
              const zegoPlayerAttr = {
                componentID: `zego-${stream.streamID}`,
                playerId: stream.streamID
              }
              // 添加到组件列表中
              zegoPlayerList.push(zegoPlayerAttr);
              // 更新，并渲染组件列表
              wxContext.setData({
                zegoPlayerList: zegoPlayerList
              })
              const zegoPlayer = wxContext.selectComponent(`#${zegoPlayerAttr.componentID}`)
              if (!zegoPlayer) return logger.webrtc('未获取到zego-player组件节点', { streamID: stream.streamID });
              // 开始播放
              logger.webrtc("开始拉流", { roomID, streamID: stream.streamID });
              await zg.startPlayingStream(zegoPlayer, stream.streamID);
              logger.info('STREAM', '成功拉取远程流', { streamID: stream.streamID });
            }
          } catch (error) {
            logger.error('STREAM', '拉取远程流失败', { error });
            ErrorHandler.handle(error, 'useRoom.roomStreamUpdate');
          }
        } else {
          // 流删除处理
          for (const stream of streamList) {
            zg.stopPlayingStream(stream.streamID);
            zegoPlayerList = zegoPlayerList.filter((comItem) => stream.streamID !== comItem.playerId)
            wxContext.setData({
              zegoPlayerList: zegoPlayerList
            })
          }
        }
      }
    );
    zg.on("roomStateChanged", (
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
          isLogin = false;
        }
      }
    );
    zg.on("tokenWillExpire", async () => {
      logger.webrtc('tokenWillExpire', 'token将过期，刷新token');
      await getToken(wxContext.data.userId);
      await zg.renewToken(currentToken);
    })
  }

  async function destroy() {
    if (zegoLocalStream) {
      zg.stopPublishingStream();
      zegoLocalStream = null;
    }
    if (zegoPlayerList.length) {
      for (const player of zegoPlayerList) {
        zg.stopPlayingStream(player.playerId);
      }
    }
    await zg.logoutRoom();
  }
  /*
   * 退出房间
   */
  async function logoutRoom(agentInstanceId: string) {
    try {
      logger.info('ROOM', '开始退出房间', { agentInstanceId });
      
      if (isLogin && agentInstanceId) {
        await Stop(agentInstanceId);
        logger.info('ROOM', 'AI Agent 服务停止成功');
      }
      
      await destroy();
      logger.info('ROOM', '退出房间成功');
    } catch (error) {
      logger.error('ROOM', '退出房间失败', { agentInstanceId, error });
      // 退出房间的错误不阻断操作，只记录日志
      ErrorHandler.updateConfig({ showNotification: false });
      ErrorHandler.handle(error, 'useRoom.logoutRoom');
      ErrorHandler.updateConfig({ showNotification: true });
    } finally {
      isLogin = false;
    }
  }

  // 检查设备权限
  async function checkPermission() {
    try {
      const res = await zg.checkSystemRequirements();
      logger.info('PERMISSION', '设备权限检查', res);
      
      if (res.code) {
        if (res.code === 10002) {
          wx.authorize({
            scope: "scope.record",
            success() {
              
            },
            fail() {
              const permissionError = createError.permission(
                "系统要求不满足，请检查您的浏览器和麦克风设置", 
                { code: res.code }
              );
              ErrorHandler.handle(permissionError, 'useRoom.checkPermission');
              permissionValid = false;
              return;
            }
          })
        }
      }
      
      permissionValid = true;
      logger.info('PERMISSION', '设备权限检查通过');
    } catch (error) {
      logger.error('PERMISSION', '设备权限检查失败', { error });
      ErrorHandler.handle(error, 'useRoom.checkPermission');
      permissionValid = false;
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
