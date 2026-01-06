import type { TrafficControlFocusOnMode, ZegoGeoFenceType, ZegoStreamRelayCDNInfo, ZegoWebPublishOption, PublisherVideoEncoderChangedCallBack, ZegoWebPlayOption } from "../../code/zh/ZegoExpressEntity.web";
import { StreamInfo, User, ENUM_LOG_LEVEL, E_CLIENT_TYPE, QualityGrade, ResourceMode } from "./zego.entity";
export declare enum ZegoFencing {
    CN = 2,
    NA = 3,
    EU = 4,
    AS = 5,
    IN = 6,
    NCN = 7
}
export declare enum ZegoSEIType {
    /**
     * 采用 SEI (nalu type = 6,payload type = 243) 类型打包，此类型是 SEI 标准未规定的类型，跟视频编码器或者视频文件中的 SEI 不存在冲突性，用户不需要根据 SEI 的内容做过滤。
     * SDK 默认发送 SEI 采用此种类型
     */
    ZegoDefined = 0,
    /**
     * 采用 SEI (nalu type = 6,payload type = 5) 类型打包，H.264 标准对于此类型有规定的格式：startcode + nalu type(6) + payload type(5) + len + pay load(uuid + context)+ trailing bits；
     * 因为视频编码器自身会产生 payload type 为 5 的 SEI，或者使用视频文件推流时，视频文件中也可能存在这样的 SEI，所以使用此类型时，用户把 uuid + context 当作一段 buffer 塞给次媒体的发送接口；
     * 此时为了区别视频编码器自身产生的 SEI， App 在发送此类型 SEI 时，可以填写业务特定的uuid（uuid长度为16字节），接收方使用SDK 解析payload type为 5的SEI时，会根据设置的过滤字符串过滤出 uuid相符的 SEI 抛给业务，如果没有设置过滤字符串，SDK会把所有收到的SEI都抛给业务方；
     * uuid过滤字符串设置接口，setSEIConfig设置的uuid过滤字符串。
     */
    UserUnregister = 1
}
export declare const enum SessionType {
    Publish = 0,
    Play = 1,
    NetProb = 2
}
export interface WebConfig {
    nickName?: string;
    logLevel?: ENUM_LOG_LEVEL;
    logUrl?: string;
    remoteLogLevel?: ENUM_LOG_LEVEL;
    debug?: boolean;
    qualityInterval?: number;
    userUpdate?: boolean;
}
export interface ParamsExt {
    keyframe_intv?: number;
    min_play_buf_level_ms?: number;
    tc_type?: number;
    video_content_type?: number;
    sei_filter_pass?: number;
    client_class_type?: number;
    video_stream_type?: number;
    zg_proxy?: number;
    coturn_internal?: number;
    auto_switch_turn_type?: number;
    ktv_device_delay?: number;
    sync_ntp?: number;
    play_jitter_level?: number;
    tc_focuson_mode?: TrafficControlFocusOnMode;
    tc_min_video_kbps?: number;
    proto_flags?: number;
    adaptive_switch?: number;
    adaptive_template_id_list?: string;
}
export interface WebListener {
    roomStreamUpdate: (roomID: string, updateType: "DELETE" | "ADD", streamList: StreamInfo[], extendedData: string) => void;
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
    screenSharingEnded: (stream: MediaStream) => void;
    publishQualityUpdate: (streamID: string, publishStats: WebPublishStats) => void;
    playQualityUpdate: (streamID: string, playStats: WebPlayStats) => void;
    remoteCameraStatusUpdate: (streamID: string, status: "OPEN" | "MUTE") => void;
    remoteMicStatusUpdate: (streamID: string, status: "OPEN" | "MUTE") => void;
    soundLevelUpdate: (soundLevelList: Array<{
        streamID: string;
        soundLevel: number;
        type: string;
    }>) => void;
    capturedSoundLevelUpdate: (level: number) => void;
    videoDeviceStateChanged: (updateType: "DELETE" | "ADD", deviceInfo: Device) => void;
    audioDeviceStateChanged: (updateType: "DELETE" | "ADD", deviceType: "Input" | "Output", deviceInfo: Device) => void;
    deviceError: (errorCode: number, deviceName: string) => void;
    receiveRealTimeSequentialData: (byte: ArrayBuffer, dataLength: number, streamID: string) => void;
    beautyEffectOverload: (stream: MediaStream) => void;
    /**
     * 收到远端流的 SEI 内容
     * 拉流成功后，当远端流调用 sendSEI 后，本端会收到此回调。
     * 若只拉纯音频流，将收不到推流端发送的 SEI 信息。
     * @param streamID 拉流的流 ID
     * @param data SEI 内容
     */
    playerRecvSEI: (streamID: string, data: Uint8Array) => void;
    beautyEffectError: (stream: MediaStream, errorCode: number, extendedData: string) => void;
    backgroundEffectError: (stream: MediaStream, errorCode: number, extendedData: string) => void;
    exceptionUpdate: (stream: MediaStream, eventData: ExceptionData) => void;
    networkQuality: (userID: string, upstreamQuality: QualityGrade, downstreamQuality: QualityGrade) => void;
    mixerSoundLevelUpdate: (soundLevels: Map<number, number>) => void;
    autoMixerSoundLevelUpdate: (soundLevels: Map<string, number>) => void;
    mixerRelayCDNStateUpdate: (taskID: string, infoList: Array<ZegoStreamRelayCDNInfo>) => void;
    recvExperimentalAPI: (content: Record<string, any>) => void;
    playerVideoTrackUpdate: (streamID: string, track: MediaStreamTrack) => void;
    playerAudioTrackUpdate: (streamID: string, track: MediaStreamTrack) => void;
    publisherVideoEncoderChanged: PublisherVideoEncoderChangedCallBack;
}
export type webPublishOption = Omit<ZegoWebPublishOption, 'videoCodec'> & {
    videoCodec?: ZegoVideoCodec;
    forceSynchronousNetworkTime?: 0 | 1;
    cdnUrl?: string;
    setDeviceDelayByUser?: number;
    audioBitRate?: number;
};
export type webPlayOption = Omit<ZegoWebPlayOption, 'resourceMode'> & {
    resourceMode?: ResourceMode;
    videoCodec?: ZegoVideoCodec;
};
export interface Geo {
    type: ZegoGeoFenceType;
    areaList: number[];
}
export interface MediaDescriptionParams {
    type?: number;
    sdp?: string;
    miniSdp?: Uint8Array;
    keyframe_intv?: number;
    min_play_buf_level_ms?: number;
    paramsExt?: ParamsExt;
}
export interface CreateSessionWithSdpOptions {
    seq: number;
    type: SessionType;
    mode: number;
    streamId: string;
    videoInfo?: {
        [key: string]: any;
    };
    strAuthParam: string;
    sdp?: string;
    miniSdp?: Uint8Array;
    serverHost: string;
    playBufLevel?: number;
    params: string;
    paramsExt: ParamsExt;
    roomID: string;
    geo: Geo;
    transCodecID?: number;
    transCodecSuffix?: string;
}
export interface DispatchGwNodesParams {
    type: SessionType;
    streamID: string;
    geo: Geo;
    transCodecID?: number;
    transCodecSuffix?: string;
}
export interface CreateSessionParams {
    type: SessionType;
    mode: number;
    streamID: string;
    strAuthParam: string;
    serverHost: string;
    params: string;
    roomID: string;
    geo: Geo;
    transCodecID?: number;
    transCodecSuffix?: string;
}
interface CapabilityError {
    name?: string;
    message?: string;
}
export interface CapabilityDetection {
    webRTC: boolean;
    customCapture: boolean;
    camera: boolean;
    microphone: boolean;
    videoCodec: {
        H264: boolean;
        H265: boolean;
        VP8: boolean;
        VP9: boolean;
    };
    screenSharing: boolean;
    errInfo: {
        webRTC?: CapabilityError;
        customCapture?: CapabilityError;
        camera?: CapabilityError;
        microphone?: CapabilityError;
        extendedDate?: string;
    };
}
export interface CapabilityDetectionSingle {
    result: boolean;
    errInfo: {
        webRTC?: CapabilityError;
        customCapture?: CapabilityError;
        camera?: CapabilityError;
        microphone?: CapabilityError;
        extendedDate?: string;
    };
}
export interface SupportVideoCodeSucCall {
    (rtcCodec: {
        webRTC: boolean;
        H264: boolean;
        VP8: boolean;
        VP9: boolean;
        H265: boolean;
    }, error?: any): void;
}
export type SupportVideoType = "VP8" | "H264";
export declare const ERROR_CODES: {
    ROOM_SESSION_ID_ERR: number;
    FETCH_TRANS_UNKNOWN_CHANNEL: number;
    FETCH_TRANS_UNKNOWN_TYPE: number;
    FETCH_TRANS_WRONG_SEQ: number;
};
export interface DataStatisticsItemEvent {
    event: string;
    event_time: number;
    time_consumed?: number;
    msg_ext?: {
        [index: string]: string | number;
    };
}
export interface DataStatisticsItem {
    event_time: number;
    time_consumed: number;
    error: number;
    message: string;
    events: DataStatisticsItemEvent[];
    seq?: number;
    event_id?: string;
    msg_ext?: any;
    itemtype?: string;
    event?: string;
    client_type?: E_CLIENT_TYPE;
}
export interface DataStatistics {
    [index: string]: DataStatisticsItem;
}
export interface TurnSecret {
    turn_username: string;
    turn_auth_key: string;
}
export declare enum ENUM_SIGNAL_STATE {
    disconnected = 0,
    connecting = 1,
    connected = 2
}
export declare enum ENUM_PROBE_STATE {
    tryProbe = 0,
    probed = 2
}
export declare enum HandleTrackType {
    replaceNew = 0,
    changeResolution = 1
}
export interface SignalConfig {
    path: string;
    query: string;
    encode?: boolean;
    messageType?: number;
}
export interface UpdateVideoInfo {
    width?: number;
    height?: number;
    frameRate?: number;
    bitRate?: number;
    startBitrate?: "default" | "target";
    minBitrate?: number;
    keyFrameInterval?: number;
    channelCount?: number;
    audioBitrate?: number;
    contentHint?: string;
}
export declare const STREAM_DELETE_REASON: any;
export interface PublishQualityInfo {
    stream_id: string;
    session_id: number;
    video_width: number;
    video_height: number;
    infos: Array<PublishInfo>;
    room_id: string;
    evnvironment: number;
    room_session_id: number;
    resource_type: ResourceType;
}
declare enum ResourceType {
    UNKNOWN = 0,
    CDN = 1,
    RTC = 2,
    L3 = 3
}
export interface PlayQualityInfo {
    stream_id: string;
    session_id: number;
    video_width: number;
    video_height: number;
    infos: Array<PlayInfo>;
    room_id: string;
    room_session_id: number;
    resource_type: ResourceType;
}
export interface PublishInfo {
    audio_bitrate: number;
    video_bitrate: number;
    video_capture_fps?: number;
    video_network_fps?: number;
    uplink_plr?: number;
    rtt?: number;
    audio_network_fps?: number;
    captured_sound_level?: number;
    audio_codec_name?: string;
    audio_FPS?: number;
    audio_input_level?: number;
    audio_level?: number;
    audio_mute_state?: string;
    audio_packets_lost?: number;
    audio_packets_lost_rate?: number;
    audio_quality?: number;
    audio_target_bitrate?: number;
    codec_implementation_name?: string;
    current_round_trip_time?: number;
    video_target_FPS?: number;
    video_transfer_FPS?: number;
    goog_actual_enc_bitrate?: number;
    goog_available_send_bandwidth?: number;
    goog_bandwidth_limited_resolution?: boolean;
    goog_cpu_limited_resolution?: boolean;
    goog_frame_height_input?: number;
    goog_frame_width_input?: number;
    goog_retransmit_bitrate?: number;
    goog_target_enc_bitrate?: number;
    muted?: boolean;
    nack_count?: number;
    volume?: number;
    paused?: boolean;
    pli_count?: number;
    sampling_rate?: number;
    send_level?: number;
    sink_id?: string;
    total_round_trip_time?: number;
    video_codec_name?: string;
    video_mute_state?: string;
    video_packets_lost?: number;
    video_packets_lost_rate?: number;
    video_quality?: number;
    video_target_bitrate?: number;
    sample_time_offset?: number;
}
export interface PlayInfo {
    audio_bitrate?: number;
    video_bitrate?: number;
    video_network_fps?: number;
    audio_break_count?: number;
    video_break_count?: number;
    downlink_plr?: number;
    peer_to_peer_plr: number;
    peer_to_peer_delay: number;
    audio_network_fps?: number;
    audio_break_duration?: number;
    video_break_duration?: number;
    audio_break_rate?: number;
    video_break_rate?: number;
    audio_break_cancel?: number;
    video_break_cancel?: number;
    rtt?: number;
    rendered_sound_level?: number;
    audio_break_cancel_duration?: number;
    video_break_cancel_duration?: number;
    audio_decode_time?: number;
    video_decode_time?: number;
    real_sampling_interval?: number;
    mos?: number;
    video_frames_decoded?: number;
    video_frames_dropped?: number;
    nack_count?: number;
    pli_count?: number;
    total_round_trip_time?: number;
    audio_codec_name?: string;
    audio_level?: number;
    audio_packets_lost?: number;
    audio_packets_lost_rate?: number;
    sampling_rate?: number;
    audio_quality?: number;
    video_quality?: number;
    video_transfer_FPS?: number;
    video_packets_lost?: number;
    video_packets_lost_rate?: number;
    video_codec_name?: string;
    goog_available_send_band_width?: string;
    codec_implementation_name?: string;
    video_mute_state?: string;
    audio_mute_state?: string;
    muted?: boolean;
    paused?: boolean;
    sink_id?: string;
    audio_jitter?: number;
    sample_time_offset?: number;
}
export interface CandidateStats {
    candidateType?: string;
    networkType?: string;
    relatedAddress?: string;
    relayProtocol?: string;
    url?: string;
}
export type CandidateStatsKey = keyof CandidateStats;
export declare const MINIUM_HEARTBEAT_INTERVAL = 3000;
export declare const SERVER_ERROR_CODE = 10000;
export declare const ICE_DISCONNECT_MAX_TIME = 15000;
export interface WaitingInfo {
    streamID: string;
    success: Function;
    error: Function | undefined;
}
export interface ChargeInfo {
    is_publishing?: number;
    play_stream_resolution_infos?: Array<ResolutionInfo>;
    play_max_audio_bitrate?: number;
    play_l3_max_audio_bitrate?: number;
    play_l3_stream_resolution_infos?: {
        video_width: number;
        video_height: number;
        count: number;
    }[];
    no_playing?: number;
}
export interface ResolutionInfo {
    video_width: number;
    video_height: number;
    count: number;
}
export interface ChargeInfos {
    timestamp_offset_begin: number;
    timestamp_offset_end: number;
    timestamp_diff_flag: number;
    timestamp_diff: number;
    room_id: string;
    infos: Array<ChargeInfo>;
}
export interface ResolutionInfo {
    video_width: number;
    video_height: number;
    count: number;
}
export declare enum UpdateQualityType {
    publish_quality = 0,
    play_quality = 1,
    charge = 2
}
export declare enum QUALITYLEVEL {
    low = 1,
    stantard = 2,
    hight = 3,
    custome = 4
}
export interface MediaStreamConstraints {
    audio?: boolean;
    audioInput?: string;
    video?: boolean;
    facingMode?: "user" | "environment";
    videoInput?: string;
    videoQuality?: QUALITYLEVEL;
    externalCapture?: boolean;
    height?: number | ConstraintExtend;
    frameRate?: number | ConstraintExtend;
    width?: number | ConstraintExtend;
    bitRate?: number;
    bitrate?: number;
    audioBitrate?: number;
    externalMediaStream?: MediaStream;
    noiseSuppression?: boolean;
    autoGainControl?: boolean;
    echoCancellation?: boolean;
    mediaSource?: "screen" | "application" | "window";
    screen?: boolean;
    source?: HTMLElement | MediaStream;
    channelCount?: 1 | 2;
    startBitrate?: "default" | "target";
    minBitrate?: number;
    sourceID?: string;
    videoOptimizationMode?: "default" | "motion" | "detail";
    keyFrameInterval?: number;
}
export interface ConstraintExtend {
    exact?: number;
    ideal?: number;
    max?: number;
    min?: number;
}
export interface CameraConstraints {
    audio?: boolean;
    audioInput?: string;
    video?: boolean;
    height?: number | ConstraintExtend;
    frameRate?: number | ConstraintExtend;
    width?: number | ConstraintExtend;
    bitRate?: number;
    bitrate?: number;
    startBitrate?: "default" | "target";
    minBitrate?: number;
    audioBitrate?: number;
    facingMode?: string;
    videoInput?: string;
    videoQuality?: QUALITYLEVEL;
    channelCount?: number;
    ANS?: boolean;
    AGC?: boolean;
    AEC?: boolean;
    videoOptimizationMode?: "default" | "motion" | "detail";
    keyFrameInterval?: number;
}
export type ScreenConstrains = {
    audio?: boolean;
    videoQuality?: 1 | 2 | 3 | 4;
    bitRate?: number;
    bitrate?: number;
    frameRate?: number | ConstraintExtend;
    width?: number | ConstraintExtend;
    height?: number | ConstraintExtend;
    sourceID?: string;
    videoOptimizationMode?: "default" | "motion" | "detail";
    startBitrate?: "default" | "target";
    minBitrate?: number;
    captureElement?: HTMLElement;
    audioBitrate?: number;
    keyFrameInterval?: number;
} | boolean;
export type CustomConstrains = {
    source: HTMLMediaElement | MediaStream;
    bitRate?: number;
    bitrate?: number;
    audioBitrate?: number;
    channelCount?: number;
    videoOptimizationMode?: "default" | "motion" | "detail";
    keyFrameInterval?: number;
};
export interface Constraints {
    camera?: CameraConstraints;
    screen?: ScreenConstrains;
    custom?: CustomConstrains;
}
export interface ZegoStreamOptions {
    autoCapture?: boolean;
    autoPlay?: boolean;
    captureView?: HTMLElement;
    view?: HTMLElement;
    multiplacePreview?: boolean;
    videoBitrate?: number | {
        bitrate?: number;
        startBitrate?: "default" | "target";
        minBitrate?: number;
    };
    audioBitrate?: number;
    camera?: {
        video?: boolean | ZegoCaptureCamera;
        audio?: boolean | ZegoCaptureMicrophone;
    };
    screen?: {
        video?: boolean | ZegoCaptureScreenVideo;
        audio?: boolean | ZegoCaptureScreenAudio;
    };
    custom?: {
        video?: ZegoCustomVideo;
        audio?: ZegoCustomAudio;
    };
}
export interface ZegoCaptureMicrophone {
    input?: string;
    channelCount?: 1 | 2;
    ANS?: boolean;
    AGC?: boolean;
    AEC?: boolean;
}
export interface ZegoCaptureCamera {
    input?: string;
    quality?: 1 | 2 | 3 | 4;
    facingMode?: "user" | "environment";
    width?: number | ConstraintExtend;
    height?: number | ConstraintExtend;
    frameRate?: number | ConstraintExtend;
    optimizationMode?: "default" | "motion" | "detail";
    keyFrameInterval?: number;
}
export interface ZegoCaptureScreenVideo {
    quality?: 1 | 2 | 3 | 4;
    width?: number | ConstraintExtend;
    height?: number | ConstraintExtend;
    frameRate?: number | ConstraintExtend;
    optimizationMode?: "default" | "motion" | "detail";
    /**
     * 指定屏幕共享画面 ID , 仅限chrome 内核浏览器使用
     */
    sourceID?: string;
    keyFrameInterval?: number;
    captureElement?: HTMLElement;
}
export interface ZegoCaptureScreenAudio {
    ANS?: boolean;
    AGC?: boolean;
    AEC?: boolean;
}
export interface ZegoCustomAudio {
    /**
     * 第三方源,<video>媒体对象或MediaStream
     */
    source: HTMLMediaElement | MediaStream;
    channelCount?: 1 | 2;
}
export interface ZegoCustomVideo {
    /**
     * 第三方源,<video>媒体对象或MediaStream
     */
    source: HTMLMediaElement | MediaStream;
    optimizationMode?: "default" | "motion" | "detail";
    keyFrameInterval?: number;
}
export interface PublishStreamConstraints {
    width?: number | ConstraintExtend;
    height?: number | ConstraintExtend;
    frameRate?: number | ConstraintExtend;
    minBitrate?: number;
    maxBitrate?: number;
    ANS?: boolean;
    AGC?: boolean;
    AEC?: boolean;
    video?: boolean;
    audio?: boolean;
}
export interface ScreenConfig {
    video?: {
        width?: number | ConstraintExtend;
        height?: number | ConstraintExtend;
        frameRate?: number | ConstraintExtend;
    };
    captureElement?: HTMLElement;
    bitRate?: number;
    audio?: boolean;
    startBitrate?: "default" | "target";
    minBitrate?: number;
    keyFrameInterval?: number;
    unlimitedCaptureResolution?: boolean;
    sourceID?: string;
    videoOptimizationMode?: "default" | "motion" | "detail";
    ANS?: boolean;
    AGC?: boolean;
    AEC?: boolean;
    channelCount?: number;
}
export interface ZegoPreviewConfig {
    audio?: boolean;
    audioInput?: string;
    video?: boolean;
    facingMode?: "user" | "environment";
    videoInput?: string;
    input?: string;
    videoQuality?: QUALITYLEVEL;
    quality?: QUALITYLEVEL;
    externalCapture?: boolean;
    height?: number | ConstraintExtend;
    frameRate?: number | ConstraintExtend;
    width?: number | ConstraintExtend;
    bitRate?: number;
    bitrate?: number;
    audioBitrate?: number;
    externalMediaStream?: MediaStream;
    ANS?: boolean;
    AGC?: boolean;
    AEC?: boolean;
    mediaSource?: "screen" | "application" | "window";
    screen?: boolean;
    source?: HTMLElement | MediaStream;
    channelCount?: 1 | 2;
    startBitrate?: "default" | "target";
    minBitrate?: number;
    sourceID?: string;
    videoOptimizationMode?: "default" | "motion" | "detail";
    optimizationMode?: "default" | "motion" | "detail";
    keyFrameInterval?: number;
    captureElement?: HTMLElement;
}
export interface CompositingStreamConfig {
    width?: number;
    height?: number;
    frameRate?: number;
    bitrate?: number;
}
export interface DeviceInfo {
    label: string;
    deviceID: string;
}
export interface Device {
    deviceName: string;
    deviceID: string;
}
export declare const ENUM_SIGNAL_SUB_CMD: {
    none: number;
    joinLiveRequest: number;
    joinLiveResult: number;
    joinLiveInvite: number;
    joinLiveStop: number;
};
export declare const ENUM_PUSH_SIGNAL_SUB_CMD: {
    none: number;
    pushJoinLiveRequest: number;
    pushJoinLiveResult: number;
    pushJoinLiveInvite: number;
    pushJoinLiveStop: number;
};
export interface ChatInfo {
    id_name: string;
    nick_name: string;
    role: number;
    msg_id: string;
    msg_category: number;
    msg_type: number;
    msg_content: string;
    send_time: number;
}
export interface UserInfo {
    userID: string;
    userName: string;
}
export interface MessageInfo {
    idName: string;
    nickName: string;
    messageId: string;
    category: number;
    type: number;
    content: string;
    time: number;
}
export interface WebQualityStats {
    video: {
        videoBitrate: number;
        videoFPS: number;
        videoTransferFPS?: number;
        frameHeight?: number;
        frameWidth?: number;
    };
    audio: {
        audioBitrate: number;
        audioCodec?: string;
        audioJitter?: number;
        audioLevel?: number;
        audioPacketsLost?: number;
        audioPacketsLostRate?: number;
        audioQuality?: number;
    };
    type: 1 | 0;
    roomId?: string;
    nackCount?: number;
    pliCount?: number;
    totalRoundTripTime?: number;
}
export declare const ENUM_PUBLISH_STATE_NEGO: {
    stop: number;
    start: number;
    waiterAnswer: number;
    waitingCandidate: number;
    sendCandidate: number;
    iceConnected: number;
    iceDisconnected: number;
    iceClosed: number;
    iceFailed: number;
};
export interface WebPublishStats {
    video: {
        videoBitrate: number;
        videoFPS: number;
        videoTransferFPS: number;
        frameHeight: number;
        frameWidth: number;
        googCodecName: string;
        muteState: "0" | "1";
        videoPacketsLost: number;
        videoPacketsLostRate: number;
    };
    audio: {
        audioBitrate: number;
        audioCodec: string;
        googCodecName: string;
        muteState: "0" | "1";
        audioPacketsLost: number;
        audioPacketsLostRate: number;
        audioFPS: number;
    };
    streamID: string;
    nackCount: number;
    pliCount: number;
    totalRoundTripTime: number;
    currentRoundTripTime: number;
}
export interface WebPlayStats {
    video: {
        videoBitrate: number;
        videoFPS: number;
        videoTransferFPS: number;
        videoFramesDecoded: number;
        videoFramesDropped: number;
        videoPacketsLostRate: number;
        videoQuality: number;
        frameHeight: number;
        frameWidth: number;
        googCodecName: string;
        muteState: "0" | "1";
        videoPacketsLost: number;
    };
    audio: {
        audioBitrate: number;
        audioCodec: string;
        audioJitter: number;
        audioLevel: number;
        audioPacketsLost: number;
        audioPacketsLostRate: number;
        audioQuality: number;
        audioSamplingRate: number;
        audioSendLevel: number;
        muteState: "0" | "1";
        audioFPS: number;
    };
    streamID: string;
    nackCount: number;
    pliCount: number;
    totalRoundTripTime: number;
    playData: number;
    currentRoundTripTime: number;
    /**
     * 端到端延迟，单位为 ms。
     */
    peerToPeerDelay: number | undefined;
    /**
     * 端到端丢包率，单位 1。（2.13.0 及以前版本单位为 %）
     */
    peerToPeerPacketLostRate: number | undefined;
}
export declare enum StreamUpdateType {
    Delete = 0,
    Add = 1
}
export interface ExceptionData {
    code: ExceptionCode;
    message: string;
}
export declare enum ExceptionCode {
    captureFpsToLow = 1001,
    captureVolumeToLow = 1002,
    sendVideoBitrateToLow = 1003,
    sendFpsToLow = 1004,
    sendAudioBitrateToLow = 1005,
    receiveVolumeToLow = 1006,
    receiveAudioDecodedFail = 1007,
    receiveVideoDecodedFail = 1008,
    receiveVideoFpsDecodedToLow = 1009,
    renderVideoFpsToLow = 1010,
    captureFpsNormal = 2001,
    captureVolumeNormal = 2002,
    sendVideoBitrateNormal = 2003,
    sendFpsNormal = 2004,
    sendAudioBitrateNormal = 2005,
    receiveVolumeNormal = 2006,
    receiveAudioDecodedNormal = 2007,
    receiveVideoDecodedNormal = 2008,
    receiveVideoFpsDecodedNormal = 2009,
    renderVideoFpsNormal = 2010
}
export interface VideoNodeInputInfo {
    track: MediaStreamTrack | null;
    frameInfo?: any;
}
export type ZegoVideoCodec = "VP8" | "H264" | "H265" | "VP9";
export interface ZegoMediaDevices extends MediaDevices {
    getDisplayMedia(constraints: any): Promise<MediaStream>;
}
export interface ZegoAudioContext extends AudioContext {
    createMediaStreamDestination(): MediaStreamAudioDestinationNode;
}
export interface ZegoHTMLAudioElement extends HTMLAudioElement {
    captureStream(): MediaStream;
}
interface ZegoMediaRecorderErrorEventInit extends EventInit {
    error: DOMException;
}
interface ZegoMediaRecorderErrorEvent extends Event {
    new (type: string, eventInitDict: ZegoMediaRecorderErrorEventInit): this;
    readonly error: DOMException;
}
interface ZegoBlobEventInit extends EventInit {
    data: Blob;
    timecode?: number;
}
export interface ZegoBlobEvent extends Event {
    readonly data: Blob;
    readonly timecode: number;
    new (type: string, eventInitDict: ZegoBlobEventInit): this;
}
export interface ZegoMediaRecorderOptions {
    mimeType?: string;
    audioBitsPerSecond?: number;
    videoBitsPerSecond?: number;
    bitsPerSecond?: number;
}
export interface StateInfo {
    state: string;
    code: number;
}
export type ZegoRecordingState = "inactive" | "recording" | "paused";
export type ZegoCheckSingleType = "webRTC" | "customCapture" | "camera" | "microphone" | "screenSharing" | "H264" | "VP8";
export declare class MediaRecorder extends EventTarget {
    readonly stream: MediaStream;
    readonly mimeType: string;
    readonly state: ZegoRecordingState;
    readonly videoBitsPerSecond: number;
    readonly audioBitsPerSecond: number;
    ondataavailable: (event: ZegoBlobEvent) => void;
    onerror: (event: ZegoMediaRecorderErrorEvent) => void;
    onpause: EventListener;
    onresume: EventListener;
    onstart: EventListener;
    onstop: EventListener;
    start(timeslice?: number): void;
    stop(): void;
    resume(): void;
    pause(): void;
    requestData(): void;
    static isTypeSupported(type: string): boolean;
    constructor(stream: MediaStream, options?: ZegoMediaRecorderOptions);
}
export declare const ENUM_RETRY_STATE: {
    didNotStart: number;
    retrying: number;
    finished: number;
};
export declare enum Segmentation {
    PortraitSegmentation = 0
}
export declare enum H264ProfileType {
    BASE_LINE = 1,
    MAIN = 2,
    HIGH = 3
}
export declare enum NetAgentMethod {
    METHOD_UNSET = 0,
    METHOD_GET = 1,
    METHOD_POST = 2,
    METHOD_PUT = 3,
    METHOD_PATCH = 4,
    METHOD_DELETE = 5,
    METHOD_HEAD = 6,
    METHOD_OPTIONS = 7
}
export declare const enum ZegoRemoteDeviceState {
    Open = 0,
    GenericError = 1,
    InvalidID = 2,
    NoAuthorization = 3,
    ZeroFPS = 4,
    InUseByOther = 5,
    Unplugged = 6,
    RebootRequired = 7,
    SystemMediaServicesLost = 8,
    Disable = 9,
    Mute = 10,
    Interruption = 11,
    InBackground = 12,
    MultiForegroundApp = 13,
    BySystemPressure = 14,
    NotSupport = 15
}
export declare const enum HandleType {
    Add = 0,
    Remove = 1
}
export declare enum NetAgentBusinessService {
    SERVICE_UNSET = 0,
    SERVICE_MEDIAGW = 1,
    SERVICE_LIVEROOM = 2,
    SERVICE_MIX = 3,
    SERVICE_ZEUS = 4,
    SERVICE_ZPUSH = 5,
    SERVICE_L3 = 6,
    SERVICE_TALKLINE = 7,
    SERVICE_EDUSUITE = 8,
    SERVICE_ZIM = 9,
    SERVICE_ClOUD_SETTING = 10,
    SERVICE_ZEUSHB = 11,
    SERVICE_USER_LOGIC = 12,
    SERVICE_UNIFYDISPATCH = 13,
    SERVICE_QUALITY = 14,
    SERVICE_SECURITY = 15,
    SERVICE_KTVCPR = 16,
    SERVICE_SWITCH4LIVEROOM = 17,
    SERVICE_WEBRTC_SIGNAL = 18,
    SERVICE_L3_WEBRTC_SIGNAL = 19,
    SERVICE_VIDEOCPR = 20,
    SERVICE_CDN = 21,
    SERVICE_CLOUDRECORD = 22,
    SERVICE_INNER_ECHO = 23,
    SERVICE_OUTER_ECHO = 24,
    SERVICE_LOCALHOST_ECHO = 25,
    SERVICE_ECHO = 26,
    SERVICE_DOCSERVICE = 27,
    SERVICE_AUTHSVR = 28
}
export interface NetAgentHttpReq {
    service: NetAgentBusinessService;
    headers?: {
        name: string;
        val: string;
    }[];
    body: any;
    idName: string;
    ack?: boolean;
    stick?: string;
    location: string;
    method_no: NetAgentMethod;
    disableLog?: boolean;
}
export interface NetAgentHttpResp {
    body: any;
    headers: Array<{
        name: string;
        val: string;
    }>;
    status_code: number;
    txid: number;
}
export type ZegoActivateSEIOption = {
    stream: MediaStream;
    action: 0 | 1;
    infoType?: number;
};
export declare const ROOM_CHANNEL_MESSAGE_EXPERIMENTALAPI = 0;
export declare const ENUM_RESOLUTION_TYPE: {
    LOW: {
        width: number;
        height: number;
        frameRate: number;
        bitRate: number;
    };
    MEDIUM: {
        width: number;
        height: number;
        frameRate: number;
        bitRate: number;
    };
    HIGH: {
        width: number;
        height: number;
        frameRate: number;
        bitRate: number;
    };
};
export declare const ENUM_SCREEM_RESOLUTION_TYPE: {
    LOW: {
        frameRate: number;
        bitRate: number;
    };
    MEDIUM: {
        frameRate: number;
        bitRate: number;
    };
    HIGH: {
        frameRate: number;
        bitRate: number;
    };
};
export declare const enum ENUM_PLAY_STATE_NEGO {
    stop = 0,
    start = 1,
    waiterAnswer = 2,
    waitingCandidate = 3,
    sendCandidate = 4,
    iceConnected = 5,
    iceDisconnected = 6,
    iceClosed = 7,
    iceFailed = 8
}
export interface VideoInfo {
    minBitrate: number;
    width: number;
    height: number;
    frameRate: number;
    bitRate: number;
    channelCount: number;
    audioBitrate: number;
    startBitrate: "default" | "target";
    keyFrameInterval: number;
    contentHint: string;
}
export {};
