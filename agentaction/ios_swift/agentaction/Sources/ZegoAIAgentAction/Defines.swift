import Foundation

public enum ZegoAIAgentActionErrorCodes {
    public static let success = 0
    public static let timeout = -1
    public static let sendFailed = -2
    public static let canceled = -3
}

public enum ZegoAIAgentActionName {
    public static let sendAgentInstanceTTS = "SendAgentInstanceTTS"
    public static let sendAgentInstanceLLM = "SendAgentInstanceLLM"
    public static let interruptAgentInstance = "InterruptAgentInstance"
    public static let startListening = "StartListening"
    public static let stopListening = "StopListening"
}

public enum ZegoAIAgentActionMsgType {
    public static let request = 20
    public static let response = 22
}

public enum ZegoAIAgentActionExpressMethods {
    /// 发送房间通道消息的方法名
    public static let sendRoomChannelMessage = "liveroom.room.send_room_channel_message"

    /// 收到房间通道消息的回调方法名
    public static let onReciveRoomChannelMessage = "liveroom.room.on_recive_room_channel_message"

    /// 发送房间通道消息结果的回调方法名
    public static let onSendRoomChannelMessage = "liveroom.room.on_send_room_channel_message"
}

public enum ZegoAIAgentActionExpressKeys {
    public static let method = "method"
    public static let params = "params"
    public static let roomId = "room_id"
    public static let msgType = "msg_type"
    public static let msgContent = "msg_content"
    public static let userList = "user_list"
    public static let seq = "seq"
    public static let errorCode = "error_code"
    public static let errorMessage = "error_message"
}

public enum ZegoAIAgentActionProtocolKeys {
    public static let action = "Action"
    public static let seq = "Seq"
    public static let params = "Params"
    public static let code = "Code"
    public static let message = "Message"
    public static let requestId = "RequestId"
    public static let data = "Data"

    // Params 内部字段
    public static let text = "Text"
    public static let addHistory = "AddHistory"
    public static let priority = "Priority"
    public static let samePriorityOption = "SamePriorityOption"
    public static let interruptMode = "InterruptMode"
    public static let enqueueUserSpeech = "EnqueueUserSpeech"
    public static let systemPrompt = "SystemPrompt"
    public static let addQuestionToHistory = "AddQuestionToHistory"
    public static let addAnswerToHistory = "AddAnswerToHistory"
    public static let userId = "UserId"
}
