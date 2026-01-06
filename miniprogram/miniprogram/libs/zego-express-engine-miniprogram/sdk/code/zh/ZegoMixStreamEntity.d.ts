/**
 * 文本信息。
 *
 * 详情描述: 文本信息配置，可用于配置文本内容、文本位置、文本风格。
 *
 * 业务场景: 手动混流场景时，设置文字水印，比如多人连麦直播。
 *
 */
export interface ZegoLabelInfo {
    /**
     * 是否必填: 是。
     *
     * 取值范围: 最大支持显示100个中文字符，300 个英文字符。
     */
    text: string;
    /**
     * 是否必填: 否。
     *
     * 默认值: 0。
     */
    left?: number;
    /**
     * 是否必填: 否。
     *
     * 默认值: 0。
     */
    top?: number;
    /**
     * 是否必填: 否。
     */
    font?: ZegoFontStyle;
}
export interface ZegoMixStreamConfig {
    /**
     * 混流任务 id（客户自定义,务必保证唯一），必填，最大为256个字符,仅支持数字,英文字符 和 '~', '!', '@', '#', '$', '', '^', '&', '*', '(', ')', '_', '+', '=', '-', ', ';', '’', ',', '
     */
    taskID: string;
    /**
     * 混流输入流列表
     */
    inputList: ZegoMixStreamInput[];
    /**
     * 混流输出流列表
     */
    outputList: string[] | ZegoMixStreamOutput[];
    /**
     * 混流输出配置
     */
    outputConfig: ZegoMixStreamOutputConfig;
    /**
     * 混流任务的水印
     */
    watermark?: ZegoWatermark;
    /**
     * 是否开启混流的声浪回调通知，开启后拉混流时可通过 [onMixerSoundLevelUpdate] 回调收到每条单流的声浪信息
     */
    enableSoundLevel?: boolean;
    /**
     * 混流任务的白板输入信息
     */
    /**
     * 流对齐模式，0 为关闭，1为开启。需先调用 [setStreamAlignmentProperty] 函数开启指定通道的推流网络时间校准的流对齐。
     */
    streamAlignmentMode?: number;
    /**
     * 混流白板输入对象
     */
    whiteboard?: ZegoMixerWhiteboard;
}
export interface ZegoMixStreamInput {
    /**
     * 输入流 ID
     */
    streamID: string;
    /**
     * 混流内容类型;contentType 取值为'VIDEO'(音视频)、'AUDIO'(纯音频),默认为'VIDEO'
     */
    contentType?: "VIDEO" | "AUDIO" | "VIDEO_ONLY";
    /**
     * 流在输出画布上的布局，当 contentType 为 “AUDIO” 时 layout 参数可不传。
     */
    layout?: ZegoMixStreamLayout;
    /**
     * 渲染模式，0 为填充模式，1 为适应模式。
     */
    renderMode?: ZegoMixStreamRenderMode;
    /**
     * 详情描述：用户图片信息。
     */
    imageInfo?: ZegoMixerImageInfo;
    /**
     * 详情描述：文字水印
     */
    label?: ZegoLabelInfo;
    /**
     * 详情描述: 视频画面圆角半径，单位 px。
     *
     * 是否必填: 否。
     *
     * 取值范围: 不超过 [layout] 参数设置的视频画面的宽高。
     *
     * 默认值: 0。
     */
    cornerRadius?: number;
    /**
     * 混流音浪 ID，用于在 [mixerSoundLevelUpdate] 中找对应输入流的音浪值。
     */
    soundLevelID?: number;
    /**
     *  输入流音量, 有效范围 [0, 200], 默认是 100。
     */
    volume?: number;
    /**
     * 当前输入流是否开启焦点语音，开启了会突出此路流的声音。
     */
    isAudioFocus?: boolean;
}
/**
 * 混流视频渲染模式
 *
 * 详情描述：混流视频渲染模式。
 *
 */
