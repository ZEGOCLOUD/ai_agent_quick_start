package com.zego.agentaction;

import org.json.JSONException;
import org.json.JSONObject;

import com.google.protobuf.MessageLite;

import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.ScheduledFuture;
import java.util.concurrent.TimeUnit;

/**
 * 智能体实例控制客户端。
 *
 * <p>负责将业务侧发起的 TTS / LLM / 打断 / 聆听等请求透明地上送到 PaaS，
 * 并在收到 PaaS 响应后回传给业务侧。
 *
 * <p>使用流程：
 * <ol>
 *   <li>业务侧实现 {@link Sender}（通常实现为直接调用
 *       {@code ZegoExpressEngine.callExperimentalAPI}），传入构造器；</li>
 *   <li>在 {@code ZegoExpressEngine.onRecvExperimentalAPI} 回调中，将实验性 API
 *       回调内容（{@code content} 字符串）原样传给 {@link #handleRoomChannelMessage(String)}；</li>
 *   <li>调用 {@link #sendAgentInstanceTTS} / {@link #sendAgentInstanceLLM} /
 *       {@link #interruptAgentInstance} / {@link #startListening} /
 *       {@link #stopListening} 等方法发起请求；</li>
 *   <li>通过 {@link Completion} 回调等待结果，或在 {@link ResponseCallback} /
 *       {@link ErrorCallback} 中接收异步通知。</li>
 * </ol>
 */
public class ZegoAIAgentActionClient {
    public static final int MSG_TYPE_REQUEST = 20;
    public static final int MSG_TYPE_RESPONSE = 22;
    public static final String ACTION_SEND_TTS = "SendAgentInstanceTTS";
    public static final String ACTION_SEND_LLM = "SendAgentInstanceLLM";
    public static final String ACTION_INTERRUPT = "InterruptAgentInstance";
    public static final String ACTION_START_LISTENING = "StartListening";
    public static final String ACTION_STOP_LISTENING = "StopListening";

    /**
     * `SendAgentInstanceTTS` / `SendAgentInstanceLLM` 的任务优先级默认值（与 aigc-agent 接口文档保持一致）
     */
    private static final String DEFAULT_PRIORITY = "Medium";
    /**
     * `SendAgentInstanceTTS` / `SendAgentInstanceLLM` 的相同优先级打断策略默认值（与 aigc-agent 接口文档保持一致）
     */
    private static final String DEFAULT_SAME_PRIORITY_OPTION = "ClearAndInterrupt";

    public interface Sender {
        void send(ZegoAIAgentActionSendParams params, String formatedJson, SendCallback callback);
    }

    public interface SendCallback {
        void onResult(ZegoAIAgentActionSendResult result);
    }

    public interface Completion {
        void onSuccess(ZegoAIAgentActionResponse response);
        void onError(ZegoAIAgentActionError error);
    }

    public interface ResponseCallback {
        void onResponse(ZegoAIAgentActionResponse response);
    }

    public interface ErrorCallback {
        void onError(ZegoAIAgentActionError error);
    }

    private final String roomId;
    private final String agentUserId;
    private final String userId;
    private final String agentInstanceId;
    private final boolean isDigitalHuman;
    private final String deviceId;
    private final int timeoutMs;
    private final Sender sender;
    private final ResponseCallback responseCallback;
    private final ErrorCallback errorCallback;
    private final Map<String, Pending> pending = new ConcurrentHashMap<>();
    private final Map<Integer, String> expressPending = new ConcurrentHashMap<>();
    private final ScheduledExecutorService scheduler = Executors.newSingleThreadScheduledExecutor();
    private long localSeq = 0;
    private int expressSeq = 0;

