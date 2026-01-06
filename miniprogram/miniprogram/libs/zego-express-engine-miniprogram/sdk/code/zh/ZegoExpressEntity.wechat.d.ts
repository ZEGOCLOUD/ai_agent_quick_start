import { ZegoRTMEvent, ZegoUser } from "./ZegoExpressEntity.rtm";
/**
 * 媒体服务相关事件集合
 *
 * Note: 详情描述：描述事件名及其对应的回调参数。
 *
 * Note: 业务场景：用于约束注册事件接口 on 和注销事件接口 off 的参数。
 *
 */
export interface ZegoWechatMiniEvent {
    /**
     * 推流质量回调
     */
    publishQualityUpdate: PublishQualityUpdateCallBack;
    /**
     * 推流状态回调
     */
    publisherStateUpdate: PublisherStateUpdateCallBack;
    /**
     * 房间内流变化回调
     *
     * 收到流删除通知时，开发者可将 extendedData 由字符串转为 json 对象得到 stream_delete_reason 字段，该字段为流删除原因的数组，stream_delete_reason[].code 字段可能为如下值：1（用户主动停止推流）；  2（用户心跳超时）；  3（用户重复登录）；  4（用户被踢出）；  5（用户断线）；  6（被服务端移除）
     */
    roomStreamUpdate: RoomStreamUpdateCallBack;
    /**
     * 拉流质量回调，每次回调间隔3s
     */
    playQualityUpdate: PlayQualityUpdateCallBack;
    /**
     * 接收对端设置的流附加信息
     */
    streamExtraInfoUpdate: StreamExtraInfoUpdateCallBack;
    /**
     * 拉流状态回调
     */
    playerStateUpdate: PlayerStateUpdateCallBack;
    /**
     * 混流转推 CDN 状态回调
     */
    mixerRelayCDNStateUpdate: MixerRelayCDNStateUpdateCallBack;
}
export interface ZegoMixStreamAdvance {
    /**
     * 混流背景颜色; backgroundColor 为十六进制的 RGB，输入格式必须为 0xRRGGBBxx
     */
    backgroundColor?: number;
    /**
     * 混流背景图片; backgroundImage 需要提前在即构后台预设 imageId，输入格式为 preset-id://xxx
     */
    backgroundImage?: string;
    /**
     * 混流视频编码，'vp8'(string) 或 ' h264' (string),默认 'h264'(string)
     */
    videoCodec?: "VP8" | "H264" | "vp8" | "h264";
}
export interface ZegoPlayAudioStats {
    /**
     * 音频码率
     */
    audioBitrate: number;
    /**
     * 音频编码格式"opus"
     */
    audioCodec: string;
    /**
     * 网络抖动
     */
    audioJitter: number;
    /**
     * 音量
     */
    audioLevel: number;
    /**
     * 丢包数
     */
    audioPacketsLost: number;
    /**
     * 丢包率
     */
    audioPacketsLostRate: number;
    /**
     * 拉流音频质量
     */
    audioQuality: number;
    /**
     * 采样率
     */
    audioSamplingRate: number;
    /**
     * 音轨是否被关闭
     */
    muteState: "0" | "1";
    /**
     * 音频帧率
     */
    audioFPS: number;
}
/**
 * 拉流质量回调详细信息
 *
 */
export interface ZegoPlayStats {
    /**
     * 视频相关描述
     */
    video: ZegoPlayVideoStats;
    /**
     * 音频相关描述
     */
    audio: ZegoPlayAudioStats;
}
export interface ZegoPlayVideoStats {
    /**
     * 接收视频高
     */
    frameHeight: number;
    /**
     * 接收视频宽
     */
    frameWidth: number;
    /**
     * 视频编码格式
     */
    googCodecName: string;
    /**
     * 视轨是否被关闭
     */
    muteState: "0" | "1";
    /**
     * 视频码率
     */
    videoBitrate: number;
    /**
     * 视频转码帧率
     */
    videoFPS: number;
    /**
     * 视频丢包数
     */
    videoPacketsLost: number;
    /**
     * 视频丢包率
     */
    videoPacketsLostRate: number;
    /**
     * 视频解码帧率
     */
    videoTransferFPS: number;
    /**
     * 拉流视频质量
     */
    videoQuality: number;
    /**
     * 视频解码总大小
     */
    videoFramesDecoded: number;
}
/**
 * 拉流状态
 *
 */