export declare enum ZegoMixStreamRenderMode {
    /**
     * 填充模式，等比填充布局，画面可能有部分被裁剪。
     */
    AspectFill = 0,
    /**
     * 适应模式，等比缩放画面，布局内可能有留白。
     */
    AspectFit = 1
}
/**
 * 混流中单条输入流的图片信息
 *
 * Note: 支持版本：2.24.0 及以上。
 *
 * Note: 详情描述：为单条输入流的内容设置图片，用于替代视频，即当使用图片时不显示视频。图片复用的 [ZegoMixerInput] 中的 layout 布局。
 *
 * Note: 业务场景：开发者在视频连麦过程中，需要暂时关闭摄像头显示图像，或音频连麦时，显示图片等。
 *
 * Note: 使用限制：图片大小限制在 1M 以内。
 *
 */
export interface ZegoMixerImageInfo {
    /**
     * 详情描述：图片路径，不为空显示图片，否则显示视频。支持 JPG 和 PNG 格式。支持 2 种使用方式：1. URI：将图片提供给 ZEGO 技术支持进行配置，配置完成后会提供图片 URI，例如：preset-id://xxx.jpg。2. URL：仅支持 HTTP 协议。
     */
    url: string;
    /**
     * 图片显示模式。
     * 0：默认值。当 url 不为空时，覆盖视频内容，显示图片。
     * 1：根据摄像头状态，判断是否显示图片。摄像头关闭，显示图片。摄像头打开，显示视频内容（无需手动清空 url 参数）。
     * 2：根据输入流是否为空流，判断是否显示图片。输入流连续3秒为空流时，显示图片。判断空流时长默认为3秒，若需额外配置请联系 ZEGO 技术支持。输入流有视频数据时，显示视频内容。
     */
    displayMode?: number;
}
/**
 * 字体类型。
 *
 */
export declare enum ZegoFontType {
    /**
     * 思源黑体。
     */
    ZegoFontTypeSourceHanSans = 0,
    /**
     * 阿里巴巴普惠体。
     */
    ZegoFontTypeAlibabaSans = 1,
    /**
     * 旁门正道标题体。
     */
    ZegoFontTypePangMenZhengDaoTitle = 2,
    /**
     * 站酷快乐体。
     */
    ZegoFontTypeHappyZcool = 3
}
/**
 * 字体风格。
 *
 * 详情描述: 字体风格配置，可用于配置字体类型、字体大小、字体颜色、字体透明度。
 *
 * 业务场景: 手动混流场景时，设置文字水印，比如多人连麦直播。
 *
 */
export interface ZegoFontStyle {
    /**
     * 是否必填: 否。
     *
     * 默认值: 思源黑体 [ZegoFontTypeSourceHanSans]。
     */
    type?: ZegoFontType;
    /**
     * 是否必填: 否。
     *
     * 默认值: 24。
     *
     * 取值范围: [12,100] 的整数。
     */
    size?: number;
    /**
     * 是否必填: 否。
     *
     * 默认值: 16777215（白色）。
     *
     * 取值范围: [0,16777215] 的整数。
     */
    color?: number;
    /**
     * 是否必填: 否。
     *
     * 默认值: 0。
     *
     * 取值范围: [0,100]，100 为完全不透明，0 为完全透明。
     */
    transparency?: number;
    /**
     * 是否必填: 否。
     * 默认值: 否。
     * 取值范围: 是/否。
     */
    border?: boolean;
    /**
     * 是否必填: 否。
     * 默认值: 0。
     * 取值范围: [0,16777215]。
     */
    borderColor?: number;
}
/**
 * 混流水印
 *
 * 详情描述: 配置一个水印的图片 URL 以及该水印在画面中的大小方位。
 *
 */
