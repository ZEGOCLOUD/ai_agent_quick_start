class LocalStrings {
  static const chatScreenTitle = '聊天';
  static const chatInputHint = '随便问...';
  static const sendButton = '发送';
  static const voiceButton = '语音';

  static const audioPageTitle = '语音聊天';
  static String roomIdLabel(String roomId) => 'RoomID = $roomId';
  static const logoutRoomButton = '退出房间';
  static const audioChatStartFailed = '音频聊天开始失败';
  static const audioChatStopFailed = '音频聊天停止失败';
  static const subtitlesCollapsed = '字幕 (点击展开)';
  static const subtitlesExpanded = '字幕 (点击收起)';
  static const audioChatNotice =
      '注意：\n1.同一个AppID 内，需保证 "userID 全局唯一，否则会互踢。\n2.请现在服务端创建对应的智能体，并在Call时同步创建智能体实例。';
}
