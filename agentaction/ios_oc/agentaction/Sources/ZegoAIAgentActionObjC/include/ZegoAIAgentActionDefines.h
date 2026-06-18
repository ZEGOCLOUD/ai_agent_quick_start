#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 套件内部错误码常量集合。
///
/// 用于 `ZegoAIAgentActionOCError.code` 与 `ZegoAIAgentActionOCSendResult.errorCode`。
/// PaaS 端业务错误时 `ZegoAIAgentActionOCError.code` 会用 PaaS 返回的业务码，
/// 本地套件错误（超时 / 发送失败 / 主动取消）会用这里的预定义值。
@interface ZegoAIAgentActionErrorCodes : NSObject
/// 请求成功（0）；PaaS 端处理成功时回写此值。
@property (class, nonatomic, readonly) NSInteger success;
/// 请求超时（-1）；从发送到收到响应的间隔超过 `timeoutMs` 时触发。
@property (class, nonatomic, readonly) NSInteger timeout;
/// 底层 Express 通道发送失败（-2）；通常是 `callExperimentalAPI` 抛错或返回非零。
@property (class, nonatomic, readonly) NSInteger sendFailed;
/// 请求被主动取消（-3）；通常由 `cancelAllWithMessage:` 触发。
@property (class, nonatomic, readonly) NSInteger canceled;
@end

/// 5 类控制能力对应的 Action 名称常量集合。
///
/// Action 名是后端 `aigc-agent` 路由分发的依据，必须与 PaaS 接口定义保持一致。
@interface ZegoAIAgentActionNames : NSObject
/// 主动调用智能体 TTS（让智能体朗读一段文本）。
@property (class, nonatomic, readonly) NSString *sendAgentInstanceTTS;
/// 主动调用智能体 LLM（直接给智能体一段文本，让其基于 LLM 推理并回复）。
@property (class, nonatomic, readonly) NSString *sendAgentInstanceLLM;
/// 打断智能体实例（停止当前 TTS / LLM 推理流程）。
@property (class, nonatomic, readonly) NSString *interruptAgentInstance;
/// 让智能体开始聆听指定用户（持续关注该用户语音输入）。
@property (class, nonatomic, readonly) NSString *startListening;
/// 让智能体结束聆听指定用户。
@property (class, nonatomic, readonly) NSString *stopListening;
@end

/// Express 协议 `msg_type` 字段的取值集合。
///
/// 上行请求固定使用 `request`（20），下行响应固定使用 `response`（22）。
@interface ZegoAIAgentActionMsgTypes : NSObject
/// 上行请求（20）。
@property (class, nonatomic, readonly) NSInteger request;
/// 下行响应（22）。
@property (class, nonatomic, readonly) NSInteger response;
@end

/// 套件识别的 Express 实验性 API 方法名集合。
///
/// 业务侧实现 Sender 回调时使用 `sendRoomChannelMessage`；处理
/// `onRecvExperimentalAPI` 回调时通过 `method` 字段区分下面三类。
@interface ZegoAIAgentActionExpressMethods : NSObject
/// 发送房间通道消息的方法名（业务方在 Sender 回调里调用
/// `ZegoExpressEngine.callExperimentalAPI` 时 method 取此值）。
@property (class, nonatomic, readonly) NSString *sendRoomChannelMessage;
/// 收到房间通道消息的回调方法名（用于接收 PaaS 端业务响应）。
@property (class, nonatomic, readonly) NSString *onReciveRoomChannelMessage;
/// 发送房间通道消息结果的回调方法名（用于接收 Express SDK 的发送结果）。
@property (class, nonatomic, readonly) NSString *onSendRoomChannelMessage;
@end