export interface ZegoWatermark {
    /**
     * 详情描述: 水印图片路径。支持本地文件绝对路径 (file://xxx)、Asset 资源路径 (asset://xxx) 和 Android URI 路径 (String path = "uri://" + uri.toString();)。 格式支持 png、jpg。
     */
    imageURL: string;
    /**
     * 详情描述: 水印图片的大小方位
     */
    layout: ZegoMixStreamLayout;
}
export interface ZegoMixStreamOutputConfig {
    /**
     * 混流输出视频码率，kbps
     * 数值 （必须，且大于 0）
     */
    outputBitrate: number;
    /**
     * 混流输出视频帧率
     */
    outputFPS: number;
    /**
     * 混流输出视频分辨率宽度
     */
    outputWidth: number;
    /**
     * 混流输出视频分辨率高度
     */
    outputHeight: number;
    /**
     * 混流输出音频编码
     * outputAudioCodecID 可选0：HE-AAC,1： LC-AAC,2：MP3,3: OPULS 默认为0
     * 注意：如果使用 CDN 录制，音频编码请选择 LC-AAC。这是因为部分浏览器（如 Google Chrome 和 Microsoft Edge）不兼容 HE-AAC 音频编码格式，从而导致录制文件无法播放
     */
    outputAudioCodecID?: 0 | 1 | 2 | 3;
    /**
     * 混流输出音频码率，kbps
     */
    outputAudioBitrate?: number;
    /**
     * 混流输出声道数
     */
    outputAudioChannels?: 1 | 2;
    /**
     * 多路音频流混音模式。若 [ZegoAudioMixMode] 选择为 [Focused]，SDK 将会选择 4 路已设置 [isAudioFocus] 的输入流作为焦点语音突出，若未选择或选择少于 4 路，则会自动补齐 4 路。
     */
    audioMixMode?: ZegoAudioMixMode;
}
export declare enum ZegoAudioMixMode {
    /**
     * 默认模式，无特殊行为
     */
    ZegoAudioMixModeRaw = 0,
    /**
     * 音频聚焦模式，可在多路音频流中突出某路流的声音
     */
    ZegoAudioMixModeFocused = 1
}
/**
 * 混流输入白板对象
 * 配置混流输入的白板 ID、宽高比、布局
 */
export interface ZegoMixerWhiteboard {
    /**
     * 白板 ID
     */
    whiteboardID: string;
    /**
     * 白板原始宽高比（宽），默认宽高比为 16:9
     */
    horizontalRatio?: number;
    /**
     * 白板原始宽高比（高），默认宽高比为 16:9
     */
    verticalRatio?: number;
    /**
     * 白板是否会加载动态 PPT 文件，默认值为 false
     */
    isPPTAnimation?: boolean;
    /**
     * 白板的布局
     */
    layout: ZegoMixStreamLayout;
    /**
     * 白板视图层级
     */
    zOrder?: number;
    /**
     * 白板的背景颜色。默认是 0xF1F3F400 （灰色）。 颜色值对应 RGBA 为 0xRRGGBBAA，目前不支持设置背景色的透明度，0xRRGGBBAA 中的 AA 为 00 即可。例如：选取 RGB 为 #87CEFA 作为背景色，此参数传 0x87CEFA00。
     */
    backgroundColor?: number;
}
export interface ZegoMixStreamLayout {
    /**
     * 目标位置，上
     */
    top: number;
    /**
     * 目标位置，左
     */
    left: number;
    /**
     * 目标位置，下
     */
    bottom: number;
    /**
     * 目标位置，右
     */
    right: number;
}
/**
 * https://doc-zh.zego.im/article/api?doc=express-video-sdk_API~java_android~enum~ZegoAudioCodecID
 */
export declare enum ZegoAudioCodecID {
    ZegoAudioCodecIDNormal = 1,
    ZegoAudioCodecIDNormal2 = 2,
    ZegoAudioCodecIDLow3 = 6
}
/**
 * 详情描述: 配置混流任务的音频码率、声道数、音频编码
 */
export interface ZegoMixerAudioConfig {
    /**
     * 音频码率，单位为 kbps，默认为 48 kbps，开始混流任务后不能修改
     */
    bitrate?: number;
    /**
     * 音频声道，默认为 Mono 单声道
     */
    channel?: 1 | 2;
    codecID?: ZegoAudioCodecID;
}
/**
 * 详情描述: 调用 [StartAutoMixerTask] 函数向 ZEGO RTC 服务器发起自动混流任务时，需要通过该参数配置自动混流任务，包括任务 ID、房间 ID、音频配置、输出流列表、是否开启声浪回调通知。
 * 业务场景: 当向 ZEGO RTC 服务器发起自动混流任务时，需要这个配置。
 * 注意事项: 作为调用 [StartAutoMixerTask] 函数时传入的参数。
 */
