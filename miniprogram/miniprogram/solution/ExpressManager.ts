//@ts-ignore
import { ZegoExpressEngine } from "../libs/zego-express-engine-miniprogram/ZegoExpressMiniProgram-3.11.0";
import type { ZegoEvent } from "zego-express-engine-miniprogram/sdk/code/zh/ZegoExpressEntity.web";
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

  public async initSDK(appID: number, server: string, context: any): Promise<void> {
    try {
      logger.info('SDK', 'ZEGO Express SDK 初始化开始', { appID, server });
      this.express = new ZegoExpressEngine(appID, server);
      this.express.initContext({
        wxContext: context,
        pushAtr: "pusher", // pushAtr 的值必须与下文 <zego-pusher> 中的 pusher 属性值一致
        playAtr: "playerList" // playAtr 的值必须与下文 <zego-player> 中的 playerList 属性值一致
      })
      logger.info('SDK', 'ZEGO Express SDK 初始化成功', {version: this.express.getVersion()});
    } catch (error) {
      logger.error('SDK', 'ZEGO Express SDK 初始化失败', { appID, server, error });
      throw ErrorHandler.handle(error, 'ExpressManager.initSDK');
    }
  }

  public callExperimentalAPI(params: Record<string, any>) {
    // @ts-ignore
    this.express?.callExperimentalAPI(params);
  }

  public on<K extends keyof ZegoEvent>(
    eventName: keyof ZegoEvent,
    callback: ZegoEvent[K]
  ) {
    this.express?.on(eventName, callback);
  }

  public off<K extends keyof ZegoEvent>(eventName: keyof ZegoEvent, callback: ZegoEvent[K]) {
    this.express?.off(eventName, callback);
  }

  public getExpress(): ZegoExpressEngine | null {
    return this.express;
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

  // 开始推流
  public async startPublishingStream(
    pusher: any,
    streamID: string,
    config?: any,
    publishOption?: {sourceType: "CDN" | "BGP", streamParams: string, extraInfo: string, roomID: string},
  ): Promise<void> {
    try {
      if (!this.express) {
        throw createError.sdk("Express SDK 未初始化", { canRetry: false });
      }
      logger.info('SDK', 'Express SDK 开始推流', { streamID });
      await pusher.startPush(this.express, streamID, publishOption, config);
      logger.info('SDK', 'Express SDK 推流启动成功', { streamID });
    } catch (error) {
      logger.error('SDK', 'Express SDK 推流启动失败', { streamID, error });
      throw ErrorHandler.handle(error, 'ExpressManager.startPublishingStream');
    }
  }

  // 停止推流
  public stopPublishingStream(): void {
    if (this.express) {
      this.express.getPusherInstance().stop();
    }
  }

  public async startPlayingStream(player: any, streamID: string) {
    return await player.startPlay(this.express, streamID);
  }

  public stopPlayingStream(streamID: string): void {
    if (this.express) {
      this.express.getPlayerInstance(streamID).stop();
    }
  }

  async checkSystemRequirements() {
    if (!this.express) {
      throw createError.sdk("Express SDK 未初始化", { canRetry: false });
    }
    const res = await this.express.checkSystemRequirements();
    return res;
  }

  public destroyed() {
    this.express?.destroyEngine();
    this.express = null;
  }

  public async renewToken(token: string) {
    if (!this.express) {
      throw createError.sdk("Express SDK 未初始化", { canRetry: false });
    }
    return await this.express.renewToken(token);
  }
}