/// Express 协议 JSON 的外层 / params 字段名常量集合。
///
/// 业务侧在日志 / 透传时如需直接读写 raw JSON，可用这些 key 避免硬编码。
@interface ZegoAIAgentActionExpressKeys : NSObject
/// 外层 method 字段。
@property (class, nonatomic, readonly) NSString *method;
/// 外层 params 字段（method 对应的参数体）。
@property (class, nonatomic, readonly) NSString *params;
/// params.room_id（业务房间 ID）。
@property (class, nonatomic, readonly) NSString *roomId;
/// params.msg_type（请求 20 / 响应 22）。
@property (class, nonatomic, readonly) NSString *msgType;
/// params.msg_content（业务请求 / 响应的 JSON 字符串）。
@property (class, nonatomic, readonly) NSString *msgContent;
/// params.user_list（点对点接收方用户 ID 列表）。
@property (class, nonatomic, readonly) NSArray<NSString *> *userList;
/// params.seq（Express SDK 用于关联 send 与 result 的内部 seq）。
@property (class, nonatomic, readonly) NSString *seq;
/// 发送失败回调 params.error_code（onSendRoomChannelMessage 携带）。
@property (class, nonatomic, readonly) NSString *errorCode;
/// 发送失败回调 params.error_message（onSendRoomChannelMessage 携带）。
@property (class, nonatomic, readonly) NSString *errorMessage;
@end

/// 业务协议 JSON（msg_content 内的 envelope / 各 Action params）的字段名常量集合。
///
/// 所有业务请求 / 响应的 JSON 字段都使用这套 key 拼装，业务侧如需自定义日志或
/// 调试时直接读写 raw JSON 可引用这里的常量。
@interface ZegoAIAgentActionProtocolKeys : NSObject
/// envelope.Action（Action 名称，取自 ZegoAIAgentActionNames）。
@property (class, nonatomic, readonly) NSString *action;
/// envelope.Seq（业务链路追踪标识，格式 `userId:deviceId:localSeq`）。
@property (class, nonatomic, readonly) NSString *seq;
/// envelope.Params（具体 Action 的请求 / 响应参数体）。
@property (class, nonatomic, readonly) NSString *params;
/// 响应 Params.Code（0 成功；其它值见 PaaS 错误码定义）。
@property (class, nonatomic, readonly) NSString *code;
/// 响应 Params.Message（处理结果说明，失败时为错误信息）。
@property (class, nonatomic, readonly) NSString *message;
/// 响应 Params.RequestId（PaaS 调用的接口 RequestId）。
@property (class, nonatomic, readonly) NSString *requestId;
/// 响应 Params.Data（PaaS 返回的业务数据，可空）。

@property (class, nonatomic, readonly) NSString *data;

// Params 内部字段
/// TTS / LLM 请求 Params.Text（要朗读或对话的文本）。
@property (class, nonatomic, readonly) NSString *text;
/// TTS 请求 Params.AddHistory（是否将本次 TTS 文本加入对话历史）。
@property (class, nonatomic, readonly) NSString *addHistory;
/// TTS / LLM 请求 Params.Priority（任务优先级枚举字符串，
/// 默认 `Medium`；与 aigc-agent 接口文档保持一致）。
@property (class, nonatomic, readonly) NSString *priority;
/// TTS / LLM 请求 Params.SamePriorityOption（相同优先级打断策略枚举字符串，
/// 默认 `ClearAndInterrupt`）。
@property (class, nonatomic, readonly) NSString *samePriorityOption;
/// TTS 请求 Params.InterruptMode（打断模式；0 = 默认）。
@property (class, nonatomic, readonly) NSString *interruptMode;
/// TTS / LLM 请求 Params.EnqueueUserSpeech（是否将本轮用户语音也排入队列）。
@property (class, nonatomic, readonly) NSString *enqueueUserSpeech;
/// LLM 请求 Params.SystemPrompt（系统提示词，可覆盖智能体默认人设）。
@property (class, nonatomic, readonly) NSString *systemPrompt;
/// LLM 请求 Params.AddQuestionToHistory（是否将问题加入历史）。
@property (class, nonatomic, readonly) NSString *addQuestionToHistory;
/// LLM 请求 Params.AddAnswerToHistory（是否将答案加入历史）。
@property (class, nonatomic, readonly) NSString *addAnswerToHistory;
/// StartListening / StopListening 请求 Params.UserId（要聆听 / 结束聆听的用户 ID）。
@property (class, nonatomic, readonly) NSString *userId;
/// StartListening / StopListening 请求 Params.Sequence（客户端自增序列号；不传则按后台接收顺序处理）。
@property (class, nonatomic, readonly) NSString *sequence;
@end

NS_ASSUME_NONNULL_END
