import { ZegoExpressEngine } from "zego-express-engine-webrtc";
import type ZegoLocalStream from "zego-express-engine-webrtc/sdk/code/zh/ZegoLocalStream.web";
import type { ZegoEvent } from "zego-express-engine-webrtc/sdk/code/zh/ZegoExpressEntity.web";
import { logger } from "../utils/logger";
import { ErrorHandler, createError } from "../utils/error-handler";

interface UserConfig {
  userID: string;
  userName: string;
}

export enum ZegoScenario {
  Default = 3,
  StandardVideoCall = 4,
  HighVideoCall = 5,
  StandardChatroom = 6,
  HighQualityChatroom = 7,
  Broadcast = 8,
  UNKNOWN = 100,
}

export enum AiDenoiseMode {
  AI = 0,
  AIBalanced = 1,
  AIAggressive = 2,
}

export class ExpressManager {
  private static instance: ExpressManager;
  public express: ZegoExpressEngine | null = null;
  public roomID = "";

  private constructor() {}

  public static getInstance(): ExpressManager {
    if (!ExpressManager.instance) {
      ExpressManager.instance = new ExpressManager();
    }
    return ExpressManager.instance;
  }

  public async initSDK(appID: number, server: string): Promise<void> {
    try {
      logger.info('SDK', 'ZEGO Express SDK 初始化开始', { appID, server });
      this.express = new ZegoExpressEngine(appID, server, {
        scenario: ZegoScenario.HighQualityChatroom,
      });
      logger.info('SDK', 'ZEGO Express SDK 初始化成功');
    } catch (error) {
      logger.error('SDK', 'ZEGO Express SDK 初始化失败', { appID, server, error });
      throw ErrorHandler.handle(error, 'ExpressManager.initSDK');
    }
  }

  public callExperimentalAPI(params: Record<string, any>) {
    this.express?.callExperimentalAPI(params);
  }

  public on<K extends keyof ZegoEvent>(
    eventName: keyof ZegoEvent,
    callback: ZegoEvent[K]
  ) {
    this.express?.on(eventName, callback);
  }

  public off(eventName: keyof ZegoEvent, callback: VoidFunction) {
    this.express?.off(eventName, callback);
  }

  public getExpress(): ZegoExpressEngine | null {
    return this.express;
  }

  public static getVersion(): string {
    return ZegoExpressEngine.version;
  }

  public async loginRoom(roomID: string, token: string, config: UserConfig) {
    try {
      logger.info('SDK', 'Express SDK 登录房间', { roomID, userConfig: config });
      
      if (!this.express) {
        throw createError.sdk("Express SDK 未初始化", { canRetry: false });
      }
      
      this.roomID = roomID;
      const result = await this.express.loginRoom(roomID, token, config, {
        userUpdate: true,
      });
      
      logger.info('SDK', 'Express SDK 登录房间成功', { roomID, result });
      return result;
    } catch (error) {
      logger.error('SDK', 'Express SDK 登录房间失败', { roomID, error });
      throw ErrorHandler.handle(error, 'ExpressManager.loginRoom');
    }
  }

  public async logoutRoom() {
    try {
      if (!this.express || !this.roomID) {
        logger.warn('SDK', 'Express SDK 实例或房间ID为空，跳过退出房间', { 
          hasExpress: !!this.express, 
          roomID: this.roomID 
        });
        return;
      }
      
      logger.info('SDK', 'Express SDK 退出房间', { roomID: this.roomID });
      this.express.logoutRoom(this.roomID);
      this.roomID = "";
      logger.info('SDK', 'Express SDK 退出房间成功');
    } catch (error) {
      logger.error('SDK', 'Express SDK 退出房间失败', { roomID: this.roomID, error });
      // 退出房间的错误不抛出，只记录日志
      ErrorHandler.updateConfig({ showNotification: false });
      ErrorHandler.handle(error, 'ExpressManager.logoutRoom');
      ErrorHandler.updateConfig({ showNotification: true });
    }
  }

  public createAudioStream() {
    const custom = {
      camera: {
        video: false,
        audio: true,
      },
    };
    return this.express!.createZegoStream(custom);
  }

  public async destroyLocalStream(localStream: ZegoLocalStream) {
    if (this.express) {
      this.express.destroyStream(localStream);
    }
  }

  public startPublishingStream(
    streamID: string,
    LocalStream: ZegoLocalStream | MediaStream
  ): void {
    try {
      if (!this.express) {
        throw createError.sdk("Express SDK 未初始化", { canRetry: false });
      }
      
      logger.info('SDK', 'Express SDK 开始推流', { streamID });
      this.express.startPublishingStream(streamID, LocalStream, {
        enableAutoSwitchVideoCodec: true,
      });
      logger.info('SDK', 'Express SDK 推流启动成功', { streamID });
    } catch (error) {
      logger.error('SDK', 'Express SDK 推流启动失败', { streamID, error });
      throw ErrorHandler.handle(error, 'ExpressManager.startPublishingStream');
    }
  }

  public stopPublishingStream(streamID: string): void {
    if (this.express) {
      this.express.stopPublishingStream(streamID);
    }
  }

  public startPlayingStream(streamID: string) {
    return this.express!.startPlayingStream(streamID);
  }

  public createRemoteStreamView(remoteStream: MediaStream) {
    if (this.express) {
      return this.express.createRemoteStreamView(remoteStream);
    }
  }

  public stopPlayingStream(streamID: string): void {
    if (this.express) {
      this.express.stopPlayingStream(streamID);
    }
  }

  public muteMicrophone(
    localStream: ZegoLocalStream | MediaStream,
    mute: boolean
  ): Promise<void> {
    try {
      if (!localStream) {
        throw createError.sdk("本地流未初始化", { canRetry: false });
      }
      
      if (!this.express) {
        throw createError.sdk("Express SDK 未初始化", { canRetry: false });
      }

      logger.info('SDK', 'Express SDK 麦克风控制', { mute });
      this.express.mutePublishStreamAudio(localStream, mute);
      logger.info('SDK', 'Express SDK 麦克风控制成功', { mute });
      return Promise.resolve();
    } catch (error) {
      logger.error('SDK', 'Express SDK 麦克风控制失败', { mute, error });
      return Promise.reject(ErrorHandler.handle(error, 'ExpressManager.muteMicrophone'));
    }
  }

  async checkSystemRequirements() {
    if (!this.express) {
      return {
        webRTC: false,
        microphone: false,
      };
    }
    const rtc_sup = await this.express.checkSystemRequirements("webRTC");
    const mic_sup = await this.express.checkSystemRequirements("microphone");
    return {
      webRTC: rtc_sup.result,
      microphone: mic_sup.result,
    };
  }

  public destroyStream(localStream: MediaStream | ZegoLocalStream): void {
    if (this.express) {
      this.express.destroyStream(localStream);
    }
  }

  public async getPlayingStreamQuality(streamID: string) {
    return this.express?.getPlayingStreamQuality(streamID);
  }

  public destroyed() {
    this.express?.destroyEngine();
    this.express = null;
  }
}
