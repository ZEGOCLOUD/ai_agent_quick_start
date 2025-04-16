import { ZegoExpressEngine } from "zego-express-engine-webrtc";
import { VoiceChanger } from "zego-express-engine-webrtc/voice-changer";
import type ZegoLocalStream from "zego-express-engine-webrtc/sdk/code/zh/ZegoLocalStream.web";
import type { ZegoEvent } from "zego-express-engine-webrtc/sdk/code/zh/ZegoExpressEntity.web";

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
  UNKNOWN = 100
}

export enum AiDenoiseMode {
  AI = 0,
  AIBalanced = 1,
  AIAggressive = 2
}

export class ExpressManager {
  private static instance: ExpressManager;
  public express: ZegoExpressEngine | null = null;

  private constructor() {}

  public static getInstance(): ExpressManager {
    if (!ExpressManager.instance) {
      ExpressManager.instance = new ExpressManager();
    }
    return ExpressManager.instance;
  }

  public async initSDK(
    appID: number,
    server: string,
  ): Promise<void> {
    ZegoExpressEngine.use(VoiceChanger);
    this.express = new ZegoExpressEngine(appID, server);
    this.express.setRoomScenario(ZegoScenario.HighQualityChatroom);
  }

  public callExperimentalAPI(params: Record<string, any>) {
    this.express?.callExperimentalAPI(params);
  }

  public on<K extends keyof ZegoEvent>(eventName: keyof ZegoEvent, callback: ZegoEvent[K]) {
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
    console.log("loginRoom", roomID, token, config);

    return await this.express?.loginRoom(roomID, token, config, {
      userUpdate: true,
    });
  }

  public logoutRoom(roomID: string) {
    return this.express?.logoutRoom(roomID);
  }

  // ai 降噪
  public async enableAiDenoise(
    zegoLocalStream: ZegoLocalStream | MediaStream,
    enable: boolean
  ) {
    if (!this.express) {
      return;
    }
    const enableResult = await this.express.enableAiDenoise(zegoLocalStream, enable);
    if (enable && enableResult.errorCode === 0) {
      return this.express?.setAiDenoiseMode(zegoLocalStream, AiDenoiseMode.AIBalanced);
    }
    return enableResult
  }

  public createAudioStream() {
    const custom = {
      camera: {
        video: false,
        audio: true,
      },
    };
    return this.express?.createZegoStream(custom);
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
    if (this.express) {
      console.log("mytag startPublishingStream", streamID, LocalStream);
      this.express.startPublishingStream(streamID, LocalStream);
    }
  }

  public stopPublishingStream(streamID: string): void {
    if (this.express) {
      this.express.stopPublishingStream(streamID);
    }
  }

  public startPlayingStream(streamID: string) {
    if (this.express) {
      return this.express.startPlayingStream(streamID);
    }
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
      if (localStream) {
        console.log("muteMicrophone", mute);

        this.express?.mutePublishStreamAudio(localStream, mute);
        return Promise.resolve();
      }
      throw new Error("Express 或 localStream 未初始化");
    } catch (error) {
      console.error("麦克风控制失败:", error);
      return Promise.reject(error);
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

  public setStreamUpdateHandler(callback: VoidFunction) {
    this.express?.on("roomStreamUpdate", callback);
  }

  public setRoomStateChangedHandler(callback: VoidFunction) {
    this.express?.on("roomStateChanged", callback);
  }

  public async getPlayingStreamQuality(streamID: string) {
    return this.express?.getPlayingStreamQuality(streamID);
  }

  public destroyed() {
    this.express?.destroyEngine();
    this.express = null;
  }
}