    /**
     * 构造一个智能体实例控制客户端。
     *
     * @param roomId          业务房间 ID（与 ZEGO 音视频房间 ID 一致），必填非空
     * @param agentUserId     1V1 等场景下后端 aiagent 进程加入 RTC 的 userID
     *                        （即 {@code rtcInfo.agentUserId}，形如 {@code @RBT#<agentId>}）；
     *                        数字人场景下本参数被忽略，套件按 {@code isDigitalHuman && agentInstanceId} 非空
     *                        自动用 {@code ai_agent_<agentInstanceId>}（对齐后端：数字人场景下后端会用
     *                        {@code ai_agent_} 前缀 + instanceId 拼接出一个内部 userID 用于接收信令）
     * @param userId          当前终端用户 ID，必填非空
     * @param agentInstanceId 智能体实例 ID（数字人场景必传且非空，其它场景传 null）
     * @param isDigitalHuman  是否为数字人通话（决定是否走 {@code ai_agent_<instanceId>} 拼接规则）
     * @param deviceId        设备 ID（用于构造请求 seq）；传 null 时由套件自动生成
     * @param timeoutMs       默认超时（ms），传 0 时使用 5000
     * @param sender          底层信令发送回调（通常实现为 {@code ZegoExpressEngine.callExperimentalAPI}）
     * @param responseCallback 全局响应回调（可选）
     * @param errorCallback   全局错误回调（可选）
     */
    public ZegoAIAgentActionClient(String roomId, String agentUserId, String userId, String agentInstanceId, boolean isDigitalHuman, String deviceId, int timeoutMs, Sender sender, ResponseCallback responseCallback, ErrorCallback errorCallback) {
        requireString(roomId, "roomId");
        requireString(agentUserId, "agentUserId");
        requireString(userId, "userId");
        if (sender == null) throw new IllegalArgumentException("sender is required");
        this.roomId = roomId;
        // 数字人场景下后端 aiagent 进程加入 RTC 用的 userID 是 `ai_agent_<agentInstanceId>`，与 `agentUserId`
        // 入参（即 `rtcInfo.agentUserId`，形如 `@RBT#<agentId>`）不一致；信令走 sendRoomChannelMessage 的
        // userList 点对点发送，userList 必须写后端真实 userID 才能被后端收到。
        // 规则对齐后端：数字人场景下后端会用 `ai_agent_` 前缀 + instanceId 拼接出一个内部 userID 用于接收信令。
        if (isDigitalHuman && agentInstanceId != null && !agentInstanceId.isEmpty()) {
            // 与后端 RTC 内部用户的拼接规则对齐（`ai_agent_` 前缀 + instanceId）
            this.agentUserId = "ai_agent_" + agentInstanceId;
        } else {
            this.agentUserId = agentUserId;
        }
        this.userId = userId;
        // 透传构造参数，供调用方做客户端复用判断（避免跨 instance 误用旧 client）
        this.agentInstanceId = agentInstanceId;
        this.isDigitalHuman = isDigitalHuman;
        this.deviceId = deviceId == null || deviceId.isEmpty() ? "android_" + UUID.randomUUID().toString().substring(0, 8) : deviceId;
        this.timeoutMs = timeoutMs;
        this.sender = sender;
        this.responseCallback = responseCallback;
        this.errorCallback = errorCallback;
    }

    /**
     * 主动调用智能体 TTS（便捷重载，使用构造器默认超时）。
     *
     * <p>对应 5 类控制能力中的"主动调用 TTS"。
     *
     * @param params    TTS 请求参数
     * @param completion 请求完成回调
     */
    public void sendAgentInstanceTTS(AIAgentActionProto.SendAgentInstanceTTSParams params, Completion completion) {
        sendAgentInstanceTTS(params, null, completion);
    }

    /**
     * 主动调用智能体 TTS。
     *
     * <p>对应 5 类控制能力中的"主动调用 TTS"，业务侧传入 TTS 参数即可发起。
     *
     * @param params     TTS 请求参数
     * @param timeoutMs  本次请求的超时（ms）；传 null 时使用构造器 {@code timeoutMs} 默认值
     * @param completion 请求完成回调
     */
    public void sendAgentInstanceTTS(AIAgentActionProto.SendAgentInstanceTTSParams params, Integer timeoutMs, Completion completion) {
        if (params == null) throw new IllegalArgumentException("SendAgentInstanceTTSParams is required");
        requireString(params.getText(), "text");
        if (params.getText().length() > 300) throw new IllegalArgumentException("text must be <= 300 characters");
        send(ACTION_SEND_TTS, params, timeoutMs, completion);
    }

