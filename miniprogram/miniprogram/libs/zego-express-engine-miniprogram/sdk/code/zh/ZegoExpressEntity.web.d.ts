import { ExceptionData } from "./../../src/common/zego.entity.web";
import { QualityGrade } from "./../../src/common/zego.entity";
import { ZegoRTMEvent, ZegoUser } from "./ZegoExpressEntity.rtm";
/**
 * 低照度增强模式。
 *
 */
export declare enum ZegoLowlightEnhancementMode {
    Off = 0,
    On = 1
}
/**
 * 背景处理分割模式
 */
export declare enum Segmentation {
    PortraitSegmentation = 0
}
/**
 * 地理围栏类型。
 */
export declare enum ZegoGeoFenceType {
    /**
     * 不使用地理围栏。
     */
    ZegoGeoFenceTypeNone = 0,
    /**
     * 包括指定的地理围栏信息。
     */
    ZegoGeoFenceTypeInclude = 1,
    /**
     * 排除指定的地理围栏信息。
     */
    ZegoGeoFenceTypeExclude = 2
}
/**
 * 详情描述：SEI 类型。
 *
 */
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
/**
 * ZegoCamera及ZegoSreen的分辨率、码率等配置的约束扩展。
 *
 * 详细描述：约束对象，当ZegoCamera和ZegoSreen的参数videoQuality 为4时，对分辨率、码率等进行设置。
 *
 * 业务场景：创建预览音视频流时约束扩展。
 *
 * 注意事项：
 * 对于四种形式，优先级为 exact > ideal >= max = min。即：
 * 1. 出现exact时，忽略其他选项。若无法满足，则采集失败
 * 2. 出现ideal，没有min、max时，尽量靠近ideal
 *     ⅰ. 若能达到，则可以浮动在 ideal ± 10
 *     ⅱ. 若不能达到，则选用最靠近的值
 * 3. 不出现exact，出现ideal，有min时，尽量靠近ideal的同时，大于min。若无法满足大于min，则采集失败
 * 4. 不出现exact，出现ideal，有max时，尽量靠近ideal的同时，小于max。若无法满足小于max，则采集失败
 * 5. 不出现exact，出现ideal，有min和max时，尽量靠近ideal的同时，大于min且小于max。若无法满足，则采集失败
 * 6. 不出现exact，不出现ideal，出现min时，大于min。若无法满足大于min，则采集失败
 * 7. 不出现exact，不出现ideal，出现max时，小于max。若无法满足小于max，则采集失败
 * 8. 不出现exact，不出现ideal，出现min和max时，大于min且小于max。若无法满足，则采集失败。
 *
 */
export interface ConstraintExtend {
    /**
     * 可选参数，出现该选项时忽略其他选项。严格指定采集设备最终输出的值，如果设备不支持指定的值，采集会失败。
     */
    exact?: number;
    /**
     * 可选参数，期望采集设备最终输出的值，如果设备不支持指定的值，会尽量输出一个最靠近的值。
     */
    ideal?: number;
    /**
     * 可选参数，采集设备最终输出的值上限。
     */
    max?: number;
    /**
     * 可选参数，采集设备最终输出的值下限。
     */
    min?: number;
}
/**
 * 音浪回调设置选项。
 *
 */
export interface SoundLevelDelegateOptions {
    /**
     * 详情描述：设置在页面隐藏时是否保持开启获取获取音浪和回调音浪回调，2.18.0 及以后版本默认为关闭。
     * 业务场景：在页面隐藏时关闭获取音浪可以减少性能消耗。
     */
    enableInBackground?: boolean;
}
/**
 * 音效播放器设置选项。
 *
 */
export interface ZegoAudioEffectPlayOptions {
    /**
     * 指定加载在线音频资源地址，如果 audioEffectID 上已经加载了音效，会直接使用加载好的音效。
     * 1. 在线音频文件需要符合 [浏览器的同源策略](https://developer.mozilla.org/zh-CN/docs/Web/Security/Same-origin_policy)。
     * 2. 支持 MP3、AAC 以及浏览器支持的其他音频格式。
     */
    path?: string;
}
/**
 * 自动切换摄像头接口相关配置约束
 *
 */
export interface ZegoAutoSwitchDeviceConfig {
    /**
     * 详情描述：是否开启摄像头设备的自动切换
     *
     * 是否必填：否
     */
    camera?: boolean;
    /**
     * 详情描述：是否开启麦克风设备的自动切换
     *
     * 是否必填：否
     */
    microphone?: boolean;
}
/**
 * 创建摄像头媒体流相关参数约束
 *
 * Note: 详情描述：该类用于约束接口 createStream 的参数 source.camera。
 *
 * Note: 业务场景：创建摄像头音视频流。
 *
 * Note: 注意事项：
 * 1. 创建流成功后拿到的 stream 为 mediaStream 对象，开发者可通过赋值给 <video> 或 <audio> 对象的 srcObject 属性进行渲染。
 * 2. audioInput 和 videoInput 不指定时使用默认设备。
 * 3. 降噪、自动增益、回声消除三者默认为开启，若无特殊情况，建议客户保持这三项取值为 true。
 * 4. 当 camera 的 videoQuality 为 4 时，camera 增加 width / height / frameRate / bitrate 属性，这几个参数只支持正整数，必须要把这四个属性也传递给 SDK。
 * 5. 如果设置了 facingMode 参数，会忽略 videoInput 参数。
 *
 */
