/// <reference types="node" />
import type { StreamHandler } from "./streamHandler";
export declare const PROTO_VERSION: any;
export declare const ROOMVERSION: any;
export declare const BUILD_TIME: any;
export declare enum ENUM_LOG_LEVEL {
    debug = 0,
    info = 1,
    warn = 2,
    error = 3,
    report = 99,
    disable = 100
}
export declare const LOG_LEVEL: {
    debug: number;
    info: number;
    warn: number;
    error: number;
    report: number;
    disable: number;
};
export declare enum ENUM_REMOTE_TYPE {
    disable = 0,
    websocket = 1,
    https = 2
}
export interface LogConfig {
    logLevel?: "debug" | "info" | "warn" | "error" | "report" | "disable";
    logURL?: string;
    remoteLogLevel?: "debug" | "info" | "warn" | "error" | "report" | "disable";
}
export interface User {
    userID: string;
    userName: string;
}
export interface RoomConfig {
    maxMemberCount?: number;
    userUpdate?: boolean;
}
export declare enum SDKProjectType {
    SDKProject_ZegoWebRTC = 6,
    SDKProject_ZegoMiniProgram = 7
}
export declare const enum ENUM_PUBLISH_STATE {
    start = 0,
    waitingSessionRsp = 1,
    waitingOfferRsp = 2,
    waitingServerAnswer = 3,
    waitingServerICE = 4,
    connecting = 5,
    publishing = 6,
    stop = 7
}
export declare const enum ENUM_PLAY_STATE {
    start = 0,
    waitingSessionRsp = 1,
    waitingOfferRsp = 2,
    waitingServerAnswer = 3,
    waitingServerICE = 4,
    connecting = 5,
    playing = 6,
    stop = 7
}
export declare const enum ENUM_PLAYER_STATE {
    start = 0,
    playing = 1,
    stop = 2
}
export declare enum ProtocolType {
    UDP = 0,
    RTMP = 1,
    FLV = 2,
    HLS = 3,
    WEBRTC = 4
}
export declare const ENUM_CONNECT_STATE: {
    disconnect: number;
    connecting: number;
    connected: number;
};
export declare const REPORT_ACTION: {
    eventStart: string;
    eventEndWithMsgInfo: string;
    addEventMsg: string;
    addEvent: string;
    eventEnd: string;
    addMsgInfo: string;
};
export declare const SEND_MSG_TIMEOUT = 1;
export declare const SEND_MSG_RESET = 2;
export declare const SEND_MSG_FAILED = 3;
export declare const MAX_TRY_CONNECT_COUNT = 3;
export declare const MAX_TRY_HEARTBEAT_COUNT = 5;
export declare const MAX_STREAM_ID_LENGTH = 256;
export declare const MAX_USER_ID_LENGTH = 64;
export declare const MAX_USER_NAME_LENGTH = 256;
export declare const MAX_ROOM_ID_LENGTH = 128;
export declare const MAX_MESSAGE_LENGTH = 1024;
export declare const MAX_MIX_TASK_ID_LENGTH = 256;
export declare const MAX_TRANS_TYPE_LENGTH = 128;
export declare const MAX_TRANS_DATA_LENGTH: number;
export declare const MAX_RETRY_CONNECT_INTERVAL = 12;
export declare const MIN_QUALITY_INTERVAL = 1000;
export declare const MIN_MAX_CHANNELS = 1;
export declare const MAX_MAX_CHANNELS = 50;
export declare const MIN_MAX_RETRY_TIME = 1;
export declare const MAX_MAX_RETRY_TIME: number;
export declare const ENUM_PUBLISH_STREAM_STATE: {
    waiting_url: number;
    tryPublish: number;
    update_info: number;
    publishing: number;
    stop: number;
    retryPublish: number;
};
export declare const ENUM_STREAM_SUB_CMD: {
    liveNone: number;
    liveBegin: number;
    liveEnd: number;
    liveUpdate: number;
};
export declare const getSeq: Function;
export declare const getReportSeq: Function;
export interface StreamInfo {
    streamID: string;
    user: User;
    extraInfo: string;
    urlsFLV: string;
    urlsRTMP: string;
    urlsHLS: string;
    urlsHttpsFLV: string;
    urlsHttpsHLS: string;
}
export declare enum E_CLIENT_TYPE {
    ClientType_None = 0,
    ClientType_H5 = 1,
    ClientType_SmallPragram = 2,
    ClientType_Webrtc = 3
}
export interface ZegoRoomInfo {
    roomID: string;
    streamHandler: StreamHandler;
    token: string;
    sessionID: string;
    roomSessionID: string;
    isResetRoom: boolean;
    streamList: Array<any>;
    streamInfoList: any;
    dataChannelManager?: any;
}
/**
 * 根据当前环境返回定时器的类型
 *  - Node.js环境返回 NodeJS.Timeout
 *  - Browser环境返回 number
 */