    /**
     * 主动调用智能体 LLM（便捷重载，使用构造器默认超时）。
     *
     * <p>对应 5 类控制能力中的"主动调用 LLM"。
     *
     * @param params    LLM 请求参数
     * @param completion 请求完成回调
     */
    public void sendAgentInstanceLLM(AIAgentActionProto.SendAgentInstanceLLMParams params, Completion completion) {
        sendAgentInstanceLLM(params, null, completion);
    }

    /**
     * 主动调用智能体 LLM。
     *
     * <p>对应 5 类控制能力中的"主动调用 LLM"，业务侧传入 LLM 参数即可发起。
     *
     * @param params     LLM 请求参数
     * @param timeoutMs  本次请求的超时（ms）；传 null 时使用构造器 {@code timeoutMs} 默认值
     * @param completion 请求完成回调
     */
    public void sendAgentInstanceLLM(AIAgentActionProto.SendAgentInstanceLLMParams params, Integer timeoutMs, Completion completion) {
        if (params == null) throw new IllegalArgumentException("SendAgentInstanceLLMParams is required");
        requireString(params.getText(), "text");
        send(ACTION_SEND_LLM, params, timeoutMs, completion);
    }

    /**
     * 打断智能体实例（便捷重载，使用构造器默认超时）。
     *
     * <p>对应 5 类控制能力中的"打断智能体实例"。
     *
     * @param completion 请求完成回调
     */
    public void interruptAgentInstance(Completion completion) {
        interruptAgentInstance(null, completion);
    }

    /**
     * 打断智能体实例。
     *
     * <p>对应 5 类控制能力中的"打断智能体实例"，停止当前 TTS / LLM 推理流程。
     *
     * @param timeoutMs  本次请求的超时（ms）；传 null 时使用构造器 {@code timeoutMs} 默认值
     * @param completion 请求完成回调
     */
    public void interruptAgentInstance(Integer timeoutMs, Completion completion) {
        send(ACTION_INTERRUPT, AIAgentActionProto.InterruptAgentInstanceParams.newBuilder().build(), timeoutMs, completion);
    }

    /**
     * 智能体开始聆听指定用户（便捷重载，使用构造器默认超时）。
     *
     * <p>对应 5 类控制能力中的"开始聆听"。
     *
     * @param params    开始聆听参数
     * @param completion 请求完成回调
     */
    public void startListening(AIAgentActionProto.StartListeningParams params, Completion completion) {
        startListening(params, null, completion);
    }

    /**
     * 智能体开始聆听指定用户。
     *
     * <p>对应 5 类控制能力中的"开始聆听"，业务侧可传入 Start 参数指定聆听用户。
     *
     * @param params     开始聆听参数
     * @param timeoutMs  本次请求的超时（ms）；传 null 时使用构造器 {@code timeoutMs} 默认值
     * @param completion 请求完成回调
     */
    public void startListening(AIAgentActionProto.StartListeningParams params, Integer timeoutMs, Completion completion) {
        if (params == null) throw new IllegalArgumentException("StartListeningParams is required");
        send(ACTION_START_LISTENING, params, timeoutMs, completion);
    }

    /**
     * 智能体结束聆听指定用户（便捷重载，使用构造器默认超时）。
     *
     * <p>对应 5 类控制能力中的"结束聆听"。
     *
     * @param params    结束聆听参数
     * @param completion 请求完成回调
     */
    public void stopListening(AIAgentActionProto.StopListeningParams params, Completion completion) {
        stopListening(params, null, completion);
    }

    /**
     * 智能体结束聆听指定用户。
     *
     * <p>对应 5 类控制能力中的"结束聆听"，业务侧可传入 Stop 参数指定聆听用户。
     *
     * @param params     结束聆听参数
     * @param timeoutMs  本次请求的超时（ms）；传 null 时使用构造器 {@code timeoutMs} 默认值
     * @param completion 请求完成回调
     */
    public void stopListening(AIAgentActionProto.StopListeningParams params, Integer timeoutMs, Completion completion) {
        if (params == null) throw new IllegalArgumentException("StopListeningParams is required");
        send(ACTION_STOP_LISTENING, params, timeoutMs, completion);
    }