export interface ZegoCamera {
    /**
     * 是否需要音频，默认为 true
     */
    audio?: boolean;
    /**
     * 音频输入设备，不传则为浏览器选择的默认设备
     */
    audioInput?: string;
    /**
     * 音频码率，默认为 48kbps
     */
    audioBitrate?: number;
    /**
     * 是否需要视频
     */
    video?: boolean;
    /**
     * 视频输入设备，不传则为浏览器选择的默认设备
     */
    videoInput?: string;
    /**
     * 视频质量等级，默认质量等级为 2：
     * 1：分辨率 320 * 240，帧率 15，码率 300 kbps
     * 2：分辨率 640 * 480，帧率:15，码率 800 kbps
     * 3：分辨率 1280 * 720，帧率:20，码率 1500 kbps
     * 4：分辨率 width * height，帧率 frameRate，码率:  bitrate（kbps）
     * 注：当 videoQuality 为 4 时，width、height、frameRate 和 bitrate 四个参数必填。
     */
    videoQuality?: 1 | 2 | 3 | 4;
    /**
     * 摄像头朝向，“user” 表示前置摄像头，“environment” 表示后置摄像头
     */
    facingMode?: "user" | "environment";
    /**
     * 声道数，1 为单声道，2 为双声道，默认为单声道
     */
    channelCount?: 1 | 2;
    /**
     * 是否开启降噪，默认
     */
    ANS?: boolean;
    /**
     * 是否开启自动增益，默认开启
     */
    AGC?: boolean;
    /**
     * 是否开启回声消除，默认开启
     */
    AEC?: boolean;
    /**
     * 分辨率宽，videoQuality 为 4 时生效
     */
    width?: number | ConstraintExtend;
    /**
     * 分辨率高，videoQuality 为 4 时生效
     */
    height?: number | ConstraintExtend;
    /**
     * 码率，videoQuality 为 4 时生效
     */
    bitrate?: number;
    /**
     * 帧率，videoQuality 为 4 时生效
     */
    frameRate?: number | ConstraintExtend;
    /**
     * 开始码率，默认为 “default”，环境要求：谷歌内核浏览器及 2.7.0 以上版本的 SDK 。
     * 值为 “default” 表示使用 webrtc 默认开始码率 300kbps  然后慢慢上升；值为 “target” 表示快速上升到已设置的目标码率。
     */
    startBitrate?: "default" | "target";
    /**
     * 视频优化模式，默认为 “default“ ；
     * 值为 “motion” 表示流畅模式，在大多数情况下，SDK 不会降低帧率，但是可能会降低发送分辨率。
     * 值为 ”detail“ 表示清晰模式，在大多数情况，SDK 不会降低发送分辨率，但是可能会降低帧率。
     */
    videoOptimizationMode?: "default" | "motion" | "detail";
    /**
     * 详情描述：推流码率最小值。当网络较差的时候可接受的视频质量下降码率的最小值。
     *
     * 业务场景：期望视频持续高质量则把 minBitrate设置为接近目标码率的值。视频质量要求不高的推流可以把 minBitrate 设置得较低。
     *
     * 默认值：默认最低码率是目标码率的 60%。
     */
    minBitrate?: number;
    /**
     * 详情描述：视频关键帧间隔时长，单位秒。
     *
     * 默认值：2 秒。
     *
     * 取值范围: [2, 6]。
     */
    keyFrameInterval?: number;
}
export interface ZegoCapabilityDetection {
    /**
     * 是否支持webRTC协议,true代表可以使用webRTC协议传输流
     */
    webRTC?: boolean;
    /**
     * 是否支持自定义流(不通过摄像头或者屏幕捕捉采集到的其他流, 比如video标签播放的mp4等)
     */
    customCapture?: boolean;
    /**
     * 摄像头是否有权限调用
     */
    camera?: boolean;
    /**
     * 麦克风是否有权限调用
     */
    microphone?: boolean;
    /**
     * 是否支持屏幕共享功能
     */
    screenSharing?: boolean;
    /**
     * 浏览器支持的视频编码格式; 需要注意的是有些浏览器检测会支持某一种编码格式,但实际系统阉割了该功能, 所以如果某个编码格式返回false,则一定不支持, true 不一定100%支持
     */
    videoCodec?: ZegoVideoCodec;
    /**
     * 检测失败相关错误信息，设备相关的错误说明可以参考 [MediaDevices.getUserMedia](https://developer.mozilla.org/zh-CN/docs/Web/API/MediaDevices/getUserMedia#%E5%BC%82%E5%B8%B8) 接口文档的异常说明。
     */
    errInfo: ZegoCapabilityErrorInfo;
    /**
     * 根据传入的类型判断是否支持
     */
    result?: boolean;
}
export interface ZegoCapabilityError {
    /**
     * 错误名称
     */
    name?: string;
    /**
     * 错误描述信息
     */
    message?: string;
}
/**
 * 检测结果相关错误信息。
 *
 */
export interface ZegoCapabilityErrorInfo {
    webRTC?: ZegoCapabilityError;
    customCapture?: ZegoCapabilityError;
    /**
     * 具体错误说明可以参考 [MediaDevices.getUserMedia](https://developer.mozilla.org/zh-CN/docs/Web/API/MediaDevices/getUserMedia#%E5%BC%82%E5%B8%B8) 接口文档的异常说明。
     */
    camera?: ZegoCapabilityError;
    /**
     * 具体错误说明可以参考 [MediaDevices.getUserMedia](https://developer.mozilla.org/zh-CN/docs/Web/API/MediaDevices/getUserMedia#%E5%BC%82%E5%B8%B8) 接口文档的异常说明。
     */
    microphone?: ZegoCapabilityError;
    extendedDate?: string;
}
export interface ZegoCheckSingleType {
    /**
     * 检测浏览器是否支持 webRTC
     */
    webRTC: "webRTC";
    /**
     * 检测浏览器是否支持 自定义流
     */
    customCapture: "customCapture";
    /**
     * 检测摄像头是否有权限调用
     */
    camera: "camera";
    /**
     * 检测麦克风是否有权限调用
     */
    microphone: "microphone";
    /**
     * 检测是否支持屏幕共享
     */
    screenSharing: "screenSharing";
    /**
     * 检测是否支持H264编码格式
     */
    H264: "H264";
    /**
     * 检测是否支持VP8编码格式
     */
    VP8: "VP8";
}
/**
 * 创建第三方媒体流相关参数约束
 *
 * Note: 详情描述：该类用于约束接口 createStream 的参数 source.custom。
 *
 * Note: 业务场景：分享网络或本地的视频资源。
 *
 */
