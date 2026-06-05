package com.zego.agentaction;

public class ZegoAIAgentActionDefines {
    public static class ErrorCodes {
        public static final int SUCCESS = 0;
        public static final int TIMEOUT = -1;
        public static final int SEND_FAILED = -2;
        public static final int CANCELED = -3;
    }

    public static class ExpressMethods {
        /// 发送房间通道消息的方法名
        public static final String sendRoomChannelMessage = "liveroom.room.send_room_channel_message";

        /// 收到房间通道消息的回调方法名
        public static final String onReciveRoomChannelMessage = "liveroom.room.on_recive_room_channel_message";

        /// 发送房间通道消息结果的回调方法名
        public static final String onSendRoomChannelMessage = "liveroom.room.on_send_room_channel_message";
    }

    public static class ExpressKeys {
        public static final String method = "method";
        public static final String params = "params";
        public static final String roomId = "room_id";
        public static final String msgType = "msg_type";
        public static final String msgContent = "msg_content";
        public static final String userList = "user_list";
        public static final String seq = "seq";
        public static final String errorCode = "error_code";
        public static final String errorMessage = "error_message";
    }

    public static class ProtocolKeys {
        public static final String action = "Action";
        public static final String seq = "Seq";
        public static final String params = "Params";
        public static final String code = "Code";
        public static final String message = "Message";
        public static final String requestId = "RequestId";
        public static final String data = "Data";

        // Params 内部字段
        public static final String text = "Text";
        public static final String addHistory = "AddHistory";
        public static final String priority = "Priority";
        public static final String samePriorityOption = "SamePriorityOption";
        public static final String interruptMode = "InterruptMode";
        public static final String enqueueUserSpeech = "EnqueueUserSpeech";
        public static final String systemPrompt = "SystemPrompt";
        public static final String addQuestionToHistory = "AddQuestionToHistory";
        public static final String addAnswerToHistory = "AddAnswerToHistory";
        public static final String userId = "UserId";
    }
}