    /**
     * 接收 Express 实验性 API 回调内容。
     *
     * <p>业务侧应在 {@code ZegoExpressEngine.onRecvExperimentalAPI} 回调中调用此方法，
     * 把回调中的 {@code content} 字符串原样传入；Kit 会自动识别
     * {@code liveroom.room.on_recive_room_channel_message} 与
     * {@code liveroom.room.on_send_room_channel_message} 两种回调，匹配到对应的请求。
     *
     * @param contentString Express 回调内容（JSON 字符串）
     * @return 表示是否匹配到一个 pending 请求（true = 已处理）
     */
    public boolean handleRoomChannelMessage(String contentString) {
        try {
            JSONObject data = new JSONObject(contentString);
            String method = data.optString(ZegoAIAgentActionDefines.ExpressKeys.method);

            if (ZegoAIAgentActionDefines.ExpressMethods.onReciveRoomChannelMessage.equals(method)) {
                JSONObject params = data.optJSONObject(ZegoAIAgentActionDefines.ExpressKeys.params);
                if (params == null) return false;

                int msgType = params.optInt(ZegoAIAgentActionDefines.ExpressKeys.msgType, -1);
                String msgContent = params.optString(ZegoAIAgentActionDefines.ExpressKeys.msgContent);
                if (msgType != MSG_TYPE_RESPONSE || msgContent.isEmpty()) return false;
                ZegoAIAgentActionLogger.debug("handleRoomChannelMessage recv: " + contentString);

                JSONObject content = new JSONObject(msgContent);
                String seq = content.optString(ZegoAIAgentActionDefines.ProtocolKeys.seq, "");
                if (seq.isEmpty() || !content.has(ZegoAIAgentActionDefines.ProtocolKeys.action) || !content.has(ZegoAIAgentActionDefines.ProtocolKeys.code)) {
                    ZegoAIAgentActionLogger.warn("on_recive_room_channel_message missing required fields: " + content);
                    return false;
                }
                Pending item = pending.remove(seq);
                if (item == null) {
                    ZegoAIAgentActionLogger.warn("on_recive_room_channel_message orphan seq=" + seq);
                    return false;
                }
                item.timeout.cancel(false);

                // 同时也清理 expressPending
                for (Map.Entry<Integer, String> entry : expressPending.entrySet()) {
                    if (entry.getValue().equals(seq)) {
                        expressPending.remove(entry.getKey());
                        break;
                    }
                }

                AIAgentActionProto.AgentActionResponse responseProto = decodeResponse(content);
                ZegoAIAgentActionResponse response = new ZegoAIAgentActionResponse(
                        responseProto.getAction(),
                        seq,
                        responseProto.getCode(),
                        responseProto.getMessage(),
                        responseProto.getRequestId(),
                        content.opt(ZegoAIAgentActionDefines.ProtocolKeys.data),
                        msgContent
                );
                ZegoAIAgentActionLogger.info("recv action=" + response.action + " seq=" + response.seq + " code=" + response.code + " message=" + response.message);
                if (responseCallback != null) responseCallback.onResponse(response);
                if (response.code == ZegoAIAgentActionDefines.ErrorCodes.SUCCESS) {
                    item.completion.onSuccess(response);
                } else {
                    ZegoAIAgentActionError error = new ZegoAIAgentActionError(seq, response.action, response.code, response.message);
                    if (errorCallback != null) errorCallback.onError(error);
                    item.completion.onError(error);
                }
                return true;
            } else if (ZegoAIAgentActionDefines.ExpressMethods.onSendRoomChannelMessage.equals(method)) {
                JSONObject params = data.optJSONObject(ZegoAIAgentActionDefines.ExpressKeys.params);
                if (params == null) return false;
                ZegoAIAgentActionLogger.debug("handleRoomChannelMessage recv: " + contentString);

                int errorCode = params.optInt(ZegoAIAgentActionDefines.ExpressKeys.errorCode, 0);
                int expressSeq = params.optInt(ZegoAIAgentActionDefines.ExpressKeys.seq, -1);

                if (errorCode != ZegoAIAgentActionDefines.ErrorCodes.SUCCESS && expressSeq != -1) {
                    String seq = expressPending.remove(expressSeq);
                    if (seq != null) {
                        Pending item = pending.remove(seq);
                        if (item != null) {
                            item.timeout.cancel(false);
                            String errorMessage = params.optString(ZegoAIAgentActionDefines.ExpressKeys.errorMessage, "");
                            ZegoAIAgentActionLogger.warn("on_send_room_channel_message error seq=" + seq + " errorCode=" + errorCode + " message=" + errorMessage);
                            ZegoAIAgentActionError error = new ZegoAIAgentActionError(seq, item.action, errorCode, errorMessage);
                            if (errorCallback != null) errorCallback.onError(error);
                            item.completion.onError(error);
                        }
                    }
                }
                return true;
            }
            return false;
        } catch (JSONException e) {
            ZegoAIAgentActionLogger.error("handleRoomChannelMessage parse error: " + e);
            return false;
        }
    }

