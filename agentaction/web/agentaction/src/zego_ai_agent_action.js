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

    const pb = (protoRoot && protoRoot.AgentActionEnvelope && protoRoot) ||
        (protoRoot && protoRoot.zego && protoRoot.zego.aiagent && protoRoot.zego.aiagent.action);

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

    function createDeviceId() {
        return 'web_' + Math.random().toString(36).slice(2, 10);
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

    class ZegoAIAgentActionClient {
        constructor(options) {
            options = options || {};
            requireString(options.roomId, 'roomId');
            requireString(options.agentUserId, 'agentUserId');
            requireString(options.userId || options.currentUserId || 'anonymous', 'userId');
            if (typeof options.sender !== 'function') {
                throw createError('', '', 'invalid_param', 'sender(params) is required');
            }
            if (!pb) {
                throw createError('', '', 'invalid_param', 'protobuf classes are not loaded');
            }

            this.roomId = options.roomId;
            this.agentUserId = options.agentUserId;
            this.userId = options.userId || options.currentUserId || 'anonymous';
            this.deviceId = options.deviceId || createDeviceId();
            this.defaultTimeoutMs = options.timeoutMs || 5000;
            this.sender = options.sender;
            this.onResponse = typeof options.onResponse === 'function' ? options.onResponse : null;
            this.onError = typeof options.onError === 'function' ? options.onError : null;
            this.onDebugEvent = typeof options.onDebugEvent === 'function' ? options.onDebugEvent : null;
            this.pending = new Map();
            this.expressPending = new Map();
            this.localSeq = 0;
            this.expressSeq = 0;
        }

        sendAgentInstanceTTS(params, options) {
            assertPbParams(params, pb.SendAgentInstanceTTSParams, 'SendAgentInstanceTTSParams');
            requireString(params.getText(), 'text');
            return this._send(Actions.SEND_AGENT_INSTANCE_TTS, params, options);
        }

        sendAgentInstanceLLM(params, options) {
            assertPbParams(params, pb.SendAgentInstanceLLMParams, 'SendAgentInstanceLLMParams');
            requireString(params.getText(), 'text');
            return this._send(Actions.SEND_AGENT_INSTANCE_LLM, params, options);
        }

        interruptAgentInstance(options) {
            return this._send(Actions.INTERRUPT_AGENT_INSTANCE, new pb.InterruptAgentInstanceParams(), options);
        }

        startListening(params, options) {
            assertPbParams(params, pb.StartListeningParams, 'StartListeningParams');
            return this._send(Actions.START_LISTENING, params, options);
        }

        stopListening(params, options) {
            assertPbParams(params, pb.StopListeningParams, 'StopListeningParams');
            return this._send(Actions.STOP_LISTENING, params, options);
        }

        handleRoomChannelMessage(contentString) {
            Log.debug('handleRoomChannelMessage recv: ' + contentString);
            let data;
            try {
                data = typeof contentString === 'string' ? JSON.parse(contentString) : contentString;
            } catch (cause) {
                Log.error('handleRoomChannelMessage parse error: ' + cause);
                this._debug('parse_failed', { cause: cause, rawMessage: contentString });
                return false;
            }

            if (!data) return false;
            const method = data[defines.ExpressKeys.method];

            if (method === defines.ExpressMethods.onReciveRoomChannelMessage) {
                const params = data[defines.ExpressKeys.params];
                if (!params || params[defines.ExpressKeys.msgType] !== MsgTypes.AGENT_ACTION_RESPONSE) {
                    return false;
                }

                const msgContentStr = params[defines.ExpressKeys.msgContent];
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

                // 清理 expressPending
                for (let [expSeq, bSeq] of this.expressPending.entries()) {
                    if (bSeq === seq) {
                        this.expressPending.delete(expSeq);
                        break;
                    }
                }

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
            } else if (method === defines.ExpressMethods.onSendRoomChannelMessage) {
                const params = data[defines.ExpressKeys.params];
                if (!params) return false;

                const errorCode = params[defines.ExpressKeys.errorCode];
                const expressSeq = params[defines.ExpressKeys.seq];

                if (errorCode !== ErrorCodes.SUCCESS && expressSeq !== undefined) {
                    const seq = this.expressPending.get(expressSeq);
                    if (seq) {
                        this.expressPending.delete(expressSeq);
                        const item = this.pending.get(seq);
                        if (item) {
                            clearTimeout(item.timer);
                            this.pending.delete(seq);
                            const errorMessage = params[defines.ExpressKeys.errorMessage] || '';
                            Log.warn('on_send_room_channel_message error seq=' + seq + ' errorCode=' + errorCode + ' message=' + errorMessage);
                            const error = createError(seq, item.action, errorCode, errorMessage);
                            if (this.onError) this.onError(error);
                            item.reject(error);
                        }
                    }
                }
                return true;
            }

            return false;
        }

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

            this.expressSeq += 1;
            const currentExpressSeq = this.expressSeq;
            this.expressPending.set(currentExpressSeq, seq);

            const expressParams = {};
            expressParams[defines.ExpressKeys.roomId] = this.roomId;
            expressParams[defines.ExpressKeys.msgType] = MsgTypes.AGENT_ACTION_REQUEST;
            expressParams[defines.ExpressKeys.msgContent] = msgContent;
            expressParams[defines.ExpressKeys.userList] = [agentUserId];
            expressParams[defines.ExpressKeys.seq] = currentExpressSeq;

            const expressPayload = {};
            expressPayload[defines.ExpressKeys.method] = defines.ExpressMethods.sendRoomChannelMessage;
            expressPayload[defines.ExpressKeys.params] = expressParams;
            const expressJson = JSON.stringify(expressPayload);
            Log.info('send action=' + action + ' seq=' + seq + ' expressSeq=' + currentExpressSeq + ' msgContent=' + msgContent);

            const sendParams = {
                roomId: this.roomId,
                msgType: MsgTypes.AGENT_ACTION_REQUEST,
                msg_type: MsgTypes.AGENT_ACTION_REQUEST,
                seq: seq,
                msgContent: msgContent,
                msg_content: msgContent,
                userList: [agentUserId],
                user_list: [agentUserId],
            };

            return new Promise((resolve, reject) => {
                const timer = setTimeout(() => {
                    this.pending.delete(seq);
                    Log.warn('timeout action=' + action + ' seq=' + seq);
                    reject(createError(seq, action, ErrorCodes.TIMEOUT, 'agent action timeout'));
                }, timeoutMs);

                this.pending.set(seq, { action: action, resolve: resolve, reject: reject, timer: timer, startTime: Date.now() });

                Promise.resolve()
                    .then(() => this.sender(sendParams, expressJson))
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
            json[defines.ProtocolKeys.priority] = params.getPriority();
            json[defines.ProtocolKeys.samePriorityOption] = params.getSamePriorityOption();
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
            json[defines.ProtocolKeys.priority] = params.getPriority();
            json[defines.ProtocolKeys.samePriorityOption] = params.getSamePriorityOption();
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
