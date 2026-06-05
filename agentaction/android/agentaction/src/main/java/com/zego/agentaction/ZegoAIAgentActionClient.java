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

public class ZegoAIAgentActionClient {
    public static final int MSG_TYPE_REQUEST = 20;
    public static final int MSG_TYPE_RESPONSE = 22;
    public static final String ACTION_SEND_TTS = "SendAgentInstanceTTS";
    public static final String ACTION_SEND_LLM = "SendAgentInstanceLLM";
    public static final String ACTION_INTERRUPT = "InterruptAgentInstance";
    public static final String ACTION_START_LISTENING = "StartListening";
    public static final String ACTION_STOP_LISTENING = "StopListening";

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

    public ZegoAIAgentActionClient(String roomId, String agentUserId, String userId, Sender sender, ResponseCallback responseCallback, ErrorCallback errorCallback) {
        this(roomId, agentUserId, userId, null, 5000, sender, responseCallback, errorCallback);
    }

    public ZegoAIAgentActionClient(String roomId, String agentUserId, String userId, String deviceId, int timeoutMs, Sender sender, ResponseCallback responseCallback, ErrorCallback errorCallback) {
        requireString(roomId, "roomId");
        requireString(agentUserId, "agentUserId");
        requireString(userId, "userId");
        if (sender == null) throw new IllegalArgumentException("sender is required");
        this.roomId = roomId;
        this.agentUserId = agentUserId;
        this.userId = userId;
        this.deviceId = deviceId == null || deviceId.isEmpty() ? "android_" + UUID.randomUUID().toString().substring(0, 8) : deviceId;
        this.timeoutMs = timeoutMs;
        this.sender = sender;
        this.responseCallback = responseCallback;
        this.errorCallback = errorCallback;
    }

    public void sendAgentInstanceTTS(AIAgentActionProto.SendAgentInstanceTTSParams params, Completion completion) {
        sendAgentInstanceTTS(params, null, completion);
    }

    public void sendAgentInstanceTTS(AIAgentActionProto.SendAgentInstanceTTSParams params, Integer timeoutMs, Completion completion) {
        if (params == null) throw new IllegalArgumentException("SendAgentInstanceTTSParams is required");
        requireString(params.getText(), "text");
        if (params.getText().length() > 300) throw new IllegalArgumentException("text must be <= 300 characters");
        send(ACTION_SEND_TTS, params, timeoutMs, completion);
    }

    public void sendAgentInstanceLLM(AIAgentActionProto.SendAgentInstanceLLMParams params, Completion completion) {
        sendAgentInstanceLLM(params, null, completion);
    }

    public void sendAgentInstanceLLM(AIAgentActionProto.SendAgentInstanceLLMParams params, Integer timeoutMs, Completion completion) {
        if (params == null) throw new IllegalArgumentException("SendAgentInstanceLLMParams is required");
        requireString(params.getText(), "text");
        send(ACTION_SEND_LLM, params, timeoutMs, completion);
    }

    public void interruptAgentInstance(Completion completion) {
        interruptAgentInstance(null, completion);
    }

    public void interruptAgentInstance(Integer timeoutMs, Completion completion) {
        send(ACTION_INTERRUPT, AIAgentActionProto.InterruptAgentInstanceParams.newBuilder().build(), timeoutMs, completion);
    }

    public void startListening(AIAgentActionProto.StartListeningParams params, Completion completion) {
        startListening(params, null, completion);
    }

    public void startListening(AIAgentActionProto.StartListeningParams params, Integer timeoutMs, Completion completion) {
        if (params == null) throw new IllegalArgumentException("StartListeningParams is required");
        send(ACTION_START_LISTENING, params, timeoutMs, completion);
    }

    public void stopListening(AIAgentActionProto.StopListeningParams params, Completion completion) {
        stopListening(params, null, completion);
    }

    public void stopListening(AIAgentActionProto.StopListeningParams params, Integer timeoutMs, Completion completion) {
        if (params == null) throw new IllegalArgumentException("StopListeningParams is required");
        send(ACTION_STOP_LISTENING, params, timeoutMs, completion);
    }

    public boolean handleRoomChannelMessage(String contentString) {
        ZegoAIAgentActionLogger.debug("handleRoomChannelMessage recv: " + contentString);
        try {
            JSONObject data = new JSONObject(contentString);
            String method = data.optString(ZegoAIAgentActionDefines.ExpressKeys.method);

            if (ZegoAIAgentActionDefines.ExpressMethods.onReciveRoomChannelMessage.equals(method)) {
                JSONObject params = data.optJSONObject(ZegoAIAgentActionDefines.ExpressKeys.params);
                if (params == null) return false;

                int msgType = params.optInt(ZegoAIAgentActionDefines.ExpressKeys.msgType, -1);
                String msgContent = params.optString(ZegoAIAgentActionDefines.ExpressKeys.msgContent);
                if (msgType != MSG_TYPE_RESPONSE || msgContent.isEmpty()) return false;

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
            put(object, ZegoAIAgentActionDefines.ProtocolKeys.priority, value.getPriority());
            put(object, ZegoAIAgentActionDefines.ProtocolKeys.samePriorityOption, value.getSamePriorityOption());
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
            put(object, ZegoAIAgentActionDefines.ProtocolKeys.priority, value.getPriority());
            put(object, ZegoAIAgentActionDefines.ProtocolKeys.samePriorityOption, value.getSamePriorityOption());
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