    /**
     * 取消所有未完成的请求。
     *
     * <p>通常在用户主动退出对话 / 切换实例时调用；被取消的请求会以
     * {@link ZegoAIAgentActionErrorCodes#CANCELED} 触发 {@link ErrorCallback} 与 {@link Completion}。
     *
     * @param message 取消原因描述（写入错误 message 字段）
     */
    public void cancelAll(String message) {
        ZegoAIAgentActionLogger.warn("cancelAll size=" + pending.size() + " message=" + message);
        for (Map.Entry<String, Pending> entry : pending.entrySet()) {
            Pending item = pending.remove(entry.getKey());
            if (item != null) {
                item.timeout.cancel(false);
                item.completion.onError(new ZegoAIAgentActionError(entry.getKey(), item.action, ZegoAIAgentActionDefines.ErrorCodes.CANCELED, message));
            }
        }
    }

    private void send(String action, MessageLite params, Integer timeoutMs, Completion completion) {
        if (completion == null) throw new IllegalArgumentException("completion is required");
        String seq = nextSeq();
        AIAgentActionProto.AgentActionEnvelope envelopeProto = AIAgentActionProto.AgentActionEnvelope.newBuilder()
                .setAction(action)
                .setSeq(seq)
                .setParams(params.toByteString())
                .build();
        JSONObject envelope = encodeEnvelope(envelopeProto, params);
        String msgContent = envelope.toString();

        int currentExpressSeq;
        synchronized (this) {
            expressSeq += 1;
            currentExpressSeq = expressSeq;
            expressPending.put(currentExpressSeq, seq);
        }

        JSONObject expressParams = new JSONObject();
        put(expressParams, ZegoAIAgentActionDefines.ExpressKeys.roomId, roomId);
        put(expressParams, ZegoAIAgentActionDefines.ExpressKeys.msgType, MSG_TYPE_REQUEST);
        put(expressParams, ZegoAIAgentActionDefines.ExpressKeys.msgContent, msgContent);
        put(expressParams, ZegoAIAgentActionDefines.ExpressKeys.userList, Collections.singletonList(agentUserId));
        put(expressParams, ZegoAIAgentActionDefines.ExpressKeys.seq, currentExpressSeq);

        JSONObject expressPayload = new JSONObject();
        put(expressPayload, ZegoAIAgentActionDefines.ExpressKeys.method, ZegoAIAgentActionDefines.ExpressMethods.sendRoomChannelMessage);
        put(expressPayload, ZegoAIAgentActionDefines.ExpressKeys.params, expressParams);
        String expressJson = expressPayload.toString();

        ScheduledFuture<?> timeout = scheduler.schedule(() -> {
            Pending item = pending.remove(seq);
            if (item != null) {
                ZegoAIAgentActionLogger.warn("timeout action=" + action + " seq=" + seq);
                item.completion.onError(new ZegoAIAgentActionError(seq, action, ZegoAIAgentActionDefines.ErrorCodes.TIMEOUT, "agent action timeout"));
            }
        }, timeoutMs == null ? this.timeoutMs : timeoutMs, TimeUnit.MILLISECONDS);
        pending.put(seq, new Pending(action, timeout, completion));
        ZegoAIAgentActionLogger.info("send action=" + action + " seq=" + seq + " expressSeq=" + currentExpressSeq + " msgContent=" + msgContent);

        sender.send(new ZegoAIAgentActionSendParams(roomId, MSG_TYPE_REQUEST, seq, msgContent, Collections.singletonList(agentUserId)), expressJson, result -> {
            ZegoAIAgentActionLogger.debug("sender result action=" + action + " seq=" + seq + " errorCode=" + (result == null ? -1 : result.errorCode));
            if (result != null && result.errorCode != ZegoAIAgentActionDefines.ErrorCodes.SUCCESS) {
                Pending item = pending.remove(seq);
                if (item != null) {
                    item.timeout.cancel(false);
                    item.completion.onError(new ZegoAIAgentActionError(seq, action, ZegoAIAgentActionDefines.ErrorCodes.SEND_FAILED, "send failed"));
                }
            }
        });
    }