export interface ZegoCustom {
    /**
     * 第三方源,<video>或<audio>媒体对象或MediaStream
     */
    source: HTMLMediaElement | MediaStream;
    /**
     * 视频码率
     */
    bitrate?: number;
    /**
     * 音频码率，默认为 48kbps
     */
    audioBitrate?: number;
    /**
     * 声道数，1为单声道，2为双声道，默认单声道
     */
    channelCount?: number;
    /**
     * 开始码率，默认为 “default”，环境要求：谷歌内核浏览器及 2.7.0 以上版本的 SDK 。
     * 值为 “default” 表示使用 webrtc 默认开始码率 300kbps  然后慢慢上升；值为 “target” 表示快速上升到已设置的目标码率。
     */
    startBitrate?: "default" | "target";
    /**
     * 视频优化模式，默认为 “default“ ；
     * 值为 “motion” 表示流畅模式，在大多数情况下，SDK 不会降低帧率，但是可能会降低发送分辨率。
     * 值为 ”detail“ 表示清晰模式，在大多数情况，SDK 不会降低发送分辨率，但是可能会降低帧率
     */
    videoOptimizationMode?: "default" | "motion" | "detail";
    /**
     * 详情描述：推流码率最小值。当网络较差的时候可接受的视频质量下降码率的最小值。
     *
     * 业务场景：期望视频持续高质量则把 minBitrate设置为接近目标码率的值。视频质量要求不高的推流可以把 minBitrate 设置得较低。
     *
     * 默认值：默认最低码率是目标码率的 60%。
     */
    minBitrate?: number;
    /**
     * 详情描述：视频关键帧间隔时长，单位秒。
     *
     * 默认值：2 秒。
     *
     * 取值范围: [2, 6]。
     */
    keyFrameInterval?: number;
}
/**
 * 实时有序数据功能相关事件集合。
 *
 * Note: 详情描述：描述事件名及其对应的回调参数。
 *
 * Note: 业务场景：用于约束注册事件接口 on 和注销事件接口 off 的参数。
 *
 */
export interface ZegoDataChannelEvent {
    /**
     * 实时信令接收更新事件。
     */
    receiveRealTimeSequentialData: PlayerRecvRealtimeSequentialDataCallBack;
}
export interface ZegoDeviceInfo {
    deviceName: string;
    deviceID: string;
}
export interface ZegoDeviceInfos {
    microphones: ZegoDeviceInfo[];
    speakers: ZegoDeviceInfo[];
    cameras: ZegoDeviceInfo[];
}
/**
 * 基础美颜参数选项。
 *
 */
export interface ZegoEffectsBeautyParam {
    /**
     * 美白强度，取值范围 [0,100]，默认值 50。
     */
    whitenIntensity?: number;
    /**
     * 红润强度，取值范围 [0,100]，默认值 50。
     */
    rosyIntensity?: number;
    /**
     * 磨皮强度，取值范围 [0,100]，默认值 50。
     */
    smoothIntensity?: number;
    /**
     * 锐化强度，取值范围 [0,100]，默认值 50。
     */
    sharpenIntensity?: number;
}
export interface ZegoElectronScreenSource {
    /**
     * id
     */
    id: string;
    /**
     * 屏幕名称
     */
    name: string;
    /**
     * 屏幕快照
     */
    thumbnail: any;
}
/**
 * createStream 接口的配置参数约束
 *
 * Note: 详情描述：该类用于约束接口 createStream 的配置参数。
 *
 * Note: 业务场景：创建预览音视频流。
 *
 * Note: 注意事项：camera、screen 和 custom 三个参数在每次调用接口 createStream 时只能选填其中一个。
 *
 */
