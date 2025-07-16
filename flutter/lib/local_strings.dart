class LocalStrings {
  static const chatScreenTitle = 'Chat';
  static const chatInputHint = 'Ask anything...';
  static const sendButton = 'Send';
  static const voiceButton = 'Voice';

  static const audioPageTitle = 'VideoChat';
  static const digitalHumanPageTitle = 'DigitalHumanChat';
  static String roomIdLabel(String roomId) => 'RoomID = $roomId';
  static const logoutRoomButton = 'LogoutRoom';
  static const loginRoomButton = 'LoginRoom';
  static const audioChatStartFailed = 'Audio chat start failed';
  static const audioChatStopFailed = 'Audio chat stop failed';
  static const subtitlesCollapsed = 'subtitles (Click to expand)';
  static const subtitlesExpanded = 'subtitles (Click to collapse)';
  static const audioChatNotice =
      'Note:\n1.Within the same AppID, ensure "userID" is globally unique, otherwise users will be kicked out.\n2.Please create the corresponding agent on the server first, and create the agent instance synchronously during Call.';
}