    private synchronized String nextSeq() {
        localSeq += 1;
        return userId + ":" + deviceId + ":" + localSeq;
    }

    private static void requireString(String value, String name) {
        if (value == null || value.trim().isEmpty()) throw new IllegalArgumentException(name + " is required");
    }

    private static void put(JSONObject object, String key, Object value) {
        try {
            object.put(key, value);
        } catch (JSONException e) {
            throw new IllegalStateException(e);
        }
    }

    private static JSONObject encodeEnvelope(AIAgentActionProto.AgentActionEnvelope envelope, MessageLite params) {
        JSONObject object = new JSONObject();
        put(object, ZegoAIAgentActionDefines.ProtocolKeys.action, envelope.getAction());
        put(object, ZegoAIAgentActionDefines.ProtocolKeys.seq, envelope.getSeq());
        put(object, ZegoAIAgentActionDefines.ProtocolKeys.params, encodeParams(params));
        return object;
    }

    private static JSONObject encodeParams(MessageLite params) {
        JSONObject object = new JSONObject();
        if (params instanceof AIAgentActionProto.SendAgentInstanceTTSParams) {
            AIAgentActionProto.SendAgentInstanceTTSParams value = (AIAgentActionProto.SendAgentInstanceTTSParams) params;
            put(object, ZegoAIAgentActionDefines.ProtocolKeys.text, value.getText());
            put(object, ZegoAIAgentActionDefines.ProtocolKeys.addHistory, value.getAddHistory());
            // priority / samePriorityOption 为枚举字符串，客户端不显式赋值时 protobuf 默认空串会触发服务端 410000003 "Priority is invalid"，此处兜底为文档默认值
            put(object, ZegoAIAgentActionDefines.ProtocolKeys.priority, value.getPriority().isEmpty() ? DEFAULT_PRIORITY : value.getPriority());
            put(object, ZegoAIAgentActionDefines.ProtocolKeys.samePriorityOption, value.getSamePriorityOption().isEmpty() ? DEFAULT_SAME_PRIORITY_OPTION : value.getSamePriorityOption());
            if (value.getInterruptMode() != 0) put(object, ZegoAIAgentActionDefines.ProtocolKeys.interruptMode, value.getInterruptMode());
            if (value.getEnqueueUserSpeech()) put(object, ZegoAIAgentActionDefines.ProtocolKeys.enqueueUserSpeech, true);
            return object;
        }
        if (params instanceof AIAgentActionProto.SendAgentInstanceLLMParams) {
            AIAgentActionProto.SendAgentInstanceLLMParams value = (AIAgentActionProto.SendAgentInstanceLLMParams) params;
            put(object, ZegoAIAgentActionDefines.ProtocolKeys.text, value.getText());
            put(object, ZegoAIAgentActionDefines.ProtocolKeys.systemPrompt, value.getSystemPrompt());
            put(object, ZegoAIAgentActionDefines.ProtocolKeys.addQuestionToHistory, value.getAddQuestionToHistory());
            put(object, ZegoAIAgentActionDefines.ProtocolKeys.addAnswerToHistory, value.getAddAnswerToHistory());
            // 同 TTS：枚举字段空串兜底为文档默认值，避免服务端校验失败
            put(object, ZegoAIAgentActionDefines.ProtocolKeys.priority, value.getPriority().isEmpty() ? DEFAULT_PRIORITY : value.getPriority());
            put(object, ZegoAIAgentActionDefines.ProtocolKeys.samePriorityOption, value.getSamePriorityOption().isEmpty() ? DEFAULT_SAME_PRIORITY_OPTION : value.getSamePriorityOption());
            if (value.getEnqueueUserSpeech()) put(object, ZegoAIAgentActionDefines.ProtocolKeys.enqueueUserSpeech, true);
            return object;
        }
        if (params instanceof AIAgentActionProto.StartListeningParams) {
            AIAgentActionProto.StartListeningParams value = (AIAgentActionProto.StartListeningParams) params;
            if (!value.getUserId().isEmpty()) put(object, ZegoAIAgentActionDefines.ProtocolKeys.userId, value.getUserId());
            return object;
        }
        if (params instanceof AIAgentActionProto.StopListeningParams) {
            AIAgentActionProto.StopListeningParams value = (AIAgentActionProto.StopListeningParams) params;
            if (!value.getUserId().isEmpty()) put(object, ZegoAIAgentActionDefines.ProtocolKeys.userId, value.getUserId());
            return object;
        }
        if (params instanceof AIAgentActionProto.InterruptAgentInstanceParams) {
            return object;
        }
        throw new IllegalArgumentException("Unsupported protobuf params: " + params.getClass().getName());
    }