export interface ZegoPlayerState {
    /**
     * 流id
     */
    streamID: string;
    /**
     * NO_PLAY：未拉流状态，PLAY_REQUESTING：正在请求拉流状态，PLAYING：正在拉流状态
     */
    state: "NO_PLAY" | "PLAY_REQUESTING" | "PLAYING";
    /**
     * 错误码
     */
    errorCode: number;
    /**
     * 扩展信息
     */
    extendedData: string;
}
export interface ZegoPublishAudioStats {
    /**
     * 音频码率
     */
    audioBitrate: number;
    /**
     * 音频编码格式
     */
    audioCodec: string;
    /**
     * 音频丢包数
     */
    audioPacketsLost: number;
    /**
     * 音频丢包率
     */
    audioPacketsLostRate: number;
    /**
     * 音频编码格式
     */
    googCodecName: string;
    /**
     * 音轨是否被关闭
     */
    muteState: "0" | "1";
    /**
     * 音频帧率
     */
    audioFPS: number;
    /**
     * 推流音频质量
     */
    audioQuality: number;
}
export interface ZegoPublishStats {
    /**
     * 推流视频数据
     */
    video: ZegoPublishVideoStats;
    /**
     * 推流音频数据
     */
    audio: ZegoPublishAudioStats;
}
export interface ZegoPublishStreamAudioConfig {
    /**
     * 是否开启降噪
     */
    ANS?: boolean;
    /**
     * 是否开启自动增益
     */
    AGC?: boolean;
    /**
     * 是否开启回声消除
     */
    AEC?: boolean;
}
export interface ZegoPublishVideoStats {
    /**
     * 采集视频高
     */
    frameHeight: number;
    /**
     * 采集视频宽
     */
    frameWidth: number;
    /**
     * 视频编码格式
     */
    googCodecName: string;
    /**
     * 视轨是否被关闭
     */
    muteState: "0" | "1";
    /**
     * 视频码率
     */
    videoBitrate: number;
    /**
     * 视频转码帧率
     */
    videoFPS: number;
    /**
     * 视频丢包数
     */
    videoPacketsLost: number;
    /**
     * 视频丢包率
     */
    videoPacketsLostRate: number;
    /**
     * 视频编码帧率
     */
    videoTransferFPS: number;
    /**
     * 推流视频质量
     */
    videoQuality: number;
}
/**
 * 推流状态
 *
 */
export interface ZegoPublisherState {
    /**
     * 流ID
     */
    streamID: string;
    /**
     * NO_PUBLISH：未推流状态，PUBLISH_REQUESTING：正在请求推流状态，PUBLISHING：正在推流状态
     */
    state: "PUBLISHING" | "NO_PUBLISH" | "PUBLISH_REQUESTING";
    /**
     * 错误码
     */
    errorCode: number;
    /**
     * 扩展信息
     */
    extendedData: string;
}
export interface ZegoServerResponse {
    /**
     * 返回错误码,为0则是成功
     */
    errorCode: number;
    /**
     * 扩展信息
     */
    extendedData?: string;
}
/**
 * 音浪信息
 *
 */
