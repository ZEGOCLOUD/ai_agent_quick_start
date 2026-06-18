(function(root, factory) {
    if (typeof module === 'object' && module.exports) {
        module.exports = factory();
    } else {
        root.ZegoAIAgentActionDefines = factory();
    }
})(typeof self !== 'undefined' ? self : this, function() {
    'use strict';

    /**
     * 5 类控制能力对应的 Action 名称常量集合。
     *
     * Action 名是后端 aigc-agent 路由分发的依据，必须与 PaaS 接口定义保持一致。
     * @enum {string}
     */
    const ActionNames = {
        /** 主动调用智能体 TTS（让智能体朗读一段文本） */
        SEND_AGENT_INSTANCE_TTS: 'SendAgentInstanceTTS',
        /** 主动调用智能体 LLM（直接给智能体一段文本，让其基于 LLM 推理并回复） */
        SEND_AGENT_INSTANCE_LLM: 'SendAgentInstanceLLM',
        /** 打断智能体实例（停止当前 TTS / LLM 推理流程） */
        INTERRUPT_AGENT_INSTANCE: 'InterruptAgentInstance',
        /** 让智能体开始聆听指定用户（持续关注该用户语音输入） */
        START_LISTENING: 'StartListening',
        /** 让智能体结束聆听指定用户 */
        STOP_LISTENING: 'StopListening',
    };

    /**
     * Express 协议 `msg_type` 字段的取值集合。
     * @enum {number}
     */
    const MsgTypes = {
        /** 上行请求（20） */
        AGENT_ACTION_REQUEST: 20,
        /** 下行响应（22） */
        AGENT_ACTION_RESPONSE: 22,
    };

    /**
     * 套件识别的 Express 实验性 API 方法名集合。
     *
     * 业务侧实现 Sender 回调时使用 `sendRoomChannelMessage`；处理
     * `onRecvExperimentalAPI` 回调时通过 `method` 字段区分下面两类。
     * @enum {string}
     */
    const ExpressMethods = {
        /** 业务方在 Sender 回调里调用 `callExperimentalAPI` 时 method 取此值 */
        sendRoomChannelMessage: 'sendRoomChannelMessage',
        /** 收到 PaaS 端业务响应的回调方法名 */
        onRecvRoomChannelMessage: 'onRecvRoomChannelMessage',
    };

    /**
     * Express 协议 JSON 的外层 / params 字段名常量集合。
     *
     * 业务侧在日志 / 透传时如需直接读写 raw JSON，可用这些 key 避免硬编码。
     * @enum {string}
     */
    const ExpressKeys = {
        /** 外层 method 字段 */
        method: 'method',
        /** 外层 params 字段（method 对应的参数体） */
        params: 'params',
        /** params.content（部分 WebRTC 端将 params 拆分为 content + params 两层） */
        content: 'content',
        /** params.roomID（业务房间 ID，Web 端使用驼峰命名） */
        roomId: 'roomID',
        /** params.msgType（请求 20 / 响应 22） */
        msgType: 'msgType',
        /** params.msgContent（业务请求 / 响应的 JSON 字符串） */
        msgContent: 'msgContent',
        /** params.toUserIDList（点对点接收方用户 ID 列表，Web 端使用 toUserIDList） */
        userList: 'toUserIDList',
        /** params.seq（业务侧用于关联 send 与 result 的内部 seq） */
        seq: 'seq',
    };

    /**
     * 业务协议 JSON（msgContent 内的 envelope / 各 Action params）的字段名常量集合。
     *
     * 所有业务请求 / 响应的 JSON 字段都使用这套 key 拼装，业务侧如需自定义日志或
     * 调试时直接读写 raw JSON 可引用这里的常量。
     * @enum {string}
     */
    const ProtocolKeys = {
        /** envelope.Action（Action 名称，取自 ActionNames） */
        action: 'Action',
        /** envelope.Seq（业务链路追踪标识，格式 `userId:deviceId:localSeq`） */
        seq: 'Seq',
        /** envelope.Params（具体 Action 的请求 / 响应参数体） */
        params: 'Params',
        /** 响应 Params.Code（0 成功；其它值见 PaaS 错误码定义） */
        code: 'Code',
        /** 响应 Params.Message（处理结果说明，失败时为错误信息） */
        message: 'Message',
        /** 响应 Params.RequestId（PaaS 调用的接口 RequestId） */
        requestId: 'RequestId',
        /** 响应 Params.Data（PaaS 返回的业务数据，可空） */
        data: 'Data',

        // Params 内部字段
        /** TTS / LLM 请求 Params.Text（要朗读或对话的文本） */
        text: 'Text',
        /** TTS 请求 Params.AddHistory（是否将本次 TTS 文本加入对话历史） */
        addHistory: 'AddHistory',
        /** TTS / LLM 请求 Params.Priority（任务优先级枚举字符串，默认 `Medium`；与 aigc-agent 接口文档保持一致） */
        priority: 'Priority',
        /** TTS / LLM 请求 Params.SamePriorityOption（相同优先级打断策略枚举字符串，默认 `ClearAndInterrupt`） */
        samePriorityOption: 'SamePriorityOption',
        /** TTS 请求 Params.InterruptMode（打断模式；0 = 默认） */
        interruptMode: 'InterruptMode',
        /** TTS / LLM 请求 Params.EnqueueUserSpeech（是否将本轮用户语音也排入队列） */
        enqueueUserSpeech: 'EnqueueUserSpeech',
        /** LLM 请求 Params.SystemPrompt（系统提示词，可覆盖智能体默认人设） */
        systemPrompt: 'SystemPrompt',
        /** LLM 请求 Params.AddQuestionToHistory（是否将问题加入历史） */
        addQuestionToHistory: 'AddQuestionToHistory',
        /** LLM 请求 Params.AddAnswerToHistory（是否将答案加入历史） */
        addAnswerToHistory: 'AddAnswerToHistory',
        /** StartListening / StopListening 请求 Params.UserId（要聆听 / 结束聆听的用户 ID） */
        userId: 'UserId',
        /** StartListening / StopListening 请求 Params.Sequence（客户端自增序列号；不传则按后台接收顺序处理） */
        sequence: 'Sequence',
    };

    /**
     * 套件内部错误码常量集合。
     *
     * 用于 `Error.code` 与 `SendResult.errorCode`。
     * PaaS 端业务错误时 `Error.code` 会用 PaaS 返回的业务码，
     * 本地套件错误（超时 / 发送失败 / 主动取消）会用这里的预定义值。
     * @enum {number}
     */
    const ErrorCodes = {
        /** 请求成功（0）；PaaS 端处理成功时回写此值 */
        SUCCESS: 0,
        /** 请求超时（-1）；从发送到收到响应的间隔超过 `timeoutMs` 时触发 */
        TIMEOUT: -1,
        /** 底层 Express 通道发送失败（-2）；通常是 `callExperimentalAPI` 抛错或返回非零 */
        SEND_FAILED: -2,
        /** 请求被主动取消（-3）；通常由 `cancelAll` 触发 */
        CANCELED: -3,
    };

    return {
        ActionNames: ActionNames,
        MsgTypes: MsgTypes,
        ExpressMethods: ExpressMethods,
        ExpressKeys: ExpressKeys,
        ProtocolKeys: ProtocolKeys,
        ErrorCodes: ErrorCodes,
    };
});