    private static AIAgentActionProto.AgentActionResponse decodeResponse(JSONObject content) {
        return AIAgentActionProto.AgentActionResponse.newBuilder()
                .setAction(content.optString(ZegoAIAgentActionDefines.ProtocolKeys.action))
                .setSeq(content.optString(ZegoAIAgentActionDefines.ProtocolKeys.seq))
                .setCode(content.optInt(ZegoAIAgentActionDefines.ProtocolKeys.code))
                .setMessage(content.optString(ZegoAIAgentActionDefines.ProtocolKeys.message))
                .setRequestId(content.optString(ZegoAIAgentActionDefines.ProtocolKeys.requestId))
                .build();
    }

    private static class Pending {
        final String action;
        final ScheduledFuture<?> timeout;
        final Completion completion;

        Pending(String action, ScheduledFuture<?> timeout, Completion completion) {
            this.action = action;
            this.timeout = timeout;
            this.completion = completion;
        }
    }

    public static class ZegoAIAgentActionSendParams {
        public final String roomId;
        public final int msgType;
        public final String seq;
        public final String msgContent;
        public final List<String> userList;

        public ZegoAIAgentActionSendParams(String roomId, int msgType, String seq, String msgContent, List<String> userList) {
            this.roomId = roomId;
            this.msgType = msgType;
            this.seq = seq;
            this.msgContent = msgContent;
            this.userList = userList;
        }
    }

    public static class ZegoAIAgentActionSendResult {
        public final int errorCode;
        public final String seq;

        public ZegoAIAgentActionSendResult(int errorCode, String seq) {
            this.errorCode = errorCode;
            this.seq = seq;
        }
    }

    public static class ZegoAIAgentActionResponse {
        public final String action;
        public final String seq;
        public final int code;
        public final String message;
        public final String requestId;
        public final Object data;
        public final String rawMessage;

        public ZegoAIAgentActionResponse(String action, String seq, int code, String message, String requestId, Object data, String rawMessage) {
            this.action = action;
            this.seq = seq;
            this.code = code;
            this.message = message;
            this.requestId = requestId;
            this.data = data;
            this.rawMessage = rawMessage;
        }
    }

    public static class ZegoAIAgentActionError {
        public final String seq;
        public final String action;
        public final Object code;
        public final String message;

        public ZegoAIAgentActionError(String seq, String action, Object code, String message) {
            this.seq = seq;
            this.action = action;
            this.code = code;
            this.message = message;
        }
    }
}