export interface ZegoLocalStreamConfig {
    /**
     * 摄像头麦克风采集流相关配置
     */
    camera?: ZegoCamera;
    /**
     * 屏幕捕捉采集流相关配置
     */
    screen?: boolean | ZegoScreen;
    /**
     * 第三方流采集相关配置
     */
    custom?: ZegoCustom;
}
export interface ZegoMixStreamAdvance {
    /**
     * 混流背景颜色; backgroundColor 为十六进制的 RGB，输入格式必须为 0xRRGGBB00。例如纯白色则传 0xffffff00。
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
    /**
     * 用户自定义数据，长度不超过 1000 字节，设置后拉流方可通过监听 [onPlayerRecvSEI] 的回调获取 SEI 内容。注意必须使用 [ByteBuffer.allocateDirect] 函数创建，否则数据不能传给SDK
     */
    userData?: Uint8Array;
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
     * 拉流音频质量，-1 表示未知，0 表示 极好,1 表示好，2 表示中等，3 表示 差，4 表示极差
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
    /**
     * 音频发送能量
     */
    audioSendLevel: number;
    /**
     * 音频编码格式
     */
    googCodecName: string;
    /**
     * 详情描述: 累计音频解码时长，单位为毫秒 （2.19.0 及以上版本支持）。
     */
    audioCumulativeDecodeTime: number;
    /**
     * 详情描述: 累计视频卡顿时长，单位为毫秒 （2.19.0 及以上版本支持）。
     */
    audioCumulativeBreakTime: number;
    /**
     * 详情描述: 累计视频卡顿率，单位为 1，取值范围 [0,1]（2.19.0 及以上版本支持）。
     */
    audioCumulativeBreakRate: number;
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
    /**
     * 端到端延迟，单位为 ms。
     */
    peerToPeerDelay: number | undefined;
    /**
     * 端到端丢包率，单位 1。（2.13.0 及以前版本单位为 %）
     */
    peerToPeerPacketLostRate: number | undefined;
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
     * 视频渲染帧率
     */
    videoRenderFPS: number;
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
     * 拉流视频质量，-1 表示未知，0 表示 极好,1 表示好，2 表示中等，3 表示 差，4 表示极差
     */
    videoQuality: number;
    /**
     * 视频解码总大小
     */
    videoFramesDecoded: number;
    /**
     * 当前实际接收的视频帧丢失数
     */
    videoFramesDropped: number;
    /**
     * 累计视频解码时长，单位为毫秒 （2.19.0 及以上版本支持）。
     */
    videoCumulativeDecodeTime: number;
    /**
     * 详情描述: 累计视频卡顿时长，单位为毫秒 （2.19.0 及以上版本支持）
     */
    videoCumulativeBreakTime: number;
    /**
     * 详情描述: 累计视频卡顿率，单位为百分比，0.0 ~ 1.0 （2.9.0 及以上版本支持）
     */
    videoCumulativeBreakRate: number;
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
     * 推流音频质量，-1 表示未知，0 表示 极好,1 表示好，2 表示中等，3 表示 差，4 表示极差
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
export interface ZegoPublishStreamConfig {
    /**
     * 分辨率宽
     */
    width?: number | ConstraintExtend;
    /**
     * 分辨率高
     */
    height?: number | ConstraintExtend;
    /**
     * 帧率
     */
    frameRate?: number | ConstraintExtend;
    /**
     * 最大码率
     */
    maxBitrate?: number;
    /**
     * 视频质量等级，默认质量等级为 2
     */
    videoQuality?: number;
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
     * 推流质量，-1 表示未知，0 表示 极好,1 表示好，2 表示中等，3 表示 差，4 表示极差
     */
    videoQuality: number;
    /**
     * 是否开启硬编，true 为开启，false 为关闭，undefined 为未知。
     */
    isHardwareEncode?: boolean;
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
/**
 * 媒体服务相关事件集合
 *
 * Note: 详情描述：描述事件名及其对应的回调参数。
 *
 * Note: 业务场景：用于约束注册事件接口 on 和注销事件接口 off 的参数。
 *
 */
export interface ZegoRTCEvent {
    /**
     * 推流质量回调
     */
    publishQualityUpdate: PublishQualityUpdateCallBack;
    /**
     * 推流状态回调
     */
    publisherStateUpdate: PublisherStateUpdateCallBack;
    /**
     * 屏幕共享中断回调
     */
    screenSharingEnded: ScreenSharingEndedCallBack;
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
     * 推流端的摄像头状态发生改变时触发
     */
    remoteCameraStatusUpdate: RemoteCameraStatusUpdateCallBack;
    /**
     * 推流端的麦克风状态改变时触发
     */
    remoteMicStatusUpdate: RemoteMicStatusUpdateCallBack;
    /**
     * 音浪回调
     */
    soundLevelUpdate: SoundLevelUpdateCallBack;
    /**
     * 监听视频设备状态变化
     */
    videoDeviceStateChanged: videoDeviceStateChangedCallBack;
    /**
     * 监听音频设备状态变化
     */
    audioDeviceStateChanged: audioDeviceStateChangedCallBack;
    /**
     * 监听设备异常
     */
    deviceError: deviceErrorCallBack;
    /**
     * 本地采集音频声浪回调
     */
    capturedSoundLevelUpdate: CapturedSoundLevelUpdateCallBack;
    /**
     * 收到远端流的 SEI 内容
     */
    playerRecvSEI: PlayerRecvSEICallBack;
    /**
     * 美颜功能发生异常错误。
     */
    beautyEffectError: BeautyEffectErrorCallBack;
    /**
     * 房间内流变化回调
     *
     * 收到流删除通知时，开发者可将 extendedData 由字符串转为 json 对象得到 stream_delete_reason 字段，该字段为流删除原因的数组，stream_delete_reason[].code 字段可能为如下值：1（用户主动停止推流）；  2（用户心跳超时）；  3（用户重复登录）；  4（用户被踢出）；  5（用户断线）；  6（被服务端移除）
     */
    roomStreamUpdate: RoomStreamUpdateCallBack;
    /**
     * 异常事件状态更新回调
     */
    exceptionUpdate: ExceptionUpdateCallBack;
    /**
     * 房间内正在推流的用户的网络质量回调
     */
    networkQuality: NetworkQualityCallBack;
    /**
     * 混流中的每条单流的声浪更新通知。
     */
    mixerSoundLevelUpdate: MixerSoundLevelUpdateCallBack;
    /**
     * 自动混流中的每条单流的声浪更新通知。
     */
    autoMixerSoundLevelUpdate: AutoMixerSoundLevelUpdateCallBack;
    /**
     * 背景虚化、虚拟的功能发生异常错误。
     */
    backgroundEffectError: BackgroundEffectErrorCallBack;
    /**
     * 实验性 API 回调
     */
    recvExperimentalAPI: RecvExperimentalAPICallBack;
    /**
     * 混流转推 CDN 状态回调
     */
    mixerRelayCDNStateUpdate: MixerRelayCDNStateUpdateCallBack;
    /**
     * 拉流的视轨发生改变时触发
     * 使用场景：当需要单独拿拉流得到的视轨进行视频渲染处理时使用。大部分场景推荐用 ZegoStreamView 渲染，不推荐使用该事件回调。
     */
    playerVideoTrackUpdate: PlayerTrackUpdateCallBack;
    /**
     * 拉流的音轨发生改变时触发
     * 使用场景：当需要单独拿拉流得到的音轨进行音频渲染处理时使用。大部分场景推荐用 ZegoStreamView 渲染，不推荐使用该事件回调。
     */
    playerAudioTrackUpdate: PlayerTrackUpdateCallBack;
    /**
     * 推流编码更新回调
     */
    publisherVideoEncoderChanged: PublisherVideoEncoderChangedCallBack;
}
/**
 * Note: 支持版本：2.16.0
 *
 */
export interface ZegoSEIConfig {
    /**
     * 详情描述：采用 H.264 的 SEI (nalu type = 6,payload type = 5) 类型打包，因为视频编码器自身会产生 payload type 为 5 的 SEI，或者使用视频文件推流时，视频文件中也可能存在这样的 SEI，所以使用此类型时，用户需要把 uuid + content 当作 buffer 塞给 SEI 发送接口；此时为了区别视频编码器自身产生的 SEI， App 在发送此类型 SEI 时，可以填写业务特定的 uuid（uuid长度为16字节），接收方使用 SDK 解析 payload type 为 5 的 SEI 时，会根据设置的过滤字符串过滤出 uuid 相符的 SEI 抛给业务，如果没有设置过滤字符串，SDK 会把所有收到的 SEI 都抛给开发者。
     *
     * 业务场景：发送 SEI，采用 H.264 的 SEI (nalu type = 6,payload type = 5) 类型打包 。
     */
    unregisterSEIFilter?: string;
    SEIPass?: boolean;
    emulationPreventionByte?: boolean;
}
/**
 * 创建屏幕共享媒体流相关参数约束
 *
 * Note: 详情描述：该类用于约束接口 createStream 的参数 source.screen。
 *
 * Note: 业务场景：创建屏幕共享媒体流。
 *
 * Note: 注意事项： 当 videoQuality 为 4 时，camera 增加 width / height / frameRate / bitrate 属性，这几个参数只支持正整数，必须要把这四个属性也传递给 SDK。
 *
 */
export interface ZegoScreen {
    /**
     * 是否需要音频，默认为 false
     */
    audio?: boolean;
    /**
     * 一般而言，屏幕共享视频质量的选择要根据实际情况和场景来确定，screen 中的 videoQuality 提供三种预设值：
     *
     * 1：帧率较大，适合对流畅度要求较高的场景。
     * 2：适合在流畅度和清晰度之间取得平衡的场景。
     * 3：码率较大，适合对清晰度要求较高的场景。
     * 除了以上三种预设值，videoQuality 还提供一种自定义取值 4，可自定义帧率、码率，screen 增加 frameRate / bitrate 属性，使用时需要把这两个属性也传递给 SDK。
     *
     * 视频质量等级，默认质量等级为 2
     * 1  帧率:20	码率: 800K
     * 2  帧率:15	码率: 1500K
     * 3  帧率:5	        码率: 2000K
     * 4  帧率:frameRate	码率: bitrate（k）
     */
    videoQuality?: 1 | 2 | 3 | 4;
    /**
     * 分辨率宽
     */
    width?: number | ConstraintExtend;
    /**
     * 分辨率高
     */
    height?: number | ConstraintExtend;
    /**
     * 码率
     */
    bitrate?: number;
    /**
     * 帧率
     */
    frameRate?: number | ConstraintExtend;
    /**
     * 码率（旧写法，建议使用 bitrate）
     */
    bitRate?: number;
    /**
     * 开始码率，默认为 “default”，环境要求：谷歌内核浏览器及 2.7.0 以上版本的 SDK 。
     * 值为 “default” 表示使用 webrtc 默认开始码率 300kbps  然后慢慢上升；值为 “target” 表示快速上升到已设置的目标码率。
     */
    startBitrate?: "default" | "target";
    /**
     * 视频优化模式，默认为 “default“ ；
     * 值为 “motion” 表示流畅模式，在大多数情况下，SDK 不会降低帧率，但是可能会降低发送分辨率。
     * 值为 ”detail“ 表示清晰模式，在大多数情况，SDK 不会降低发送分辨率，但是可能会降低帧率
     */
    videoOptimizationMode?: "default" | "motion" | "detail";
    /**
     * 指定屏幕共享画面 ID , 仅限chrome 内核浏览器使用
     */
    sourceID?: string;
    /**
     * 详情描述：推流码率最小值。当网络较差的时候可接受的视频质量下降码率的最小值。
     *
     * 业务场景：期望视频持续高质量则把 minBitrate设置为接近目标码率的值。视频质量要求不高的推流可以把 minBitrate 设置得较低。
     *
     * 默认值：默认最小码率是目标码率的 60%。
     */
    minBitrate?: number;
    /**
     * 详情描述：视频关键帧间隔时长，单位秒。屏幕共享可以通过调大关键帧的间隔时长以减少视频编码性能压力。
     *
     * 默认值：2 秒。
     *
     * 取值范围: [2, 6]。
     */
    keyFrameInterval?: number;
    /**
     * 是否开启自动增益，默认关闭。
     */
    ANS?: boolean;
    /**
     * 是否开启自动增益，默认关闭。
     */
    AGC?: boolean;
    /**
     * 是否开启回声消除，默认开启。
     */
    AEC?: boolean;
}
export interface ZegoServerResponse {
    /**
     * 返回错误码，为 0 则是成功
     */
    errorCode: number;
    /**
     * 扩展信息
     */
    extendedData?: string;
}
/**
 * 截图相关配置选项
 *
 */
export interface ZegoSnapshotOptions {
    /**
     * 详情描述：图片格式，支持 png 和 jpeg，默认为png。
     *
     * 业务场景：指定截图的图片格式。
     */
    imageType?: string;
    /**
     * 详情描述：图片质量，0-1，默认1。
     *
     * 业务场景：指定截图的图片质量。
     */
    quality?: number;
    /**
     * 详情描述：是否把截图保存下载到本地文件。
     */
    save?: boolean;
    /**
     * 详情描述：保存文件的名称，只在 save 设置为 true 时生效。
     */
    fileName?: string;
}
export interface AudioFrameOptions {
    /**
     * frameSize 每次回调的音频数据中每个声道包含的采样数据个数，只能设为下列值：256, 512, 1024, 2048, 4096, 8192, 16384。默认为 4096。
     * 只在首次设置生效
     */
    frameSize?: number;
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
     * 音浪大小，取值范围 [0，100]，通常一个人正常说话时麦克风音浪会波动到 10 以上。
     */
    soundLevel: number;
    /**
     * 用于区分推拉流，“push” 表示推流，“pull” 表示拉流。
     */
    type: "push" | "pull";
}
/**
 * 流信息
 *
 */
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
/**
 * 媒体流播放组件选项。
 *
 */
export interface ZegoStreamViewOptions {
    /**
     * 镜像显示，true 为开启，false 为关闭，默认是关闭。
     */
    mirror?: boolean;
    /**
     * 视频画面显示模式，"cover" 为覆盖容器；"contain" 为显示全部内容；"fill" 为拉伸填充。默认是 "contain"。
     */
    objectFit?: "cover" | "contain" | "fill";
    /**
     * 是否静音，true 为开启静音，false 为关闭静音。本地流的播放默认是静音，远端流的播放默认是关闭静音。
     */
    muted?: boolean;
    /**
     * 自动播放失败弹窗，默认开启，当出现自动播放失败时，SDK 会弹窗引导用户点击页面，来恢复音视频播放。可设置为 false 关闭。
     */
    enableAutoplayDialog?: boolean;
    /**
     * 当视频数据中断时是否去掉最后一帧画面。true 为清除，false 为保留，默认是 true。
     */
    clearLastFrame?: boolean;
}
/**
 * 媒体流播放组件选项。
 *
 */
export interface ZegoLocalViewOptions {
    /**
     * 镜像显示，true 为开启，false 为关闭，默认是关闭。
     */
    mirror?: boolean;
    /**
     * 视频画面显示模式，"cover" 为覆盖容器；"contain" 为显示全部内容；"fill" 为拉伸填充。默认是 "contain"。
     */
    objectFit?: "cover" | "contain" | "fill";
    /**
     * 自动播放失败弹窗，默认开启，当出现自动播放失败时，SDK 会弹窗引导用户点击页面，来恢复音视频播放。可设置为 false 关闭。
     */
    enableAutoplayDialog?: boolean;
    /**
     * 当视频数据中断时是否去掉最后一帧画面。true 为清除，false 为保留，默认是 true。
     */
    clearLastFrame?: boolean;
}
export interface ZegoLocalAduioOptions {
    /**
     * 自动播放失败弹窗，默认开启，当出现自动播放失败时，SDK 会弹窗引导用户点击页面，来恢复音视频播放。可设置为 false 关闭。
     */
    enableAutoplayDialog?: boolean;
}
export interface ZegoLocalStreamEvent {
    autoplayFailed: (player: HTMLMediaElement, e?: any) => void;
    canPlayAudio: (e: Event) => void;
    canPlayVideo: (e: Event) => void;
    canPlayCaptureVideo: (e: Event) => void;
    canPlayCaptureAudio: (e: Event) => void;
    autoplayCaptureFailed: (player: HTMLMediaElement, e?: any) => void;
    videoTrackChanged: (videoTrack: MediaStreamTrack) => void;
    audioTrackChanged: (audioTrack: MediaStreamTrack) => void;
    captureVideoTrackChanged: (videoTrack: MediaStreamTrack) => void;
    captureAudioTrackChanged: (audioTrack: MediaStreamTrack) => void;
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
/**
 * 拉流模式，默认为 0。0 表示仅从 RTC 拉流；1 表示仅从 CDN 拉流；2 表示仅从 L3 拉流；5 表示自定义模式，SDK根据推流设置的customResourceConfig参数选择推流资源。
 */
type ZegoResourceType = 0 | 1 | 2 | 5;
/**
 * 自定义拉流资源类型配置。3.7.0 版本开始支持。
 */
export interface ZegoCustomPlayerResourceConfig {
    /**
     * 开始推流前拉流选择的资源类型。0 表示仅从 RTC 拉流；1 表示仅从 CDN 拉流；2 表示仅从 L3。
     */
    beforePublish: ZegoResourceType;
    /**
     * 推流中拉流选择的资源类型。0 表示仅从 RTC 拉流；1 表示仅从 CDN 拉流；2 表示仅从 L3。
     */
    publishing: ZegoResourceType;
    /**
     * 停止推流后拉流选择的资源类型。0 表示仅从 RTC 拉流；1 表示仅从 CDN 拉流；2 表示仅从 L3。
     */
    afterPublish: ZegoResourceType;
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
    /**
     * 拉流模式，默认为 0。0 表示仅从 RTC 拉流；1 表示仅从 CDN 拉流；2 表示仅从 L3 拉流；5 表示自定义模式，SDK根据推流设置的customResourceConfig参数选择推流资源。
     */
    resourceMode?: ZegoResourceType;
    /**
     * 详情描述：是否发送 SEI
     */
    isSEIStart?: boolean;
    /**
     * 拉流大小流类型 0 为小流，1为大流，2为自动
     */
    streamType?: 0 | 1 | 2;
    /**
     * ZegoCDNPlayer 实例对象，目前仅支持flv格式。
     */
    CDNPlayer?: any;
    /**
     * 用于播放 CDN 资源的 <video> 标签元素。
     */
    CDNVideo?: HTMLVideoElement;
    /**
     * @deprecated 已废弃, 请使用jitterBufferTarget进行设置
     * 设置拉流音视频播放延迟，单位为秒，取值[1, 4]secs。如果网络状况不佳，浏览器可能会增加播放延迟以减少卡顿。
     * 如果将enableLowLatency设置为true，则此参数不起作用。
     */
    playoutDelayHint?: number;
    /**
     * 设置拉流音视频播放延迟，单位为毫秒，取值(0, 4000]ms。如果网络状况不佳，浏览器可能会增加播放延迟以减少卡顿。
     * 如果将enableLowLatency设置为true，则此参数不起作用。
     */
    jitterBufferTarget?: number;
    /**
     * 是否允许超低延迟，默认为 false；
     * 当设置为true，则playoutDelayHint和jitterBufferTarget参数不起作用。
     */
    enableLowLatency?: boolean;
    /**
     * 当 [resourceMode] 为5 即自定义拉流资源策略时的拉流资源类型配置。
     * 自 3.7.0 版本起支持该参数。
     */
    customResourceConfig?: ZegoCustomPlayerResourceConfig;
    /**
     * 码率模板ID，用于拉取指定码率模板的流。 取值大于 100 的整数，ID 必须唯一
     */
    codecTemplateID?: number;
    /**
     * 是否开启流的自适应切换，1 表示开启，0 表示关闭。仅 [resourceMode] 为 L3 时有效。
     * 若需要使用请联系 ZEGO 技术支持，否则可以忽略此参数。
     */
    adaptiveSwitch?: boolean;
    /**
     * 流的自适应转码模板ID列表。仅 [resourceMode] 为 L3 时有效。
     * 若需要使用请联系 ZEGO 技术支持，否则可以忽略此参数。
     */
    adaptiveTemplateIDList?: number[];
}
/**
 * 详情描述：触发推流流量控制的因素。
 *
 */
export declare enum TrafficControlFocusOnMode {
    /**
     * 只关注本地网络
     */
    TrafficControlFocusOnLocalOnly = 0,
    /**
     * 关注本地网络， 同时也兼顾远端网络，目前只在 1v1 场景下有效
     */
    TrafficControlFocusOnRemote = 1
}
export declare enum TrafficControlMinVideoBitrateMode {
    /**
     * 低于设置的最低码率时，停止视频发送, 默认最低码率为50kbps
     */
    NoVideo = 0
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
    /**
     * 是否开启 SEI
     */
    isSEIStart?: boolean;
    /**
     * SEI 类型
     */
    SEIType?: ZegoSEIType;
    /**
     * 是否开启 DTX 静音检测，用于减少不发声时推流的音频码率。默认是关闭 DTX。
     */
    enableDTX?: boolean;
    /**
     * 是否允许对该流进行审核，默认为允许， 0：允许， 1：不允许。
     */
    inspectFlag?: ZegoInspectFlagType;
    /**
     * 触发流量控制的因素, 默认为TrafficControlFocusOnRemote
     */
    trafficControlFocusOnMode?: TrafficControlFocusOnMode;
    /**
     * 最低视频码率，单位为 kbps
     */
    trafficControlMinVideoBitrate?: number;
    /**
     * 流控触发最低码率时的视频发送模式
     */
    trafficControlMinVideoMode?: TrafficControlMinVideoBitrateMode;
    /**
     * 流控开关，默认为开启， true：开启， false：关闭。
     */
    enableTrafficControl?: boolean;
    /**
     * 当 videoCodec 不可用时，是否自动切换为可用的 videoCodec, 默认false。 比如：当前设备不支持H264，开启该配置后，SDK 会自动切换至VP8
     */
    enableAutoSwitchVideoCodec?: boolean;
}
export declare enum ZegoInspectFlagType {
    Allow = 0,
    NotAllow = 1
}
/**
 * 更新推流的类型
 */
export declare enum ZegoStreamUpdateType {
    video = 0,
    audio = 1,
    videoAndAudio = 2
}
/**
 * 背景虚化、虚拟功能发生异常错误时触发事件。
 *
 * @param stream 开启背景虚化、虚拟功能对应的媒体流对象。
 * @param errorCode 错误码。
 * @param extendedData 错误描述信息。
 */
type BackgroundEffectErrorCallBack = (stream: MediaStream, errorCode: number, extendedData: string) => void;
/**
 * 美颜功能发生异常错误时触发事件。
 *
 * @param stream 开启美颜功能对应的媒体流对象。
 * @param errorCode 错误码。
 * @param extendedData 错误描述信息。
 */
type BeautyEffectErrorCallBack = (stream: MediaStream, errorCode: number, extendedData: string) => void;
/**
 * @param content 回调的内容，JSON 对象
 */
type RecvExperimentalAPICallBack = (content: Record<string, any>) => void;
/**
 * 详情描述: 包括转推 CDN 的 URL、转推状态等
 */
export interface ZegoStreamRelayCDNInfo {
    url: string;
    state: "NO_RELAY" | "RELAY_REQUESTING" | "RELAYING";
    updateReason: string;
    stateTime: number;
}
export declare const enum ZegoVideoCodecID {
    ZegoVideoCodecIDDefault = 0,
    ZegoVideoCodecIDVp8 = 2
}
export type PublisherVideoEncoderChangedCallBack = (fromCodecID: ZegoVideoCodecID, toCodecID: ZegoVideoCodecID, streamID: string) => void;
/**
 * 混流转推 CDN 状态更新通知。
 * 在 ZEGO RTC 服务器的混流任务的一般情况会以 RTMP 协议将输出流向 CDN 推送，推送过程中出现的状态的变化会从该回调函数通知出来。
 * @param taskID 混流任务 ID。取值范围：长度不超过256。注意事项：该参数为字符串格式，不可以包含 URL 关键字，例如 'http', '?' 等，否则推拉流失败。仅支持数字，英文字符 和 '~', '!', '@', '$', '%', '^', '&', '*', '(', ')', '_', '+', '=', '-', '`', ';', '’', ',', '.', '<', '>', '\'。
 * @param infoList 当前 CDN 正在混流的信息列表。
 */
type MixerRelayCDNStateUpdateCallBack = (taskID: string, infoList: Array<ZegoStreamRelayCDNInfo>) => void;
/**
 * 本地采集音频声浪回调，该接口目前不兼容 safari
 *
 * @param soundLevel 本地采集的声浪值，取值范围为 0.0 ~ 100.0 。
 */
type CapturedSoundLevelUpdateCallBack = (soundLevel: number) => void;
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
 * 实时有序数据更新回调
 *
 * Note: 详情描述：实时有序数据更新回调。
 *
 * Note: 触发条件：收到了对端发送的 实时数据。
 *
 * Note: 重点提示：必须在 startSubscribing 接口调用前监听。
 *
 * Note: 支持版本：2.12.0
 *
 * @param byte 实时数据
 * @param dataLength 数据长度
 * @param streamID 数据相关流ID
 */
type PlayerRecvRealtimeSequentialDataCallBack = (byte: ArrayBuffer, dataLength: number, streamID: string) => void;
/**
 * channels 音频数据
 * channelCount 音频数据声道数
 */
export type AudioFrameCallback = (audioData: {
    channels: Float32Array[];
    channelCount: number;
    sampleRate: number;
}) => void;
/**
 * 收到远端流的 SEI 内容
 * 拉流成功后，当远端流调用 sendSEI 后，本端会收到此回调
 * 若只拉纯音频流，将收不到推流端发送的 SEI 信息
 *
 * @param streamID 流 ID
 * @param data SEI 内容
 */
type PlayerRecvSEICallBack = (streamID: string, data: Uint8Array) => void;
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
 * 拉流摄像头状态回调
 *
 * @param streamID 流 ID
 * @param status 所拉流的摄像头状态 'OPEN'表示开启 'MUTE'表示关闭
 */
type RemoteCameraStatusUpdateCallBack = (streamID: string, status: "OPEN" | "MUTE") => void;
/**
 * 拉流麦克风状态回调
 *
 * @param streamID 流 ID
 * @param status 所拉流的麦克风状态 'OPEN'表示开启 'MUTE'表示关闭
 */
type RemoteMicStatusUpdateCallBack = (streamID: string, status: "OPEN" | "MUTE") => void;
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
 * @param streamList 更新流列表，数组顺序是以服务器接收到的时间进行排序。
 * @param extendedData 扩展信息
 */
type RoomStreamUpdateCallBack = (roomID: string, updateType: "DELETE" | "ADD", streamList: ZegoStreamList[], extendedData: string) => void;
/**
 * 监听已推拉流采集、编码解码异常
 *
 * Note: 详情描述：监听已推拉流采集、编码解码异常
 *
 * Note: 触发条件：流质量开始更新
 *
 * Note: 限制频率：无
 *
 * Note: 重点提示：需要在推拉流前绑定
 *
 * Note: 支持版本：2.23.0
 *
 * Note: 废弃时间：无
 *
 * @param streamID 流ID
 * @param eventData 事件相关信息
 */
type ExceptionUpdateCallBack = (streamID: string, eventDate: ExceptionData) => void;
/**
 * 房间内正在推流的用户的网络质量回调
 *
 * Note: 详情描述：房间内正在推流的用户的网络质量回调
 *
 * Note: 触发条件：流质量开始更新
 *
 * Note: 限制频率：无
 *
 * Note: 重点提示：需要在推拉流前绑定
 *
 * Note: 支持版本：2.24.0
 *
 * Note: 废弃时间：无
 *
 * @param userID 用户id
 * @param upstreamQuality 上行质量
 * @param downstreamQuality 下行质量
 */
type NetworkQualityCallBack = (userID: string, upstreamQuality: QualityGrade, downstreamQuality: QualityGrade) => void;
/**
 * 屏幕共享中断回调
 *
 * Note: 详情描述：监听因为点击系统停止按钮，或者关闭捕捉进程等导致的屏幕共享流被动关闭
 *
 * Note: 触发条件：屏幕共享后点击系统停止或者关闭捕捉进程等
 *
 * Note: 限制频率：无
 *
 * Note: 重点提示：必须在屏幕共享前监听
 *
 * Note: 支持版本：1.0.0
 *
 * Note: 废弃时间：无
 *
 * @param mediaStream 创建屏幕共享流得到的流对象
 */
type ScreenSharingEndedCallBack = (mediaStream: MediaStream) => void;
/**
 * 推拉流音浪回调,该接口目前不兼容safari
 *
 * @param soundLevelList 声浪信息列表，包括流id，声浪大小，及流状态
 */
type SoundLevelUpdateCallBack = (soundLevelList: ZegoSoundLevelInfo[]) => void;
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
/**
 * 音频设备状态变化回调
 *
 * Note: 详情描述：监测到系统中有音频设备添加或移除时，会触发此回调。通过监听此回调，用户可在必要的时候更新使用特定设备进行音频采集。
 *
 * Note: 触发条件：音频设备添加或移除时触发
 *
 * Note: 限制频率：无
 *
 * Note: 关注回调：无
 *
 * Note: 重点提示：
 *       需要浏览器授权麦克风摄像头后才能触发回调；
 *       由于设备和浏览器的限制，部分浏览器在使用某些设备时可能不会触发该回调
 *
 * Note: 支持版本：1.16.0
 *
 * Note: 废弃时间：无
 *
 * @param updateType 'DELETE' 表示设备删除， 'ADD'表示设备增加
 * @param deviceType 'Input'表示输入设备， 'Output'表示输出设备
 * @param deviceInfo 设备信息
 */
type audioDeviceStateChangedCallBack = (updateType: "DELETE" | "ADD", deviceType: "Input" | "Output", deviceInfo: {
    deviceName: string;
    deviceID: string;
}) => void;
/**
 * 设备异常回调
 *
 * Note: 详情描述：当本地推流的音频或视频设备读写出现异常时会触发此回调
 *
 * Note: 触发条件：推流使用的音视频设备出现异常（如松动时）触发
 *
 * Note: 限制频率：无
 *
 * Note: 关注回调：无
 *
 * Note: 重点提示：
 *       推流后才可能触发；
 *       由于设备和浏览器的限制，部分浏览器在使用某些设备时可能不会触发该回调
 *
 * Note: 支持版本：1.16.0
 *
 * Note: 废弃时间：无
 *
 * @param errorCode 错误码
 * @param deviceName 发生异常的设备名称
 */
type deviceErrorCallBack = (errorCode: number, deviceName: string) => void;
/**
 * 视频设备状态变化更新回调
 *
 * Note: 详情描述：监测到系统中有视频设备添加或移除时，会触发此回调。通过监听此回调，用户可在必要的时候更新使用特定设备进行视频采集。
 *
 * Note: 触发条件：视频设备添加或移除时触发
 *
 * Note: 限制频率：无
 *
 * Note: 关注回调：无
 *
 * Note: 重点提示：
 *       需要浏览器授权麦克风摄像头后才能触发回调；
 *       由于设备和浏览器的限制，部分浏览器在使用某些设备时可能不会触发该回调
 *
 * Note: 支持版本：1.16.0
 *
 * Note: 废弃时间：无
 *
 * @param updateType 'DELETE' 为设备被移除， 'ADD'表示设备增加
 * @param deviceInfo 设备信息，deviceName为设备名称，deviceID为设备ID
 */
type videoDeviceStateChangedCallBack = (updateType: "DELETE" | "ADD", deviceInfo: {
    deviceName: string;
    deviceID: string;
}) => void;
/**
 * 混流中的每条单流的声浪更新通知。
 *
 * Note: 详情描述：开发者可根据此回调在观众拉混流的 UI 界面显示哪条流的主播在说话的效果。
 *
 *  Note: 业务场景：常用于需要多个视频画面合成一个视频时使用混流，比如教育类，直播老师和学生的画面。
 *
 *  Note: 触发条件：开发者调用 [startPlayingStream] 函数并且拉流选项开启接收 SEI，开始拉混流后触发回调，回调通知周期为 100 ms。
 *
 *  Note: 支持版本：3.0.0
 *
 *  Note: 废弃时间：无
 *
 * @param soundLevels 混流中每条单流的声浪键值对，key 为每条单流的 soundLevelID，value 为对应的单流的声浪值。取值范围：value 的取值范围为 0.0 ~ 100.0。
 */
type MixerSoundLevelUpdateCallBack = (soundLevels: Map<number, number>) => void;
/**
 * 自动混流中的每条单流的声浪更新通知。
 *
 * Note: 详情描述：开发者可根据此回调在观众拉混流的 UI 界面显示哪条流的主播在说话的效果。
 *
 *  Note: 业务场景：常用于需要多个视频画面合成一个视频时使用混流，比如教育类，直播老师和学生的画面。
 *
 *  Note: 触发条件：开发者调用 [startPlayingStream] 函数并且拉流选项开启接收 SEI，开始拉混流后触发回调，回调通知周期为 100 ms。
 *
 *  Note: 支持版本：3.0.0
 *
 *  Note: 废弃时间：无
 *
 * @param soundLevels 混流中每条单流的声浪键值对，key 为每条单流的 streamID，value 为对应的单流的声浪值，value 的取值范围为 0.0 ~ 100.0。
 */
type AutoMixerSoundLevelUpdateCallBack = (soundLevels: Map<string, number>) => void;
/**
 * 拉流音轨或视轨更新回调
 *
 * @param streamID 流 ID
 * @param track 拉流上的音轨或视轨
 */
type PlayerTrackUpdateCallBack = (streamID: string, track: MediaStreamTrack) => void;
export interface ZegoEvent extends ZegoRTCEvent, ZegoRTMEvent {
}
export * from "./ZegoRangeAudioEntity.web";
export * from "./ZegoCopyrightedMusicEntity.web";
export * from "./ZegoBackgroundProcessEntity.web";
export * from "./ZegoVoiceChangerEntity.web";
export * from "./ZegoMixStreamEntity";
