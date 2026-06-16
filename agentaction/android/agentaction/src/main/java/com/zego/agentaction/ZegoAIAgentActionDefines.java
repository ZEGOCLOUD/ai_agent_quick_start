package com.zego.agentaction;

/**
 * 套件对外暴露的协议常量集合（错误码 / Express 协议字段名 / 业务协议字段名）。
 *
 * <p>所有常量均对应 PaaS（aigc-agent）接口文档定义，请勿随意修改取值。
 */
public class ZegoAIAgentActionDefines {
    /**
     * 套件内部错误码常量集合。
     *
     * <p>用于 {@code ZegoAIAgentActionError.code} 与 {@code ZegoAIAgentActionSendResult.errorCode}。
     * PaaS 端业务错误时 {@code ZegoAIAgentActionError.code} 会用 PaaS 返回的业务码，
     * 本地套件错误（超时 / 发送失败 / 主动取消）会用这里的预定义值。
     */
    public static class ErrorCodes {
        /// 请求成功（0）；PaaS 端处理成功时回写此值。
        public static final int SUCCESS = 0;
        /// 请求超时（-1）；从发送到收到响应的间隔超过 {@code timeoutMs} 时触发。
        public static final int TIMEOUT = -1;
        /// 底层 Express 通道发送失败（-2）；通常是 {@code callExperimentalAPI} 抛错或返回非零。
        public static final int SEND_FAILED = -2;
        /// 请求被主动取消（-3）；通常由 {@code ZegoAIAgentActionClient.cancelAll(String)} 触发。
        public static final int CANCELED = -3;
    }

    /**
     * 5 类控制能力对应的 Action 名称常量集合。
     *
     * <p>Action 名是后端 aigc-agent 路由分发的依据，必须与 PaaS 接口定义保持一致。
     */
    public static class ActionNames {
        /// 主动调用智能体 TTS（让智能体朗读一段文本）。
        public static final String SEND_AGENT_INSTANCE_TTS = "SendAgentInstanceTTS";
        /// 主动调用智能体 LLM（直接给智能体一段文本，让其基于 LLM 推理并回复）。
        public static final String SEND_AGENT_INSTANCE_LLM = "SendAgentInstanceLLM";
        /// 打断智能体实例（停止当前 TTS / LLM 推理流程）。
        public static final String INTERRUPT_AGENT_INSTANCE = "InterruptAgentInstance";
        /// 让智能体开始聆听指定用户（持续关注该用户语音输入）。
        public static final String START_LISTENING = "StartListening";
        /// 让智能体结束聆听指定用户。
        public static final String STOP_LISTENING = "StopListening";
    }

    /**
     * Express 协议 {@code msg_type} 字段的取值集合。
     *
     * <p>上行请求固定使用 {@link #MSG_TYPE_REQUEST}，下行响应固定使用 {@link #MSG_TYPE_RESPONSE}。
     */
    public static class MsgTypes {
        /// 上行请求（20）。
        public static final int MSG_TYPE_REQUEST = 20;
        /// 下行响应（22）。
        public static final int MSG_TYPE_RESPONSE = 22;
    }

    /**
     * 套件识别的 Express 实验性 API 方法名集合。
     *
     * <p>业务侧实现 Sender 回调时使用 {@link #sendRoomChannelMessage}；处理
     * {@code onRecvExperimentalAPI} 回调时通过 {@code method} 字段区分下面三类。
     */
    public static class ExpressMethods {
        /// 发送房间通道消息的方法名（业务方在 Sender 回调里调用
        /// {@code ZegoExpressEngine.callExperimentalAPI} 时 method 取此值）。
        public static final String sendRoomChannelMessage = "liveroom.room.send_room_channel_message";

        /// 收到房间通道消息的回调方法名（用于接收 PaaS 端业务响应）。
        public static final String onReciveRoomChannelMessage = "liveroom.room.on_recive_room_channel_message";

        /// 发送房间通道消息结果的回调方法名（用于接收 Express SDK 的发送结果）。
        public static final String onSendRoomChannelMessage = "liveroom.room.on_send_room_channel_message";
    }

