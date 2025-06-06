import 'message_command.dart';

/// 说话状态枚举
///
/// 定义了说话过程中的不同状态，用于标记说话的开始和结束。
/// 此状态对于管理音频流和界面提示至关重要。
enum ZegoAIAgentSubtitlesSpeakStatus {
  /// 说话开始 - 表示用户或AI开始发言
  start(1),

  /// 说话结束 - 表示用户或AI结束发言
  end(2);

  final int value;
  const ZegoAIAgentSubtitlesSpeakStatus(this.value);

  static ZegoAIAgentSubtitlesSpeakStatus fromValue(int value) {
    return ZegoAIAgentSubtitlesSpeakStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => ZegoAIAgentSubtitlesSpeakStatus.start,
    );
  }
}

/// 说话状态数据
///
/// 用于传递说话状态信息，包含说话状态和用户ID。
/// 此数据结构对于管理音频流和界面提示至关重要。
class ZegoSpeakStatusData {
  /// 说话状态
  final ZegoAIAgentSubtitlesSpeakStatus speakStatus;

  /// 用户ID
  final String userId;

  ZegoSpeakStatusData({
    required this.speakStatus,
    required this.userId,
  });

  factory ZegoSpeakStatusData.fromJson(Map<String, dynamic> json) {
    return ZegoSpeakStatusData(
      speakStatus:
          ZegoAIAgentSubtitlesSpeakStatus.fromValue(json['speakStatus'] as int),
      userId: json['userId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'speakStatus': speakStatus.value,
      'userId': userId,
    };
  }
}

/// ASR字幕数据
class ZegoASRTextData {
  final String text;
  final String messageId;
  final bool endFlag;

  ZegoASRTextData({
    required this.text,
    required this.messageId,
    required this.endFlag,
  });

  factory ZegoASRTextData.fromJson(Map<String, dynamic> json) {
    String text = '';
    String messageId = '';
    bool endFlag = false;
    if (json.containsKey('Text')) {
      text = json['Text'] ?? '';
    }
    if (json.containsKey('MessageId')) {
      messageId = json['MessageId'] ?? '';
    }
    if (json.containsKey('EndFlag')) {
      var val = json['EndFlag'];
      if (val is bool) {
        endFlag = val;
      } else if (val is int) {
        endFlag = val != 0;
      } else if (val is String) {
        endFlag = val == 'true' || val == '1';
      }
    }
    return ZegoASRTextData(text: text, messageId: messageId, endFlag: endFlag);
  }
}

/// LLM字幕数据
class ZegoLLMTextData {
  final String text;
  final String messageId;
  final bool endFlag;

  ZegoLLMTextData({
    required this.text,
    required this.messageId,
    required this.endFlag,
  });

  factory ZegoLLMTextData.fromJson(Map<String, dynamic> json) {
    String text = '';
    String messageId = '';
    bool endFlag = false;
    if (json.containsKey('Text')) {
      text = json['Text'] ?? '';
    }
    if (json.containsKey('MessageId')) {
      messageId = json['MessageId'] ?? '';
    }
    if (json.containsKey('EndFlag')) {
      var val = json['EndFlag'];
      if (val is bool) {
        endFlag = val;
      } else if (val is int) {
        endFlag = val != 0;
      } else if (val is String) {
        endFlag = val == 'true' || val == '1';
      }
    }
    return ZegoLLMTextData(text: text, messageId: messageId, endFlag: endFlag);
  }
}

/// 字幕消息协议模型
class ZegoSubtitlesMessageProtocol {
  final int timestamp;
  final int seqId;
  final int round;
  final ZegoSubtitlesMessageCommand? cmdType;
  final Map<String, dynamic> data;

  /// 结构化字段，便于直接访问
  ZegoSpeakStatusData? userSpeakData;
  ZegoSpeakStatusData? agentSpeakData;
  ZegoASRTextData? asrTextData;
  ZegoLLMTextData? llmTextData;

  ZegoSubtitlesMessageProtocol({
    required this.timestamp,
    required this.seqId,
    required this.round,
    required this.cmdType,
    required this.data,
  }) {
    _parseDataForCmd();
  }

  /// 从JSON构造协议对象，并根据命令类型解析特定数据
  factory ZegoSubtitlesMessageProtocol.fromJson(Map<String, dynamic> json) {
    final protocol = ZegoSubtitlesMessageProtocol(
      timestamp: json['Timestamp'] ?? 0,
      seqId: json['SeqId'] ?? 0,
      round: json['Round'] ?? 0,
      cmdType: ZegoSubtitlesMessageCommandExtension.fromInt(json['Cmd'] ?? 0),
      data: json['Data'] != null ? Map<String, dynamic>.from(json['Data']) : {},
    );
    return protocol;
  }

  /// 根据命令类型解析特定数据
  void _parseDataForCmd() {
    switch (cmdType) {
      case ZegoSubtitlesMessageCommand.userSpeakStatus:
        userSpeakData = ZegoSpeakStatusData.fromJson(data);
        break;
      case ZegoSubtitlesMessageCommand.agentSpeakStatus:
        agentSpeakData = ZegoSpeakStatusData.fromJson(data);
        break;
      case ZegoSubtitlesMessageCommand.asrText:
        asrTextData = ZegoASRTextData.fromJson(data);
        break;
      case ZegoSubtitlesMessageCommand.llmText:
        llmTextData = ZegoLLMTextData.fromJson(data);
        break;
      default:
        break;
    }
  }
}
