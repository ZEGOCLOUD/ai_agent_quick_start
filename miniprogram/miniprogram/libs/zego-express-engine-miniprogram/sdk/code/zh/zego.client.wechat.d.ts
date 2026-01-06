import { PlayerAttributes, PusherAttributes } from "../../src/common/zego.entity.wechat";
import { ZegoAutoMixerTask, ZegoEvent, ZegoMixStreamAdvance, ZegoMixStreamConfig, ZegoServerResponse, ZegoWxPlayOption, ZegoWxPublishOption } from "./ZegoExpressEntity.wechat";
import { LivePusher } from "../../src/wechatMini/modules/pusher";
import { LivePlayer } from "../../src/wechatMini/modules/player";
import { ZegoExpressWebRTMEngine } from "./zego.client.rtm";
/**
 * 实时音视频引擎
 *
 * Note: 详情描述：该类用于初始化 Express SDK 引擎实例。
 *
 */
export declare class ZegoExpressEngine extends ZegoExpressWebRTMEngine {
    private zegoWechatMini;
    /**
       * 初始化 Engine
       *
       * Note: 支持版本：1.0.0
       *
       * Note: 详情描述：实例化对象。
       *
       * Note: 业务场景：所有场景必须。
       *
       * Note: 默认值：无默认值，所有参数必须填写。
       *
       * Note: 调用时机：第一个调用。
       *
       * Note: 使用限制：无
       *
       * Note: 注意事项：server 建议填写数组，备用域名抗弱网能力更强。
       *
       * Note: 影响范围：无
       *
       * Note: 相关回调：无
       *
       * Note: 相关接口：无
       *
       * Note: 平台差异：无
       *
       * @param appID 用于区分不同客户和项目的唯一标识（必须为 number 类型），且必须从即构控制台获取。一个 appID 对应一个客户项目，不同端共有一个 appID 实现互通 ，一个客户可以申请多个 appID。
  
       * @param server 表示 SDK 连接的即构服务器地址（支持备用域名），必须从控制台获取，SDK 内的大多数功能都通过该服务器地址交互 。同一个 appID 可以填写多个 server。
       */
    constructor(appID: number, server: string | string[]);
    /**
     * 获取新的流地址
     *
     * Note: 支持版本：2.0.0 及以上。
     *
     * Note: 详情描述：传给小程序组件的推流地址推流失败后，可通过该接口获取下一个推流地址。
     *
     * Note: 业务场景：获取推流地址。
     *
     * Note: 调用时机：调用接口 startPublishingStream 推流成功之后。
     *
     * Note: 安全性提醒：请勿在此接口填写用户敏感信息，包括但不限于手机号、身份证号、护照编号、真实姓名等。
     *
     * @param streamID 媒体流 ID。
     *
     * @return 新的推流地址。
     */
    getNextUrl(streamID: string): string;
    /**
     * 开始拉流
     *
     * Note: 支持版本：1.0.0 及以上。
     *
     * Note: 详情描述：调用拉流接口获取拉流地址。
     *
     * Note: 业务场景：拉流时必选。
     *
     * Note: 调用时机：收到新增拉流，即 roomStreamUpdate 回调后。
     *
     * Note: 注意事项： 拉流前确保该条流已经推成功（推送到 ZEGO 服务器），即拉流是在 roomStreamUpdate 回调后。
     *
     * Note: 相关回调：拉流质量回调 playQualityUpdate，拉流状态回调 playerStateUpdate （可通过该回调来判断拉流是否成功）。
     *
     * Note: 相关接口：调用接口 stopPlayStream 结束拉流。
     *
     * @param streamID 流 ID ，必填。
     * @param playOption? 拉流附加参数，可选。
     *
     * @return promise 异步返回流媒体对象。
     */
    startPlayingStream(streamID: string, playOption?: ZegoWxPlayOption): Promise<{
        streamID: string;
        url: string;
    }>;
    /**
     * 停止拉取远端流（即构服务器）
     *
     * Note: 支持版本：1.0.0
     *
     * Note: 详情描述：停止拉流，断开和即构服务器之间的连接，不再产生带宽。
     *
     * Note: 业务场景：拉流必选。
     *
     * Note: 默认值：无
     *
     * Note: 调用时机：拉流成功后。
     *
     * Note: 使用限制：无
     *
     * Note: 注意事项： 停止拉流后不会销毁播放器，播放器销毁需要开发者自己实现。
     *
     * Note: 影响范围：无
     *
     * Note: 相关回调：拉流质量回调 playQualityUpdate，拉流状态回调 playerStateUpdate。
     *
     * Note: 相关接口：开始拉流 startPlayStream。
     *
     * Note: 平台差异：无
     *
     * @param streamID 流 ID
     */
    stopPlayingStream(streamID: string): void;
    /**
     * 小程序组件网络状态通知事件
     *
     * Note: 支持版本：1.0.0 及以上。
     *
     * Note: 详情描述：在小程序 <live-player> 和 <live-pusher> 组件中设置 bindnetstatus 属性，小程序回调的事件完全透传给 SDK 。
     *
     * Note: 业务场景：推拉流功能需要。
     *
     * Note: 调用时机：在小程序 <live-player> 和 <live-pusher> 组件触发 bindnetstatus 事件时调用。
     *
     * Note: 安全性提醒：请勿在此接口填写用户敏感信息，包括但不限于手机号、身份证号、护照编号、真实姓名等。
     *
     * @param streamID 媒体流 ID。
     * @param event 回调函数的事件对象。
     */
    updatePlayerNetStatus(streamID: string, event: any): void;
    /**
     * 推拉流状态更新回调处理
     *
     * Note: 支持版本：1.0.0 及以上。
     *
     * Note: 详情描述：在小程序 <live-player> 和 <live-pusher> 组件中设置 bindstatechange 属性，小程序回调的事件完全透传给 SDK 。
     *
     * Note: 业务场景：推拉流功能需要。
     *
     * Note: 调用时机：在小程序 <live-player> 和 <live-pusher> 组件触发 bindstatechange 事件时调用。
     *
     * Note: 注意事项：SDK 底层会根据 event 进行流状态更新，必须将回调消息传给 SDK 。
     *
     * Note: 安全性提醒：请勿在此接口填写用户敏感信息，包括但不限于手机号、身份证号、护照编号、真实姓名等。
     *
     * Note: 相关回调：推流状态回调 publisherStateUpdate。
     *
     * @param streamID 媒体流 ID。
     * @param event 回调函数的事件对象。
     */
    updatePlayerState(streamID: string, event: any): void;
    updateAudioVolumeNotify(streamID: string, event: any): void;
    /**
     * 支持能力检测接口
     *
     * Note: 支持版本：1.0.0
     *
     * Note: 详情描述：检测微信小程序兼容性。
     *
     * Note: 业务场景：用于判断微信版本和权限的场景。
     *
     * Note: 默认值：none
     *
     * Note: 调用时机：初始化之后，推（拉）流之前调用。
     *
     * Note: 使用限制：无
     *
     * Note: 注意事项：强烈推荐使用。
     *
     * Note: 影响范围：无
     *
     * Note: 相关回调：无
     *
     * Note: 相关接口：无
     *
     * Note: 平台差异：无
     *
     * @return 返回检测结果。code 为 0 表示支持；code 为 10001 表示当前微信版本过低，无法使用相关组件；code 为 10002 表示需要摄像头和录音功能的授权。
     */
    checkSystemRequirements(): Promise<{
        code: number;
        msg: string;
    }>;
    /**
     * 混流高级配置
     *
     * Note: 支持版本：1.5.2 及以上。
     *
     * Note: 详情描述：混流功能进阶设置，可以设置视频背景和视频编码格式。
     *
     * Note: 业务场景：1. 设置混流画面背景；2. 视频编码转换来兼容部分浏览器的播放。
     *
     * Note: 调用时机：推流成功后，而且需在使用 startMixerTask 之前调用才能生效。
     *
     * Note: 安全性提醒：请勿在此接口填写用户敏感信息，包括但不限于手机号、身份证号、护照编号、真实姓名等。
     *
     * Note: 相关接口：开始混流接口 startMixerTask
     *
     * @param config 混流高级功能设置。
     */
    setMixerTaskConfig(config: ZegoMixStreamAdvance): Promise<ZegoServerResponse>;
    /**
     * 开始混流任务
     *
     * Note: 支持版本：1.5.2 及以上。
     *
     * Note: 详情描述：将多条流按照调用要求合成一条流。 由那个点于实际动作是在服务端操作，没有浏览器性能上的限制，且各个流之间延迟低，可以保证被混的多条流画面和声音同步。
     *
     * Note: 业务场景：通常用于多个主播连麦PK的场景，将多个主播的音视频流混合成一条流，观众端只需要拉这一条流。
     *
     * Note: 调用时机：调用接口 startPublishingStream 推流成功后。
     *
     * Note: 使用限制：混流前需要保证流还存在，避免发起混流和流删除操作同时触发，以免混流失败。被混的流如果中止推流，需要重新做混流处理，否则对端画面会卡住。
     *
     * Note: 注意事项：1. 应用对应的 AppID 开启了混流功能；2. 被混的流必须在 ZEGO 服务器上存在；3. 混流输入流列表接口 inputList 中的 “contentType” 均为 “AUDIO” 时，ZegoMixStreamOutputConfig 类下的 outputBitrate 、outputFPS 、outputWidth 、outputHeight 属性可不设置，默认设置为 “1”。
     *
     * Note: 安全性提醒：请勿在此接口填写用户敏感信息，包括但不限于手机号、身份证号、护照编号、真实姓名等。
     *
     * Note: 相关接口： 使用接口 stopMixerTask 来停止服务端混流，未及时停止混流功能会影响计费。
     *
     * @param mixStreamConfig 混流参数配置
     */
    startMixerTask(mixStreamConfig: ZegoMixStreamConfig): Promise<ZegoServerResponse>;
    /**
     * 开始自动混流任务
     *
     * Note: 支持版本：3.5.0 及以上。
     *
     * Note: 详情描述：本地用户可调用该函数开始自动混流任务，对房间内的所有流进行混流，目前仅支持音频流自动混流。启动自动混流后，会自动混流该房间内所有流的音频，此房间内再发起的推流也会自动混入最后的输出流中。
     *
     * Note: 业务场景：常用于语聊房场景下，需要由客户端发起自动混流任务时。
     *
     * Note: 调用时机：在创建引擎后，如果目标房间已经创建，可调用该函数在目标房间开启自动混流。
     *
     * Note: 注意事项：在同一个房间内开启下一个自动混流任务前，请先调用 [stopAutoMixerTask] 函数结束上一次自动混流任务，以免造成当一个主播已经开启下一个自动混流任务与其他主播混流时，观众依然在一直拉上一个自动混流任务的输出流的情况。若用户未主动结束当前自动混流任务，该任务将在房间不存在之后或者输入流持续 90 秒不存在之后自动结束。
     *
     * Note: 安全性提醒：请勿在此接口填写用户敏感信息，包括但不限于手机号、身份证号、护照编号、真实姓名等。
     *
     * Note: 相关接口： 使用接口 stopAutoMixerTask 来停止服务端自动混流，未及时停止混流功能会影响计费。
     *
     * @param mixStreamConfig 混流参数配置
     */
    startAutoMixerTask(task: ZegoAutoMixerTask): Promise<ZegoServerResponse>;
    /**
     * 停止服务端自动混流
     *
     * Note: 支持版本：3.5.0 及以上。
     *
     * Note: 详情描述：本地用户可调用该函数结束自动混流任务。
     *
     * Note: 业务场景：常用于语聊房场景下，需要由客户端发起自动混流任务时。
     *
     * Note: 调用时机：在调用 [startAutoMixerTask] 函数开启自动混流任务后可调用该函数。
     *
     * Note: 注意事项：在同一个房间内开启下一个自动混流任务前，请先调用 [stopAutoMixerTask] 函数结束上一次自动混流任务，以免造成当一个主播已经开启下一个自动混流任务与其他主播混流时，观众依然在一直拉上一个自动混流任务的输出流的情况。若用户未主动结束当前自动混流任务，该任务将在房间不存在之后或者输入流持续 90 秒不存在之后自动结束。
     *
     * Note: 安全性提醒：请勿在此接口填写用户敏感信息，包括但不限于手机号、身份证号、护照编号、真实姓名等。
     *
     * Note: 相关接口： 开始混流任务接口 startAutoMixerTask
     *
     * @param taskID 混流任务 ID（客户自定义，务必保证唯一），必填，最大长度为 256 个字符，仅支持数字、英文字符 和 '~', '!', '@', '#', '$', '', '^', '&', '*', '(', ')', '_', '+', '=', '-', ', ';', '’', ',', '
     */
    stopAutoMixerTask(task: {
        taskID: string;
        roomID: string;
    }): Promise<ZegoServerResponse>;
    /**
     * 删除注册过的回调事件
     *
     * Note: 支持版本：1.0.0
     *
     * Note: 详情描述：ZegoEvent 包括了 [ZegoWechatMiniEvent](https://doc-zh.zego.im/article/api?doc=Express_Video_SDK_API~javascript_wxxcx~interface~ZegoWechatMiniEvent&) 与 [ZegoRTMEvent](https://doc-zh.zego.im/article/api?doc=Express_Video_SDK_API~javascript_web~interface~ZegoRTMEvent)， 用于处理 SDK 主动通知开发者回调的接口，用于删除注册的同一类回调事件。
     *
     * Note: 业务场景：通用接口，必选。
     *
     * Note: 支默认值：无
     *
     * Note: 调用时机：注册之后，退出房间之前。
     *
     * Note: 使用限制：无
     *
     * Note: 注意事项：同类事件有多个时，都会被删除。
     *
     * Note: 影响范围：无
     *
     * Note: 相关回调：无
     *
     * Note: 相关接口：无
     *
     * Note: 平台差异：无
     *
     * @param event 监听事件名
     * @param callBack? 回调函数，可选
     */
    off<K extends keyof ZegoEvent>(event: K, callBack?: ZegoEvent[K]): boolean;
    /**
     * 停止服务端混流
     *
     * Note: 支持版本：1.5.2 及以上。
     *
     * Note: 详情描述：用于停止 taskID 对应的服务端混流任务。
     *
     * Note: 业务场景：通常用于多个主播连麦 PK 的场景，混流画面使用结束后停止混流。
     *
     * Note: 调用时机：调用接口 startMixerTask 混流成功之后。
     *
     * Note: 注意事项：关闭页面一定要发起停止混流，避免异常关闭导致混流没有停止，影响计费；被混的流若中止推流，需要重新做混流处理，否则对端画面会卡住。
     *
     * Note: 安全性提醒：请勿在此接口填写用户敏感信息，包括但不限于手机号、身份证号、护照编号、真实姓名等。
     *
     * Note: 相关接口： 开始混流任务接口 startMixerTask
     *
     * @param taskID 混流任务 ID（客户自定义，务必保证唯一），必填，最大长度为 256 个字符，仅支持数字、英文字符 和 '~', '!', '@', '#', '$', '', '^', '&', '*', '(', ')', '_', '+', '=', '-', ', ';', '’', ',', '
     */
    stopMixerTask(taskID: string): Promise<ZegoServerResponse>;
    /**
     * 注册回调事件
     *
     * Note: 支持版本：1.0.0 及以上
     *
     * Note: 详情描述：ZegoEvent 包括了 [ZegoWechatMiniEvent](https://doc-zh.zego.im/article/api?doc=Express_Video_SDK_API~javascript_wxxcx~interface~ZegoWechatMiniEvent&) 与 [ZegoRTMEvent](https://doc-zh.zego.im/article/api?doc=Express_Video_SDK_API~javascript_web~interface~ZegoRTMEvent) ，用于处理 SDK 主动通知开发者回调的接口，通过注册不同 event 的事件，可以收到不同功能的回调。
     *
     * Note: 业务场景：通用接口，用于监听 SDK 的业务事件。
     *
     * Note: 调用时机：初始化实例之后，调用接口 loginRoom 登录房间之前。
     *
     * Note: 注意事项：同样的事件可以注册多个，相同的注册事件，会根据注册的先后顺序依次触发。
     *
     * Note: 相关接口：调用接口 off 来注销对应回调事件处理。
     *
     * @param event 监听事件名。
     * @param callBack 回调函数。
     *
     * @return 注册是否成功。
     */
    on<K extends keyof ZegoEvent>(event: K, callBack: ZegoEvent[K]): boolean;
    /**
     * 开始推流
     *
     * Note: 支持版本：1.0.0 及以上。
     *
     * Note: 详情描述：调用推流接口获取推流地址。
     *
     * Note: 业务场景：推流时必选。
     *
     * Note: 调用时机：调用接口 loginRoom 登录房间成功后。
     *
     * Note: 相关回调：推流质量回调 publishQualityUpdate，推流状态回调 publisherStateUpdate（可通过该接口来判断推流是否成功）。
     *
     * Note: 相关接口：通过调用接口 stopPublishingStream 结束推流。
     *
     * @param streamID 推流 ID，长度不超过256的字符串，仅支持数字，英文字符 和 '~', '!', '@', '#', '$', '', '^', '&', '*', '(', ')', '_', '+', '=', '-', ', ';', '’', ',', '.', '<', '>', '/', ''
     * @param publishOption? 推拉附加参数（鉴权、视频编码），可选。
     *
     * @return true 表示客户端发送请求成功，流成功推送到服务器需要通过流状态回调接口判断。
     */
    startPublishingStream(streamID: string, publishOption?: ZegoWxPublishOption): Promise<{
        streamID: string;
        url: string;
    }>;
    /**
     * 停止将本地流推送到远端（即构服务器）
     *
     * Note: 支持版本：1.0.0
     *
     * Note: 详情描述：停止推流。
     *
     * Note: 业务场景：推流时必选。
     *
     * Note: 默认值：无
     *
     * Note: 调用时机：推流成功后。
     *
     * Note: 使用限制：无
     *
     * Note: 注意事项： 停止推流不会导致渲染的 <video> 画面暂停，开发者需自行销毁 <video>。
     *
     * Note: 影响范围：无
     *
     * Note: 相关回调：推流质量回调 publishQualityUpdate，推流状态回调 publisherStateUpdate。
     *
     * Note: 相关接口：开始推流 startPublishingStream。
     *
     * Note: 平台差异：无
     *
     * @param streamID 推流 ID,和推流streamID保持一致
     */
    stopPublishingStream(streamID: string): boolean;
    /**
     * 通知即构服务器将流转推到CDN
     *
     * Note: 支持版本：1.0.0
     *
     * Note: 详情描述：当需要将音视频流转推到其它指定的 CDN 时，需要调用此接口进行设置（调用前请先联系 ZEGO 技术支持配置转推 CDN 功能）。
     *
     * Note: 业务场景：单向直播场景，拉流端使用 CDN 拉流。
     *
     * Note: 默认值：无
     *
     * Note: 调用时机：推流成功后。
     *
     * Note: 使用限制：无
     *
     * Note: 注意事项：
     *      建议使用服务端动态转推 CDN 中的增加转推 CDN 地址 API 替代该客户端 API。
     *      该接口调用有可能会失败，若返回成功，仅代表通知即构服务器成功，无法判断即构服务器是否转推 CDN 成功。
     *
     * Note: 影响范围：无
     *
     * Note: 相关回调：无
     *
     * Note: 相关接口：通知即构服务器停止将流转推到 CDN removePublishCdnUrl。
     *
     * Note: 平台差异：无
     *
     * @param streamID 推流 ID
     * @param targetURL CDN 转推地址，支持的转推地址格式有 rtmp
     */
    addPublishCdnUrl(streamID: string, targetURL: string): Promise<ZegoServerResponse>;
    /**
     * 通知即构服务器停止将流转推到 CDN
     *
     * Note: 支持版本：1.0.0
     *
     * Note: 详情描述： 当已经添加了某个 CDN 转推地址，需要停止将流转推至该 CDN 时调用此接口（调用前请先联系 ZEGO 技术支持配置转推 CDN 功能）。
     *
     * Note: 业务场景：单向直播场景，拉流端使用 CDN 拉流。
     *
     * Note: 默认值：无
     *
     * Note: 调用时机：转推成功后
     *
     * Note: 使用限制：无
     *
     * Note: 注意事项：
     *      建议使用服务端动态转推 CDN 中的增加转推 CDN 地址 API 替代该客户端 API。
     *      该接口调用有可能会失败，若返回成功，仅代表通知即构服务器成功，无法判断即构服务器是否转推 CDN 成功。
     *
     * Note: 影响范围：无
     *
     * Note: 相关回调：无
     *
     * Note: 相关接口：通知即构服务器将流转推到 CDN addPublishCdnUrl。
     *
     * Note: 平台差异：无
     *
     * @param streamID 推流 ID
     * @param targetURL CDN 转推地址，支持的转推地址格式有 rtmp
     */
    removePublishCdnUrl(streamID: string, targetURL: string): Promise<ZegoServerResponse>;
    /**
     * 设置流的附加信息
     *
     * Note: 支持版本：1.0.0
     *
     * Note: 详情描述： 更改流附加信息。
     *
     * Note: 业务场景：需要对推流进行更丰富的描述，且希望拉流端能接受到这些信息时使用。
     *
     * Note: 默认值：无
     *
     * Note: 调用时机：推流成功后。
     *
     * Note: 使用限制：无
     *
     * Note: 注意事项： 只支持字符串。
     *
     * Note: 影响范围：无
     *
     * Note: 相关回调：流附加信息回调 streamExtraInfoUpdate。
     *
     * Note: 相关接口：无
     *
     * Note: 平台差异：无
     *
     * @param streamID 推流 ID
     * @param extraInfo 流附加信息; extraInfo为json格式字符串
     */
    setStreamExtraInfo(streamID: string, extraInfo: string): Promise<ZegoServerResponse>;
    static use(module: any): void;
    initContext(obj: {
        wxContext?: any;
        pushAtr?: string;
        playAtr?: string;
    }): void;
    createPusher(config?: PusherAttributes): LivePusher | null;
    getPusherInstance(): LivePusher | null;
    getPlayerInstance(streamID: string, wxContext?: any): LivePlayer | null;
    mutePublishStreamVideo(bool: boolean): void;
    mutePublishStreamAudio(bool: boolean): void;
    mutePlayStreamVideo(streamID: string, bool: boolean): void;
    mutePlayStreamAudio(streamID: string, bool: boolean): void;
    setPusherAttributes(config: PusherAttributes): void;
    setPlayerAttributes(streamID: string, config: PlayerAttributes): void;
    getPlayerList(streamID?: string): Array<LivePlayer["attributes"]>;
    /**
     * 销毁 ZegoExpressEngine 引擎实例
     *
     * Note: 支持版本：3.5.0
     *
     * Note: 详情描述：销毁引擎对象
     *
     * Note: 业务场景：所有场景。
     *
     * Note: 默认值：无默认值。
     *
     * Note: 调用时机：同一个引擎实例最后一个调用的接口。
     *
     * Note: 使用限制：无
     *
     * Note: 注意事项：销毁引擎后应及时将实例化对象置空，并不应再调用引擎对象的其他接口，否则可能出现意想不到的问题。
     *
     * Note: 影响范围：无
     *
     * Note: 相关回调：无
     *
     * Note: 相关接口：无
     *
     * Note: 平台差异：无
     */
    destroyEngine(): void;
}