export interface ZegoSoundLevelInfo {
    /**
     * 流ID
     */
    streamID: string;
    /**
     * 音浪大小
     */
    soundLevel: number;
    /**
     * 用于区分推拉流
     */
    type: string;
}
export interface ZegoStreamList {
    /**
     * 流 ID
     */
    streamID: string;
    /**
     * 流对应的用户
     */
    user: ZegoUser;
    /**
     * 流附加信息
     */
    extraInfo: string;
    /**
     * flv 播放地址
     */
    urlsFLV: string;
    /**
     * rtmp 播放地址
     */
    urlsRTMP: string;
    /**
     * hls 播放地址
     */
    urlsHLS: string;
    /**
     * https 协议的 flv 播放地址
     */
    urlsHttpsFLV: string;
    /**
     * https 协议的 hls 播放地址
     */
    urlsHttpsHLS: string;
}
export interface ZegoVideoCodec {
    /**
     * 是否支持H264编解码能力
     */
    H264: boolean;
    /**
     * 是否支持VP8编解码能力
     */
    VP8: boolean;
}
export interface ZegoWebPlayOption {
    /**
     * 是否需要拉取视频，默认为 true;
     * 通常情况下建议不填，SDK 默认会根据拉到的实际设备状态选择是否拉音视频
     */
    video?: boolean;
    /**
     * 是否需要拉取音频，默认为 true;
     * 通常情况下建议不填，SDK 默认会根据拉到的实际设备状态选择是否拉音视频
     */
    audio?: boolean;
    /**
     * 拉流额外参数;鉴权参数 streamParams 格式如下：'zg_expired=XX&zg_nonce=XX&zg_token=XX',只有需要配置鉴权时才传入，否则请忽略
     */
    streamParams?: string;
}
export interface ZegoWebPublishOption {
    /**
     * 推流备选参数 ; 备选参数 streamParams 格式如下：'zg_expired=XX&zg_nonce=XX&zg_token=XX'，只有需要配置鉴权才传入（可选功能）
     */
    streamParams?: string;
    /**
     * 流附加信息
     */
    extraInfo?: string;
    /**
     * 推流视频编码，只能传入 'VP8' (string) 或 'H264' (string)，默认值为 'H264' 。
     */
    videoCodec?: "VP8" | "H264";
    /**
     * 房间ID，开启多房间功能后必填，选择在哪个房间推流。
     */
    roomID?: string;
}
export interface ZegoWxPlayOption {
    /**
     * 拉流选项
     */
    streamParams?: string;
    /**
     * 是否拉混流
     */
    isMix?: boolean;
    /**
     * 拉流格式
     */
    sourceType?: "CDN" | "BGP";
}
export interface ZegoWxPublishOption {
    /**
     * 推流格式
     */
    sourceType?: "CDN" | "BGP";
    /**
     * 推流选项
     */
    streamParams?: string;
    /**
     * 额外信息
     */
    extraInfo?: string;
    /**
     * 房间ID，开启多房间功能后必填，选择在哪个房间推流。
     */
    roomID?: string;
    /**
     * 是否允许对该流进行审核，默认为允许， 0：允许， 1：不允许。
     */
    inspectFlag?: ZegoInspectFlagType;
}
export declare enum ZegoInspectFlagType {
    allow = 0,
    notAllow = 1
}
/**
 * 拉流质量回调,拉流成功后开始触发
 *
 * Note: 详情描述：订阅拉流质量回调
 *
 * Note: 触发条件：拉流成功后
 *
 * Note: 限制频率：无
 *
 * Note: 关注回调：无
 *
 * Note: 重点提示：每 3 秒回调一次
 *
 * Note: 支持版本：1.0.0
 *
 * Note: 废弃时间：无
 *
 * @param streamID 流 ID
 * @param stats 拉流质量回调信息
 */
type PlayQualityUpdateCallBack = (streamID: string, stats: ZegoPlayStats) => void;
/**
 * 拉流状态发生变化时回调
 *
 * Note: 详情描述：拉流的状态通知，拉流是异步过程，中间的状态切换都通过该接口回调。监听该回调，对重试依旧不能成功的情况，做错误日志收集，提示客户
 *
 * Note: 触发条件：开始拉流后
 *
 * Note: 限制频率：无
 *
 * Note: 关注回调：无
 *
 * Note: 重点提示：必须在拉流前监听
 *
 * Note: 支持版本：1.0.0
 *
 * Note: 废弃时间：无
 *
 * @param result 拉流状态结果
 */