    /**
     * Express 协议 JSON 的外层 / params 字段名常量集合。
     *
     * <p>业务侧在日志 / 透传时如需直接读写 raw JSON，可用这些 key 避免硬编码。
     */
    public static class ExpressKeys {
        /// 外层 method 字段。
        public static final String method = "method";
        /// 外层 params 字段（method 对应的参数体）。
        public static final String params = "params";
        /// params.room_id（业务房间 ID）。
        public static final String roomId = "room_id";
        /// params.msg_type（请求 20 / 响应 22）。
        public static final String msgType = "msg_type";
        /// params.msg_content（业务请求 / 响应的 JSON 字符串）。
        public static final String msgContent = "msg_content";
        /// params.user_list（点对点接收方用户 ID 列表）。
        public static final String userList = "user_list";
        /// params.seq（Express SDK 用于关联 send 与 result 的内部 seq）。
        public static final String seq = "seq";
        /// 发送失败回调 params.error_code（onSendRoomChannelMessage 携带）。
        public static final String errorCode = "error_code";
        /// 发送失败回调 params.error_message（onSendRoomChannelMessage 携带）。
        public static final String errorMessage = "error_message";
    }

    /**
     * 业务协议 JSON（msgContent 内的 envelope / 各 Action params）的字段名常量集合。
     *
     * <p>所有业务请求 / 响应的 JSON 字段都使用这套 key 拼装，业务侧如需自定义日志或
     * 调试时直接读写 raw JSON 可引用这里的常量。
     */
    public static class ProtocolKeys {
        /// envelope.Action（Action 名称，取自 {@link ActionNames}）。
        public static final String action = "Action";
        /// envelope.Seq（业务链路追踪标识，格式 {@code userId:deviceId:localSeq}）。
        public static final String seq = "Seq";
        /// envelope.Params（具体 Action 的请求 / 响应参数体）。
        public static final String params = "Params";
        /// 响应 Params.Code（0 成功；其它值见 PaaS 错误码定义）。
        public static final String code = "Code";
        /// 响应 Params.Message（处理结果说明，失败时为错误信息）。
        public static final String message = "Message";
        /// 响应 Params.RequestId（PaaS 调用的接口 RequestId）。
        public static final String requestId = "RequestId";
        /// 响应 Params.Data（PaaS 返回的业务数据，可空）。
        public static final String data = "Data";

        // Params 内部字段
        /// TTS / LLM 请求 Params.Text（要朗读或对话的文本）。
        public static final String text = "Text";
        /// TTS 请求 Params.AddHistory（是否将本次 TTS 文本加入对话历史）。
        public static final String addHistory = "AddHistory";
        /// TTS / LLM 请求 Params.Priority（任务优先级枚举字符串，
        /// 默认 {@code Medium}；与 aigc-agent 接口文档保持一致）。
        public static final String priority = "Priority";
        /// TTS / LLM 请求 Params.SamePriorityOption（相同优先级打断策略枚举字符串，
        /// 默认 {@code ClearAndInterrupt}）。
        public static final String samePriorityOption = "SamePriorityOption";
        /// TTS 请求 Params.InterruptMode（打断模式；0 = 默认）。
        public static final String interruptMode = "InterruptMode";
        /// TTS / LLM 请求 Params.EnqueueUserSpeech（是否将本轮用户语音也排入队列）。
        public static final String enqueueUserSpeech = "EnqueueUserSpeech";
        /// LLM 请求 Params.SystemPrompt（系统提示词，可覆盖智能体默认人设）。
        public static final String systemPrompt = "SystemPrompt";
        /// LLM 请求 Params.AddQuestionToHistory（是否将问题加入历史）。
        public static final String addQuestionToHistory = "AddQuestionToHistory";
        /// LLM 请求 Params.AddAnswerToHistory（是否将答案加入历史）。
        public static final String addAnswerToHistory = "AddAnswerToHistory";
        /// StartListening / StopListening 请求 Params.UserId（要聆听 / 结束聆听的用户 ID）。
        public static final String userId = "UserId";
    }
}
