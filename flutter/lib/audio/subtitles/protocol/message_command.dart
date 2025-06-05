/// 消息命令类型枚举
enum ZegoSubtitlesMessageCommand {
  /// 用户说话状态 - 表示用户开始或结束说话
  userSpeakStatus, // 1

  /// 智能体说话状态 - 表示AI智能体开始或结束回复
  agentSpeakStatus, // 2

  /// 识别的ASR文本 - 语音识别结果
  asrText, // 3

  /// LLM文本 - 大语言模型生成的回复文本
  llmText, // 4
}

extension ZegoSubtitlesMessageCommandExtension on ZegoSubtitlesMessageCommand {
  int get value {
    switch (this) {
      case ZegoSubtitlesMessageCommand.userSpeakStatus:
        return 1;
      case ZegoSubtitlesMessageCommand.agentSpeakStatus:
        return 2;
      case ZegoSubtitlesMessageCommand.asrText:
        return 3;
      case ZegoSubtitlesMessageCommand.llmText:
        return 4;
    }
  }

  static ZegoSubtitlesMessageCommand? fromInt(int v) {
    switch (v) {
      case 1:
        return ZegoSubtitlesMessageCommand.userSpeakStatus;
      case 2:
        return ZegoSubtitlesMessageCommand.agentSpeakStatus;
      case 3:
        return ZegoSubtitlesMessageCommand.asrText;
      case 4:
        return ZegoSubtitlesMessageCommand.llmText;
      default:
        return null;
    }
  }
}