type PlayerStateUpdateCallBack = (result: ZegoPlayerState) => void;
/**
 * 详情描述: 包括转推 CDN 的 URL、转推状态等
 */
export interface ZegoStreamRelayCDNInfo {
    url: string;
    state: "NO_RELAY" | "RELAY_REQUESTING" | "RELAYING";
    updateReason: string;
    stateTime: number;
}
/**
 * 混流转推 CDN 状态更新通知。
 * 在 ZEGO RTC 服务器的混流任务的一般情况会以 RTMP 协议将输出流向 CDN 推送，推送过程中出现的状态的变化会从该回调函数通知出来。
 * @param taskID 混流任务 ID。取值范围：长度不超过256。注意事项：该参数为字符串格式，不可以包含 URL 关键字，例如 'http', '?' 等，否则推拉流失败。仅支持数字，英文字符 和 '~', '!', '@', '$', '%', '^', '&', '*', '(', ')', '_', '+', '=', '-', '`', ';', '’', ',', '.', '<', '>', '\'。
 * @param infoList 当前 CDN 正在混流的信息列表。
 */
type MixerRelayCDNStateUpdateCallBack = (taskID: string, infoList: Array<ZegoStreamRelayCDNInfo>) => void;
/**
 * 订阅推流质量回调
 *
 * Note: 详情描述：订阅推流质量回调
 *
 * Note: 触发条件：推流成功后
 *
 * Note: 限制频率：无
 *
 * Note: 关注回调：无
 *
 * Note: 重点提示：每 3 秒回调一次
 *
 * Note: 支持版本：1.0.0
 *
 * Note: 废弃时间：无
 *
 * @param streamID 推流流ID
 * @param stats 推流质量描述
 */
type PublishQualityUpdateCallBack = (streamID: string, stats: ZegoPublishStats) => void;
/**
 * 推流状态回调
 *
 * Note: 详情描述：推流的状态通知，推流是异步过程，中间的状态切换都通过该接口回调。监听该回调，对重试依旧不能成功的情况，做错误日志收集，提示客户
 *
 * Note: 触发条件：开始推流后
 *
 * Note: 限制频率：无
 *
 * Note: 关注回调：无
 *
 * Note: 重点提示：必须在推流前监听
 *
 * Note: 支持版本：1.0.0
 *
 * Note: 废弃时间：无
 *
 * @param result 推流状态结果
 */
type PublisherStateUpdateCallBack = (result: ZegoPublisherState) => void;
/**
 * 监听已登录房间内流的变化（增加，删除）
 *
 * Note: 详情描述：监听已登录房间内流的变化（增加，删除）
 *
 * Note: 触发条件：房间内有流新增或删除
 *
 * Note: 限制频率：无
 *
 * Note: 重点提示：需要在登录房间前调用
 *
 * Note: 支持版本：1.0.0
 *
 * Note: 废弃时间：无
 *
 * @param roomID 房间ID
 * @param updateType DELETE：流删除，ADD：流新增
 * @param streamList 更新流列表
 * @param extendedData 扩展信息
 */
type RoomStreamUpdateCallBack = (roomID: string, updateType: "DELETE" | "ADD", streamList: ZegoStreamList[], extendedData: string) => void;
/**
 * 流附加消息变化时回调
 *
 * Note: 详情描述：接收对端设置的流附加信息
 *
 * Note: 触发条件：流附加消息更新
 *
 * Note: 支持版本：1.0.0
 *
 * Note: 废弃时间：无
 *
 * @param roomID 房间ID
 * @param streamList 流信息
 */
type StreamExtraInfoUpdateCallBack = (roomID: string, streamList: {
    streamID: string;
    user: ZegoUser;
    extraInfo: string;
}[]) => void;
export interface ZegoEvent extends ZegoWechatMiniEvent, ZegoRTMEvent {
}
export * from "./ZegoMixStreamEntity";
