import type { ZegoInspectFlagType as ZegoWXInspectFlagType, ZegoStreamRelayCDNInfo } from "../../code/zh/ZegoExpressEntity.wechat";
import { StreamInfo, User, ENUM_LOG_LEVEL } from "./zego.entity";
export type wxPublishOption = {
    sourceType?: "CDN" | "BGP";
    streamParams?: string;
    extraInfo?: string;
    roomID?: string;
    inspectFlag?: ZegoWXInspectFlagType;
};
export interface WxListener {
    roomStreamUpdate: (roomID: string, updateType: "DELETE" | "ADD", streamList: StreamInfo[]) => void;
    streamExtraInfoUpdate: (roomID: string, streamList: {
        streamID: string;
        user: User;
        extraInfo: string;
    }[]) => void;
    playerStateUpdate: (result: {
        streamID: string;
        state: "PLAYING" | "NO_PLAY" | "PLAY_REQUESTING";
        errorCode: number;
        extendedData: string;
    }) => void;
    publisherStateUpdate: (result: {
        streamID: string;
        state: "PUBLISHING" | "NO_PUBLISH" | "PUBLISH_REQUESTING";
        errorCode: number;
        extendedData: string;
    }) => void;
    publishQualityUpdate: (streamID: string, publishStats: WxQualityStats) => void;
    playQualityUpdate: (streamID: string, playStats: WxQualityStats) => void;
    mixerRelayCDNStateUpdate: (taskID: string, infoList: Array<ZegoStreamRelayCDNInfo>) => void;
}
export interface WxQualityStats {
    video: {
        videoBitrate: number;
        videoFPS: number;
        videoHeight?: number;
        videoWidth?: number;
    };
    audio: {
        audioBitrate: number;
    };
}
export interface WxConfig {
    nickName?: string;
    logLevel?: ENUM_LOG_LEVEL;
    logUrl?: string;
    remoteLogLevel?: ENUM_LOG_LEVEL;
    debug?: boolean;
    userUpdate?: boolean;
}
export interface WxParams {
    success: Function;
    fail: Function;
    complete: Function;
}
export declare enum ENUM_PLAY_SOURCE_TYPE {
    cdn = 0,
    ultra = 1
}
export declare enum ENUM_SOURCE_TYPE {
    CDN = 0,
    BGP = 1
}
export type wxPlayOption = {
    streamParams?: string;
    isMix?: boolean;
};
export declare enum ENUM_DISPATCH_TYPE {
    cdn = 0,
    ultra = 1,
    customUrl = 2
}
export interface PlayerAttributes {
    id?: string;
    url?: string;
    mode?: "RTC" | "live";
    autoPlay?: boolean;
    muteAudio?: boolean;
    muteVideo?: boolean;
    orientation?: "vertical" | "horizontal";
    objectFit?: "contain" | "fillCrop";
    minCache?: number;
    maxCache?: number;
    soundMode?: "speaker" | "ear";
    enableRecvMessage?: boolean;
    autoPauseIfNavigate?: boolean;
    autoPauseIfOpenNative?: boolean;
}
export interface PusherAttributes {
    id?: string;
    url?: string;
    mode?: "SD" | "HD" | "FHD" | "RTC";
    enableCamera?: boolean;
    enableMic?: boolean;
    enableAgc?: boolean;
    enableAns?: boolean;
    minBitrate?: number;
    maxBitrate?: number;
    frontCamera?: "front" | "back";
    enableZoom?: boolean;
    videoWidth?: number;
    videoHeight?: number;
    beautyLevel?: number;
    beautyStyle?: "smooth" | "nature";
    whitenessLevel?: number;
    videoOrientation?: "vertical" | "horizontal";
    enableRemoteMirror?: boolean;
    localMirror?: "auto" | "enable" | "disable";
    audioQuality?: "low" | "high";
    audioVolumeType?: "media" | "voicecall";
    audioReverbType?: 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7;
    filter?: "standard" | "pink" | "nostalgia" | "blues" | "romantic" | "cool" | "fresher" | "solor" | "aestheticism" | "whitening" | "cerisered";
}
