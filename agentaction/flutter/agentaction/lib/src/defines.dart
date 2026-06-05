class ZegoAIAgentActionErrorCodes {
  static const success = 0;
  static const timeout = -1;
  static const sendFailed = -2;
  static const canceled = -3;
}

class ZegoAIAgentActionNames {
  static const sendAgentInstanceTTS = 'SendAgentInstanceTTS';
  static const sendAgentInstanceLLM = 'SendAgentInstanceLLM';
  static const interruptAgentInstance = 'InterruptAgentInstance';
  static const startListening = 'StartListening';
  static const stopListening = 'StopListening';
}

class ZegoAIAgentActionMsgTypes {
  static const request = 20;
  static const response = 22;
}

class ZegoAIAgentActionExpressMethods {
  /// 发送房间通道消息的方法名
  static const sendRoomChannelMessage = 'liveroom.room.send_room_channel_message';

  /// 收到房间通道消息的回调方法名
  static const onReciveRoomChannelMessage = 'liveroom.room.on_recive_room_channel_message';

  /// 发送房间通道消息结果的回调方法名
  static const onSendRoomChannelMessage = 'liveroom.room.on_send_room_channel_message';
}

class ZegoAIAgentActionExpressKeys {
  static const method = 'method';
  static const params = 'params';
  static const roomId = 'room_id';
  static const msgType = 'msg_type';
  static const msgContent = 'msg_content';
  static const userList = 'user_list';
  static const seq = 'seq';
  static const errorCode = 'error_code';
  static const errorMessage = 'error_message';
}

class ZegoAIAgentActionProtocolKeys {
  static const action = 'Action';
  static const seq = 'Seq';
  static const params = 'Params';
  static const code = 'Code';
  static const message = 'Message';
  static const requestId = 'RequestId';
  static const data = 'Data';

  // Params 内部字段
  static const text = 'Text';
  static const addHistory = 'AddHistory';
  static const priority = 'Priority';
  static const samePriorityOption = 'SamePriorityOption';
  static const interruptMode = 'InterruptMode';
  static const enqueueUserSpeech = 'EnqueueUserSpeech';
  static const systemPrompt = 'SystemPrompt';
  static const addQuestionToHistory = 'AddQuestionToHistory';
  static const addAnswerToHistory = 'AddAnswerToHistory';
  static const userId = 'UserId';
}
