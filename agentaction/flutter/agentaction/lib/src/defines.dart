/// 套件内部错误码常量集合。
///
/// 用于 [ZegoAIAgentActionError.code] 与 [ZegoAIAgentActionSendResult.errorCode]。
/// PaaS 端业务错误时 [ZegoAIAgentActionError.code] 会用 PaaS 返回的业务码，
/// 本地套件错误（超时 / 发送失败 / 主动取消）会用这里的预定义值。
class ZegoAIAgentActionErrorCodes {
  /// 请求成功（0）；PaaS 端处理成功时回写此值。
  static const success = 0;

  /// 请求超时（-1）；从发送到收到响应的间隔超过 `timeoutMs` 时触发。
  static const timeout = -1;

  /// 底层 Express 通道发送失败（-2）；通常是 `callExperimentalAPI` 抛错或返回非零。
  static const sendFailed = -2;

  /// 请求被主动取消（-3）；通常由 `ZegoAIAgentActionClient.cancelAll` 触发。
  static const canceled = -3;
}

/// 5 类控制能力对应的 Action 名称常量集合。
///
/// Action 名是后端 aigc-agent 路由分发的依据，必须与 PaaS 接口定义保持一致。
class ZegoAIAgentActionNames {
  /// 主动调用智能体 TTS（让智能体朗读一段文本）。
  static const sendAgentInstanceTTS = 'SendAgentInstanceTTS';

  /// 主动调用智能体 LLM（直接给智能体一段文本，让其基于 LLM 推理并回复）。
  static const sendAgentInstanceLLM = 'SendAgentInstanceLLM';

  /// 打断智能体实例（停止当前 TTS / LLM 推理流程）。
  static const interruptAgentInstance = 'InterruptAgentInstance';

  /// 让智能体开始聆听指定用户（持续关注该用户语音输入）。
  static const startListening = 'StartListening';

  /// 让智能体结束聆听指定用户。
  static const stopListening = 'StopListening';
}

/// Express 协议 `msg_type` 字段的取值集合。
///
/// 上行请求固定使用 [request]（20），下行响应固定使用 [response]（22）。
class ZegoAIAgentActionMsgTypes {
  /// 上行请求（20）。
  static const request = 20;

  /// 下行响应（22）。
  static const response = 22;
}

/// 套件识别的 Express 实验性 API 方法名集合。
///
/// 业务侧实现 Sender 回调时使用 [sendRoomChannelMessage]；处理
/// `onRecvExperimentalAPI` 回调时通过 `method` 字段区分下面三类。
class ZegoAIAgentActionExpressMethods {
  /// 发送房间通道消息的方法名（业务方在 Sender 回调里调用
  /// `ZegoExpressEngine.callExperimentalAPI` 时 method 取此值）。
  static const sendRoomChannelMessage = 'liveroom.room.send_room_channel_message';

  /// 收到房间通道消息的回调方法名（用于接收 PaaS 端业务响应）。
  static const onReciveRoomChannelMessage = 'liveroom.room.on_recive_room_channel_message';

  /// 发送房间通道消息结果的回调方法名（用于接收 Express SDK 的发送结果）。
  static const onSendRoomChannelMessage = 'liveroom.room.on_send_room_channel_message';
}

/// Express 协议 JSON 的外层 / params 字段名常量集合。
///
/// 业务侧在日志 / 透传时如需直接读写 raw JSON，可用这些 key 避免硬编码。
class ZegoAIAgentActionExpressKeys {
  /// 外层 method 字段。
  static const method = 'method';

  /// 外层 params 字段（method 对应的参数体）。
  static const params = 'params';

  /// params.room_id（业务房间 ID）。
  static const roomId = 'room_id';

  /// params.msg_type（请求 20 / 响应 22）。
  static const msgType = 'msg_type';

  /// params.msg_content（业务请求 / 响应的 JSON 字符串）。
  static const msgContent = 'msg_content';

  /// params.user_list（点对点接收方用户 ID 列表）。
  static const userList = 'user_list';

  /// params.seq（Express SDK 用于关联 send 与 result 的内部 seq）。
  static const seq = 'seq';

  /// 发送失败回调 params.error_code（onSendRoomChannelMessage 携带）。
  static const errorCode = 'error_code';

  /// 发送失败回调 params.error_message（onSendRoomChannelMessage 携带）。
  static const errorMessage = 'error_message';
}

/// 业务协议 JSON（msgContent 内的 envelope / 各 Action params）的字段名常量集合。
///
/// 所有业务请求 / 响应的 JSON 字段都使用这套 key 拼装，业务侧如需自定义日志或
/// 调试时直接读写 raw JSON 可引用这里的常量。
class ZegoAIAgentActionProtocolKeys {
  /// envelope.Action（Action 名称，取自 [ZegoAIAgentActionNames]）。
  static const action = 'Action';

  /// envelope.Seq（业务链路追踪标识，格式 `userId:deviceId:localSeq`）。
  static const seq = 'Seq';

  /// envelope.Params（具体 Action 的请求 / 响应参数体）。
  static const params = 'Params';

  /// 响应 Params.Code（0 成功；其它值见 PaaS 错误码定义）。
  static const code = 'Code';

  /// 响应 Params.Message（处理结果说明，失败时为错误信息）。
  static const message = 'Message';

  /// 响应 Params.RequestId（PaaS 调用的接口 RequestId）。
  static const requestId = 'RequestId';

  /// 响应 Params.Data（PaaS 返回的业务数据，可空）。
  static const data = 'Data';

  // Params 内部字段
  /// TTS / LLM 请求 Params.Text（要朗读或对话的文本）。
  static const text = 'Text';

  /// TTS 请求 Params.AddHistory（是否将本次 TTS 文本加入对话历史）。
  static const addHistory = 'AddHistory';

  /// TTS / LLM 请求 Params.Priority（任务优先级枚举字符串，
  /// 默认 `Medium`；与 aigc-agent 接口文档保持一致）。
  static const priority = 'Priority';

  /// TTS / LLM 请求 Params.SamePriorityOption（相同优先级打断策略枚举字符串，
  /// 默认 `ClearAndInterrupt`）。
  static const samePriorityOption = 'SamePriorityOption';

  /// TTS 请求 Params.InterruptMode（打断模式；0 = 默认）。
  static const interruptMode = 'InterruptMode';

  /// TTS / LLM 请求 Params.EnqueueUserSpeech（是否将本轮用户语音也排入队列）。
  static const enqueueUserSpeech = 'EnqueueUserSpeech';

  /// LLM 请求 Params.SystemPrompt（系统提示词，可覆盖智能体默认人设）。
  static const systemPrompt = 'SystemPrompt';

  /// LLM 请求 Params.AddQuestionToHistory（是否将问题加入历史）。
  static const addQuestionToHistory = 'AddQuestionToHistory';

  /// LLM 请求 Params.AddAnswerToHistory（是否将答案加入历史）。
  static const addAnswerToHistory = 'AddAnswerToHistory';

  /// StartListening / StopListening 请求 Params.UserId（要聆听 / 结束聆听的用户 ID）。
  static const userId = 'UserId';
}