export type Timer = ReturnType<typeof globalThis.setTimeout> | null;
export interface ZegoResponse {
    errorCode: number;
    extendedData: string;
}
export interface ZegoError {
    code: number;
    message: string;
}
export type ERRO = ZegoError;
export interface CdnPushConfig {
    type: "addpush" | "delpush" | "clearpush";
    streamID: string;
    pushUrl: string;
}
export interface TransCodecConfig {
    playAddr: string;
    transCodecID: number;
    transCodecSuffix: string;
    retry: number;
}
export interface MiniStreamDispatchRequest {
    streamID: string;
    actionType: "push" | "pull";
}
export declare const enum ENUM_STREAM_UPDATE_TYPE {
    deleted = 0,
    added = 1
}
export declare const ENUM_STREAM_UPDATE_CMD: {
    added: number;
    deleted: number;
    updated: number;
};
export declare const ENUM_PUBLISH_STATE_UPDATE: {
    start: number;
    error: number;
    retry: number;
};
export declare const ENUM_PLAY_STATE_UPDATE: {
    start: number;
    error: number;
    retry: number;
    stop: number;
};
export interface StreamQuality {
    videoBitrate: number;
    videoFramesDecoded?: number;
    videoFramesDropped?: number;
    videoPacketsLostRate?: number;
    videoQuality?: number;
    videoWidth?: number;
    videoHeight?: number;
    audioBitrate: number;
    audioJitter?: number;
    audioLevel?: number;
    audioPacketsLost?: number;
    audioPacketsLostRate?: number;
    audioQuality?: number;
    audioSamplingRate?: number;
    audioSendLevel?: number;
    playData?: number;
    videoFPS: number;
    frameHeight: number;
    frameWidth: number;
    videoTransferFPS: number;
    audioCodec: string;
    nackCount: number;
    pliCount: number;
    totalRoundTripTime: number;
    currentRoundTripTime: number;
}
export declare enum ZegoNetmode {
    Default = 0,
    Extranet = 1,
    Intranet = 2
}
export declare enum ENUM_RUN_STATE {
    logout = 0,
    trylogin = 1,
    login = 2
}
export declare enum USER_RUN_STATE {
    logout = 0,
    trylogin = 1,
    login = 2,
    reconnect = 3
}
export declare enum ENUM_BROADCASTER_STATUS {
    stop = 0,
    start = 1
}
export declare enum SignalResourceType {
    CDN = 0,
    RTC = 1,
    L3 = 2,
    DG = 3
}
export declare enum SoundLevelApiType {
    useAnalyzer = 0,
    useWorklet = 1
}
export declare enum ZegoScenario {
    Default = 3,
    StandardVideoCall = 4,
    HighVideoCall = 5,
    StandardChatroom = 6,
    HighQualityChatroom = 7,
    Broadcast = 8,
    UNKNOWN = 100
}
export interface ZegoReportSpan {
    setAttributes(attributes: Record<string, any>): void;
    setAttribute(key: string, value: any): void;
    end(immediately?: boolean): void;
}
export declare enum OSType {
    WIN32 = "WIN32",
    MAC = "Mac",
    ANDROID = "Android",
    LINUX = "Linux",
    IOS = "iOS",
    Harmony = "Harmony",
    UNKNOWN = "WTF"
}
export declare enum PlayMode {
    CDN = "cdn",
    L3 = "l3",
    RTC = "rtc"
}
export declare enum ResourceMode {
    RTC = 0,
    CDN = 1,
    L3 = 2,
    DG = 3,
    CUSTOM = 5
}
export declare enum ENUM_NETWORK_STATE {
    offline = 0,
    online = 1
}
export interface SEIConfig {
    unregisterSEIFilter?: string;
    SEIPass?: boolean;
    emulationPreventionByte?: boolean;
}
export interface AutoSwitchDeviceConfig {
    camera?: boolean;
    microphone?: boolean;
}
export declare enum QUALITY_CONSTANT {
    MinQuality = 0,
    DieQuality = 0,
    PoorMinQuality = 1,
    MiddleMinQuality = 30,
    GoodMinQuality = 60,
    ExcellentMinQuality = 85,
    MaxQuality = 100
}
export declare enum QualityGrade {
    Unknown = -1,
    Excellent = 0,
    Good = 1,
    Middle = 2,
    Poor = 3,
    Die = 4
}
export declare class ListNode<K> {
    _id: number | null;
    _data: K | null;
    next: ListNode<K> | null;
    prev: ListNode<K> | null;
    constructor(id?: number | null, data?: K | null);
    set id(id: number | null);
    get id(): null | number;
    set data(data: K | null);
    get data(): K | null;
    hasNext(): null | number;
    hasPrev(): null | number;
}
export type MessageItem = {
    seq: number;
    deleted: boolean;
    sendTime: number;
    timeout: number;
    success: Function | undefined | null;
    error: Function | undefined | null;
    params?: Record<string, any>;
    cmd?: string;
};
export declare class LinkedList<T> {
    start: ListNode<T>;
    end: ListNode<T>;
    _idCounter: number;
    _numNodes: number;
    constructor();
    /**
     *   Inserts a node before another node in the linked list
     *   @param {Node} toInsertBefore
     *   @param {Node} node
     */
    insertBefore(toInsertBefore: ListNode<T>, data: T): ListNode<T>;
    /**
     *   Adds data wrapped in a Node object to the end of the linked list
     *   @param {object} data
     */
    addLast(data: T): ListNode<T>;
    /**
     *   Alias for addLast
     *   @param {object} data
     */
    add(data: T): ListNode<T>;
    /**
     *   Gets and returns the first node in the linked list or null
     *   @return {Node/null}
     */
    getFirst(): ListNode<T> | null;
    /**
     *   Gets and returns the last node in the linked list or null
     *   @return {Node/null}
     */
    getLast(): ListNode<T> | null;
    /**
     *   Gets and returns the size of the linked list
     *   @return {number}
     */
    size(): number;
    /**
     *   (Internal) Gets and returns the node at the specified index starting from the first in the linked list
     *   Use getAt instead of this function
     *   @param {number} index
     */
    getFromFirst(index: number): null | ListNode<T>;
    /**
     *   Gets and returns the Node at the specified index in the linked list
     *   @param {number} index
     */
    get(index: number): ListNode<T> | null;
    /**
     *   Removes and returns node from the linked list by rearranging pointers
     *   @param {Node} node
     *   @return {Node}
     */
    remove(node: ListNode<T>): ListNode<T>;
    /**
     *   Removes and returns the first node in the linked list if it exists, otherwise returns null
     *   @return {Node/null}
     */
    removeFirst(): ListNode<T> | null;
    /**
     *   Removes and returns the last node in the linked list if it exists, otherwise returns null
     *   @return {Node/null}
     */
    removeLast(): ListNode<T> | null;
    /**
     *   Removes all nodes from the list
     */
    removeAll(): void;
    /**
     *    Iterates the list calling the given fn for each node
     *    @param {function} fn
     */
    each(iterator: Function): void;
    find(iterator: Function): ListNode<T> | null;
    map(iterator: Function): ListNode<T>[];
    /**
     *    Alias for addLast
     *    @param {object} data
     */
    push(data: T): ListNode<T>;
    /**
     *    Performs insertBefore on the first node
     *    @param {object} data
     */
    unshift(data: T): void;
    /**
     *    Alias for removeLast
     */
    pop(): ListNode<T> | null;
    /**
     *    Alias for removeFirst()
     */
    shift(): ListNode<T> | null;
}
export declare enum EncodecSelectionModeType {
    ONLY_BASELINE = "only_baseline",
    HARD_SOFT_ENCODEC_FIRST = "hard_or_soft_encodec_first",
    HIGH_PROFILE_FIRST = "high_profile_first"
}
declare enum ChoirRole {
    None = 0,
    Vocalist = 1,
    BackingSinging = 2
}
export interface DataChannelOption {
    ordered?: boolean;
    maxPacketLifeTime?: number;
    maxRetransmits?: number;
}
export interface EngineConfig {
    encodecSelectionMode?: EncodecSelectionModeType;
    keepAudioTrack: boolean;
    playClearLastFrame: boolean;
    previewClearLastFrame: boolean;
    mixingAudioDelay: number;
    adaptCustomUA: boolean;
    allowReplaceEmptyTrack: boolean;
    publishQualityInterval: number;
    playQualityInterval: number;
    baseMixingAudioDelay: number;
    setDeviceDelayByUser?: number;
    blankVideoTrackFrameInterval?: number;
    choirRole?: ChoirRole;
    notProxyRTC?: boolean;
    disableCanvasIOS15_1?: boolean;
    setUserInfo?: {
        userID?: string;
        userName?: string;
        token?: string;
    };
    enableMiniSDP?: boolean;
    keepRtcWhenSignalDisconnected?: boolean;
    autoRecaptureOnShow?: boolean;
    datachannelOption: DataChannelOption;
    maxChannels?: number;
    roomRetryTime?: number;
    streamRetryTime?: number;
    connectMediaServerInAdvance: boolean;
    switchRoomNotStopPlay?: boolean;
    enableReferenceBitrate: boolean;
    speechEnhanceLogLevel?: number;
    disableAINSRollback?: boolean;
}
export type { HttpReq, ConnectedType, BrokenType, Mode, DisconnectedType, BusinessService } from "../plugin/zegoConnection";
export { TRACER_LEVEL } from "../rtm/zego.entity";
export type { ZReporter } from "../rtm/zego.reporter";
export type { ZegoLogger, ZegoDataReport } from "zego-express-logger";
