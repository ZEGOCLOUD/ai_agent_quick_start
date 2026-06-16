(function(root, factory) {
    if (typeof module === 'object' && module.exports) {
        module.exports = factory(
            require('./generated/ai_agent_action_pb'),
            require('./defines'),
            require('./logger')
        );
    } else {
        root.ZegoAIAgentAction = factory(root.proto, root.ZegoAIAgentActionDefines, root.ZegoAIAgentActionLogger);
    }
})(typeof self !== 'undefined' ? self : this, function(protoRoot, defines, Logger) {
    'use strict';

    let pb = (protoRoot && protoRoot.AgentActionEnvelope && protoRoot) ||
        (protoRoot && protoRoot.zego && protoRoot.zego.aiagent && protoRoot.zego.aiagent.action);
    if (!pb) {
        pb = createFallbackProtobuf();
    }

    const Log = Logger || {
        debug: function () {},
        info: function () {},
        warn: function () {},
        error: function () {},
    };

    const Actions = {
        SEND_AGENT_INSTANCE_TTS: 'SendAgentInstanceTTS',
        SEND_AGENT_INSTANCE_LLM: 'SendAgentInstanceLLM',
        INTERRUPT_AGENT_INSTANCE: 'InterruptAgentInstance',
        START_LISTENING: 'StartListening',
        STOP_LISTENING: 'StopListening',
    };

    const MsgTypes = {
        AGENT_ACTION_REQUEST: 20,
        AGENT_ACTION_RESPONSE: 22,
    };

    const ErrorCodes = {
        SUCCESS: 0,
        TIMEOUT: -1,
        SEND_FAILED: -2,
        CANCELED: -3,
    };

    // `SendAgentInstanceTTS` / `SendAgentInstanceLLM` 的任务优先级默认值（与 aigc-agent 接口文档保持一致）
    const DEFAULT_PRIORITY = 'Medium';
    // `SendAgentInstanceTTS` / `SendAgentInstanceLLM` 的相同优先级打断策略默认值（与 aigc-agent 接口文档保持一致）
    const DEFAULT_SAME_PRIORITY_OPTION = 'ClearAndInterrupt';

    function createDeviceId() {
        return 'web_' + Math.random().toString(36).slice(2, 10);
    }

    function createFallbackProtobuf() {
        class AgentActionEnvelope {
            constructor() {
                this.action = '';
                this.seq = '';
                this.params = null;
            }
            setAction(value) { this.action = value || ''; return this; }
            getAction() { return this.action; }
            setSeq(value) { this.seq = value || ''; return this; }
            getSeq() { return this.seq; }
            setParams(value) { this.params = value; return this; }
            getParams() { return this.params; }
        }

        class AgentActionResponse {
            constructor() {
                this.action = '';
                this.seq = '';
                this.code = 0;
                this.message = '';
                this.requestId = '';
            }
            setAction(value) { this.action = value || ''; return this; }
            getAction() { return this.action; }
            setSeq(value) { this.seq = value || ''; return this; }
            getSeq() { return this.seq; }
            setCode(value) { this.code = Number(value || 0); return this; }
            getCode() { return this.code; }
            setMessage(value) { this.message = value || ''; return this; }
            getMessage() { return this.message; }
            setRequestId(value) { this.requestId = value || ''; return this; }
            getRequestId() { return this.requestId; }
        }

        class SendAgentInstanceTTSParams {
            constructor() {
                this.text = '';
                this.addHistory = false;
                this.priority = '';
                this.samePriorityOption = '';
                this.interruptMode = 0;
                this.enqueueUserSpeech = false;
            }
            serializeBinary() { return []; }
            setText(value) { this.text = value || ''; return this; }
            getText() { return this.text; }
            setAddHistory(value) { this.addHistory = !!value; return this; }
            getAddHistory() { return this.addHistory; }
            setPriority(value) { this.priority = value || ''; return this; }
            getPriority() { return this.priority; }
            setSamePriorityOption(value) { this.samePriorityOption = value || ''; return this; }
            getSamePriorityOption() { return this.samePriorityOption; }
            setInterruptMode(value) { this.interruptMode = Number(value || 0); return this; }
            getInterruptMode() { return this.interruptMode; }
            setEnqueueUserSpeech(value) { this.enqueueUserSpeech = !!value; return this; }
            getEnqueueUserSpeech() { return this.enqueueUserSpeech; }
        }

        class SendAgentInstanceLLMParams {
            constructor() {
                this.text = '';
                this.systemPrompt = '';
                this.addQuestionToHistory = false;
                this.addAnswerToHistory = false;
                this.priority = '';
                this.samePriorityOption = '';
                this.enqueueUserSpeech = false;
            }
            serializeBinary() { return []; }
            setText(value) { this.text = value || ''; return this; }
            getText() { return this.text; }
            setSystemPrompt(value) { this.systemPrompt = value || ''; return this; }
            getSystemPrompt() { return this.systemPrompt; }
            setAddQuestionToHistory(value) { this.addQuestionToHistory = !!value; return this; }
            getAddQuestionToHistory() { return this.addQuestionToHistory; }
            setAddAnswerToHistory(value) { this.addAnswerToHistory = !!value; return this; }
            getAddAnswerToHistory() { return this.addAnswerToHistory; }
            setPriority(value) { this.priority = value || ''; return this; }
            getPriority() { return this.priority; }
            setSamePriorityOption(value) { this.samePriorityOption = value || ''; return this; }
            getSamePriorityOption() { return this.samePriorityOption; }
            setEnqueueUserSpeech(value) { this.enqueueUserSpeech = !!value; return this; }
            getEnqueueUserSpeech() { return this.enqueueUserSpeech; }
        }

        class InterruptAgentInstanceParams {
            serializeBinary() { return []; }
        }

        class StartListeningParams {
            constructor() {
                this.userId = '';
            }
            serializeBinary() { return []; }
            setUserId(value) { this.userId = value || ''; return this; }
            getUserId() { return this.userId; }
        }

        class StopListeningParams extends StartListeningParams {}

        return {
            AgentActionEnvelope: AgentActionEnvelope,
            AgentActionResponse: AgentActionResponse,
            SendAgentInstanceTTSParams: SendAgentInstanceTTSParams,
            SendAgentInstanceLLMParams: SendAgentInstanceLLMParams,
            InterruptAgentInstanceParams: InterruptAgentInstanceParams,
            StartListeningParams: StartListeningParams,
            StopListeningParams: StopListeningParams,
        };
    }

    function requireString(value, name) {
        if (typeof value !== 'string' || value.trim() === '') {
            throw createError('', '', 'invalid_param', name + ' is required');
        }
    }

    function createError(seq, action, code, message) {
        const error = new Error(message);
        error.seq = seq;
        error.action = action;
        error.code = code;
        return error;
    }

    function createEnvelope(action, seq, params) {
        return {
            Action: action,
            Seq: seq,
            Params: params || {},
        };
    }

    function extractRoomChannelEvent(data) {
        if (!data || typeof data !== 'object') return null;
        const method = data[defines.ExpressKeys.method];
        if (method !== defines.ExpressMethods.onRecvRoomChannelMessage) return null;
        const body = data[defines.ExpressKeys.content] || data[defines.ExpressKeys.params];
        if (!body || typeof body !== 'object') return null;
        return {
            body: body,
            msgType: body[defines.ExpressKeys.msgType],
            msgContent: body[defines.ExpressKeys.msgContent],
        };
    }

    class ZegoAIAgentActionClient {
        constructor(options) {
            options = options || {};
            requireString(options.roomId, 'roomId');
            requireString(options.agentUserId, 'agentUserId');
            requireString(options.userId || options.currentUserId || 'anonymous', 'userId');
            if (typeof options.sender !== 'function') {
                throw createError('', '', 'invalid_param', 'sender(params) is required');
            }
            this.roomId = options.roomId;
            // 数字人场景下后端 aiagent 进程加入 RTC 用的 userID 是 `ai_agent_<agentInstanceId>`，与 `agentUserId`
            // 入参（即 `rtcInfo.agentUserId`，形如 `@RBT#<agentId>`）不一致；信令走 sendRoomChannelMessage 的
            // userList 点对点发送，userList 必须写后端真实 userID 才能被后端收到。
            // 规则对齐后端：数字人场景下后端会用 `ai_agent_` 前缀 + instanceId 拼接出一个内部 userID 用于接收信令。
            if (options.isDigitalHuman && options.agentInstanceId) {
                // 与后端 RTC 内部用户的拼接规则对齐（`ai_agent_` 前缀 + instanceId）
                this.agentUserId = 'ai_agent_' + options.agentInstanceId;
            } else {
                this.agentUserId = options.agentUserId;
            }
            this.userId = options.userId || options.currentUserId || 'anonymous';
            // 透传构造参数，供调用方做客户端复用判断（避免跨 instance 误用旧 client）
            this.agentInstanceId = options.agentInstanceId || null;
            this.isDigitalHuman = !!options.isDigitalHuman;
            this.deviceId = options.deviceId || createDeviceId();
            this.defaultTimeoutMs = options.timeoutMs || 5000;
            this.sender = options.sender;
            this.onResponse = typeof options.onResponse === 'function' ? options.onResponse : null;
            this.onError = typeof options.onError === 'function' ? options.onError : null;
            this.onDebugEvent = typeof options.onDebugEvent === 'function' ? options.onDebugEvent : null;
            this.pending = new Map();
            this.localSeq = 0;
        }

        /**
         * 主动调用智能体 TTS。
         *
         * 对应 5 类控制能力中的"主动调用 TTS"，业务侧传入 TTS 参数即可发起。
         * @param {SendAgentInstanceTTSParams} params
         * @param {{seq?: string, timeoutMs?: number, agentUserId?: string}} [options]
         * @returns {Promise<ZegoAIAgentActionResponse>}
         */
        sendAgentInstanceTTS(params, options) {
            assertPbParams(params, pb.SendAgentInstanceTTSParams, 'SendAgentInstanceTTSParams');
            requireString(params.getText(), 'text');
            return this._send(Actions.SEND_AGENT_INSTANCE_TTS, params, options);
        }

        /**
         * 主动调用智能体 LLM。
         *
         * 对应 5 类控制能力中的"主动调用 LLM"，业务侧传入 LLM 参数即可发起。
         * @param {SendAgentInstanceLLMParams} params
         * @param {{seq?: string, timeoutMs?: number, agentUserId?: string}} [options]
         * @returns {Promise<ZegoAIAgentActionResponse>}
         */
        sendAgentInstanceLLM(params, options) {
            assertPbParams(params, pb.SendAgentInstanceLLMParams, 'SendAgentInstanceLLMParams');
            requireString(params.getText(), 'text');
            return this._send(Actions.SEND_AGENT_INSTANCE_LLM, params, options);
        }

        /**
         * 打断智能体实例。
         *
         * 对应 5 类控制能力中的"打断智能体实例"，停止当前 TTS / LLM 推理流程。
         * @param {{seq?: string, timeoutMs?: number, agentUserId?: string}} [options]
         * @returns {Promise<ZegoAIAgentActionResponse>}
         */
        interruptAgentInstance(options) {
            return this._send(Actions.INTERRUPT_AGENT_INSTANCE, new pb.InterruptAgentInstanceParams(), options);
        }

        /**
         * 智能体开始聆听指定用户。
         *
         * 对应 5 类控制能力中的"开始聆听"，业务侧可传入 Start 参数指定聆听用户。
         * @param {StartListeningParams} params
         * @param {{seq?: string, timeoutMs?: number, agentUserId?: string}} [options]
         * @returns {Promise<ZegoAIAgentActionResponse>}
         */
        startListening(params, options) {
            assertPbParams(params, pb.StartListeningParams, 'StartListeningParams');
            return this._send(Actions.START_LISTENING, params, options);
        }

        /**
         * 智能体结束聆听指定用户。
         *
         * 对应 5 类控制能力中的"结束聆听"，业务侧可传入 Stop 参数指定聆听用户。
         * @param {StopListeningParams} params
         * @param {{seq?: string, timeoutMs?: number, agentUserId?: string}} [options]
         * @returns {Promise<ZegoAIAgentActionResponse>}
         */
        stopListening(params, options) {
            assertPbParams(params, pb.StopListeningParams, 'StopListeningParams');
            return this._send(Actions.STOP_LISTENING, params, options);
        }

        /**
         * 接收 Express 实验性 API 回调内容。
         *
         * 业务侧应在 `onRecvExperimentalAPI` 回调中调用此方法，
         * 把回调中的 `content` 字符串原样传入；Kit 会自动识别
         * `liveroom.room.on_recive_room_channel_message` 与
         * `liveroom.room.on_send_room_channel_message` 两种回调，匹配到对应的请求。
         *
         * @param {string|object} contentString
         * @returns {boolean} 表示是否匹配到一个 pending 请求（true = 已处理）
         */
        handleRoomChannelMessage(contentString) {
            let data;
            try {
                data = typeof contentString === 'string' ? JSON.parse(contentString) : contentString;
            } catch (cause) {
                this._debug('parse_failed', { cause: cause, rawMessage: contentString });
                Log.debug('handleRoomChannelMessage skip: reason=parse_failed');
                return false;
            }

            const event = extractRoomChannelEvent(data);
            if (!event) {
                Log.debug('handleRoomChannelMessage skip: reason=not_room_channel_event method=' + (data && data[defines.ExpressKeys.method]));
                return false;
            }

            if (Number(event.msgType) !== MsgTypes.AGENT_ACTION_RESPONSE || !event.msgContent) {
                return false;
            }

            Log.debug('handleRoomChannelMessage recv: ' + (typeof contentString === 'string' ? contentString : JSON.stringify(contentString)));

            const msgContentStr = event.msgContent;
            let content;
            try {
                content = typeof msgContentStr === 'string' ? JSON.parse(msgContentStr) : msgContentStr;
            } catch (cause) {
                Log.error('handleRoomChannelMessage msgContent parse error: ' + cause);
                this._debug('parse_failed', { cause: cause, rawMessage: msgContentStr });
                return false;
            }

            if (!content || typeof content[defines.ProtocolKeys.seq] !== 'string' || !content[defines.ProtocolKeys.action] || typeof content[defines.ProtocolKeys.code] !== 'number') {
                Log.warn('on_recive_room_channel_message missing required fields: ' + JSON.stringify(content));
                this._debug('invalid_response', { content: content, rawMessage: msgContentStr });
                return false;
            }

            const seq = content[defines.ProtocolKeys.seq];
            const item = this.pending.get(seq);
            if (!item) {
                Log.warn('on_recive_room_channel_message orphan seq=' + seq);
                this._debug('orphan_response', { seq: seq, content: content });
                return false;
            }

            clearTimeout(item.timer);
            this.pending.delete(seq);

            const responseProto = decodeResponse(content);
            const response = {
                action: responseProto.getAction(),
                seq: responseProto.getSeq(),
                code: responseProto.getCode(),
                message: responseProto.getMessage() || '',
                requestId: responseProto.getRequestId() || '',
                data: content[defines.ProtocolKeys.data],
                rawMessage: msgContentStr,
            };

            Log.info('recv action=' + response.action + ' seq=' + response.seq + ' code=' + response.code + ' message=' + response.message);
            if (this.onResponse) this.onResponse(response);
            if (response.code === ErrorCodes.SUCCESS) {
                item.resolve(response);
            } else {
                const error = createError(response.seq, response.action, response.code, response.message || 'agent action failed');
                if (this.onError) this.onError(error);
                item.reject(error);
            }
            return true;

        }

        /**
         * 取消所有未完成的请求。
         *
         * 通常在用户主动退出对话 / 切换实例时调用；被取消的请求会以
         * `ZegoAIAgentActionErrorCodes.CANCELED` 触发 `onError` 与 `Promise` reject。
         *
         * @param {string} [message='agent action canceled'] 取消原因描述
         */
        cancelAll(message) {
            const reason = message || 'agent action canceled';
            Log.warn('cancelAll size=' + this.pending.size + ' message=' + reason);
            this.pending.forEach((item, seq) => {
                clearTimeout(item.timer);
                item.reject(createError(seq, item.action, ErrorCodes.CANCELED, reason));
            });
            this.pending.clear();
        }

        _send(action, params, options) {
            options = options || {};
            const agentUserId = options.agentUserId || this.agentUserId;
            requireString(agentUserId, 'agentUserId');
            const seq = options.seq || this._nextSeq();
            const timeoutMs = options.timeoutMs || this.defaultTimeoutMs;
            const envelope = new pb.AgentActionEnvelope();
            envelope.setAction(action);
            envelope.setSeq(seq);
            envelope.setParams(params.serializeBinary());
            const msgContent = JSON.stringify(encodeEnvelope(envelope, params));

            const expressParams = {};
            expressParams[defines.ExpressKeys.roomId] = this.roomId;
            expressParams[defines.ExpressKeys.msgType] = MsgTypes.AGENT_ACTION_REQUEST;
            expressParams[defines.ExpressKeys.msgContent] = msgContent;
            expressParams[defines.ExpressKeys.userList] = [agentUserId];

            const expressPayload = {};
            expressPayload[defines.ExpressKeys.method] = defines.ExpressMethods.sendRoomChannelMessage;
            expressPayload[defines.ExpressKeys.params] = expressParams;
            Log.info('send action=' + action + ' seq=' + seq + ' msgContent=' + msgContent);

            const sendParams = {
                roomId: this.roomId,
                msgType: MsgTypes.AGENT_ACTION_REQUEST,
                msg_type: MsgTypes.AGENT_ACTION_REQUEST,
                seq: seq,
                msgContent: msgContent,
                msg_content: msgContent,
                userList: [agentUserId],
                user_list: [agentUserId],
                roomID: this.roomId,
                msgTypeValue: MsgTypes.AGENT_ACTION_REQUEST,
                msgContentValue: msgContent,
                toUserIDList: [agentUserId],
            };

            return new Promise((resolve, reject) => {
                const timer = setTimeout(() => {
                    this.pending.delete(seq);
                    Log.warn('timeout action=' + action + ' seq=' + seq);
                    reject(createError(seq, action, ErrorCodes.TIMEOUT, 'agent action timeout'));
                }, timeoutMs);

                this.pending.set(seq, { action: action, resolve: resolve, reject: reject, timer: timer, startTime: Date.now() });

                Promise.resolve()
                    .then(() => this.sender(sendParams, expressPayload))
                    .then((result) => {
                        Log.debug('sender result action=' + action + ' seq=' + seq + ' errorCode=' + (result && result.errorCode));
                        if (result && result.errorCode && result.errorCode !== ErrorCodes.SUCCESS) {
                            clearTimeout(timer);
                            this.pending.delete(seq);
                            reject(createError(seq, action, ErrorCodes.SEND_FAILED, 'send room channel message failed'));
                        }
                    })
                    .catch((cause) => {
                        Log.error('sender exception action=' + action + ' seq=' + seq + ' error=' + cause);
                        clearTimeout(timer);
                        this.pending.delete(seq);
                        reject(createError(seq, action, ErrorCodes.SEND_FAILED, 'send room channel message failed'));
                    });
            });
        }

        _nextSeq() {
            this.localSeq += 1;
            return this.userId + ':' + this.deviceId + ':' + this.localSeq;
        }

        _debug(type, payload) {
            if (this.onDebugEvent) {
                this.onDebugEvent(Object.assign({ type: type }, payload || {}));
            }
        }
    }

    function encodeEnvelope(envelope, params) {
        const payload = {};
        payload[defines.ProtocolKeys.action] = envelope.getAction();
        payload[defines.ProtocolKeys.seq] = envelope.getSeq();
        payload[defines.ProtocolKeys.params] = encodeParams(params);
        return payload;
    }

    function assertPbParams(params, ctor, name) {
        if (!(params instanceof ctor)) {
            throw createError('', '', 'invalid_param', name + ' is required');
        }
    }

    function decodeResponse(content) {
        const response = new pb.AgentActionResponse();
        response.setAction(content[defines.ProtocolKeys.action] || '');
        response.setSeq(content[defines.ProtocolKeys.seq] || '');
        response.setCode(Number(content[defines.ProtocolKeys.code] || ErrorCodes.SUCCESS));
        response.setMessage(content[defines.ProtocolKeys.message] || '');
        response.setRequestId(content[defines.ProtocolKeys.requestId] || '');
        return response;
    }

    function encodeParams(params) {
        if (params instanceof pb.SendAgentInstanceTTSParams) {
            const json = {};
            json[defines.ProtocolKeys.text] = params.getText();
            json[defines.ProtocolKeys.addHistory] = params.getAddHistory();
            // priority / samePriorityOption 为枚举字符串，客户端不显式赋值时 protobuf 默认空串会触发服务端 410000003 "Priority is invalid"，此处兜底为文档默认值
            json[defines.ProtocolKeys.priority] = params.getPriority() || DEFAULT_PRIORITY;
            json[defines.ProtocolKeys.samePriorityOption] = params.getSamePriorityOption() || DEFAULT_SAME_PRIORITY_OPTION;
            if (params.getInterruptMode() !== 0) json[defines.ProtocolKeys.interruptMode] = params.getInterruptMode();
            if (params.getEnqueueUserSpeech()) json[defines.ProtocolKeys.enqueueUserSpeech] = true;
            return json;
        }
        if (params instanceof pb.SendAgentInstanceLLMParams) {
            const json = {};
            json[defines.ProtocolKeys.text] = params.getText();
            json[defines.ProtocolKeys.systemPrompt] = params.getSystemPrompt();
            json[defines.ProtocolKeys.addQuestionToHistory] = params.getAddQuestionToHistory();
            json[defines.ProtocolKeys.addAnswerToHistory] = params.getAddAnswerToHistory();
            // 同 TTS：枚举字段空串兜底为文档默认值，避免服务端校验失败
            json[defines.ProtocolKeys.priority] = params.getPriority() || DEFAULT_PRIORITY;
            json[defines.ProtocolKeys.samePriorityOption] = params.getSamePriorityOption() || DEFAULT_SAME_PRIORITY_OPTION;
            if (params.getEnqueueUserSpeech()) json[defines.ProtocolKeys.enqueueUserSpeech] = true;
            return json;
        }
        if (params instanceof pb.StartListeningParams) {
            const json = {};
            if (params.getUserId()) json[defines.ProtocolKeys.userId] = params.getUserId();
            return json;
        }
        if (params instanceof pb.StopListeningParams) {
            const json = {};
            if (params.getUserId()) json[defines.ProtocolKeys.userId] = params.getUserId();
            return json;
        }
        if (params instanceof pb.InterruptAgentInstanceParams) {
            return {};
        }
        return params || {};
    }

    return {
        ZegoAIAgentActionClient: ZegoAIAgentActionClient,
        Actions: Actions,
        MsgTypes: MsgTypes,
        ErrorCodes: ErrorCodes,
        createEnvelope: createEnvelope,
        Protobuf: pb,
    };
});