export interface ZegoAutoMixerTask {
    /**
     * 混流任务 id（客户自定义,务必保证唯一），必填，最大为256个字符,仅支持数字,英文字符 和 '~', '!', '@', '#', '$', '', '^', '&', '*', '(', ')', '_', '+', '=', '-', ', ';', '’', ',', '
     */
    taskID: string;
    /**
     * 自动混流任务的房间 ID。必填，仅支持数字，英文字符 和 '~', '!', '@', '#', '$', '%', '^', '&', '*', '(', ')', '_', '+', '=', '-', '`', ';', '’', ',', '.', '<', '>', '\'。如果需要与 Web SDK 互通，请不要使用 '%'。
     */
    roomID: string;
    /**
     * 自动混流任务的音频配置，可配置音频码率、音频声道，编码 ID、多路音频流混音模式。
     * 如果对自动混流任务的音频有特殊需求，比如需要调整音频码率，可根据需要调整该参数，否则不用配置。
     * 默认音频码率为 "48 kbps", 默认音频声道为 "ZEGO_AUDIO_CHANNEL_MONO", 默认编码 ID 为 "ZEGO_AUDIO_CODEC_ID_DEFAULT"，默认多路音频流混音模式为 "ZEGO_AUDIO_MIX_MODE_RAW"。
     */
    audioConfig?: ZegoMixerAudioConfig;
    /**
     * 自动混流任务的输出流列表，列表中为 URL 或者流 ID，若为 URL 格式 目前只支持 RTMP URL 格式：rtmp://xxxxxxxx。
     * 当发起自动混流任务时，需要配置该参数指明混流输出目标。Mix stream output target
     * 必填
     */
    outputList: ZegoMixStreamOutput[];
    /**
     * 是否开启自动混流的声浪回调通知，开启后拉混流时可通过 [onAutoMixerSoundLevelUpdate] 回调收到每条单流的声浪信息。
     * 当发起自动混流任务时，如果需要回调流的声浪信息，需要配置该参数。
     * 可选。
     */
    enableSoundLevel?: boolean;
    /**
     * 流对齐模式，0 为关闭，1为开启。需先调用 [setStreamAlignmentProperty] 函数开启指定通道的推流网络时间校准的流对齐。
     */
    streamAlignmentMode?: number;
    /**
     * 设置混流服务器拉流缓存自适应调整的区间范围下限。在实时合唱 KTV 场景下，推流端网络轻微波动可能会导致混流的卡顿，此时观众拉混流的时候，会有比较高概率出现卡顿的问题。通过调节混流服务器拉流缓存自适应调整的区间范围下限，可优化观众端拉混流出现的卡顿问题，但会增大延迟。默认不设置，即服务端使用自身配置值。只会对新的输入流设置生效，对于已经开始混流的输入流不生效。
     *  [0,10000]，超过最大值混流会失败。
     */
    minPlayStreamBufferLength?: number;
}
export interface ZegoMixStreamOutput {
    /**
     * 混流输出流 ID 或 URL
     */
    target: string;
    /**
     * 混流输出视频设置。
     */
    videoConfig?: ZegoMixerOutputVideoConfig;
}
export interface ZegoMixerOutputVideoConfig {
    videoCodecID?: string;
    bitrate?: number;
    encodeProfile?: ZegoEncodeProfile;
    encodeLatency?: number;
    enableLowBitrateHD?: boolean;
}
export declare enum ZegoEncodeProfile {
    ZegoEncodeProfileDefault = 0,
    ZegoEncodeProfileBaseline = 1,
    ZegoEncodeProfileMain = 2,
    ZegoEncodeProfileHigh = 3
}
