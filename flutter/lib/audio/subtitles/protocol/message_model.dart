import 'package:ai_agent_quickstart_flutter/audio/subtitles/protocol/message_protocol.dart';

/// 字幕消息模型
class ZegoSubtitlesMessageModel {
  /// 消息序列号
  final int seqId;

  /// 对话轮次
  final int round;

  /// 是否为自己发送的消息
  final bool isMine;

  /// 消息内容
  final String content;

  /// 时间戳
  final int timestamp;

  /// 消息ID
  final String messageId;

  /// 是否为结束标志
  final bool endFlag;

  ZegoSubtitlesMessageModel({
    required this.seqId,
    required this.round,
    required this.isMine,
    required this.content,
    required this.timestamp,
    required this.messageId,
    required this.endFlag,
  });

  /// 创建消息副本
  ZegoSubtitlesMessageModel copyWith({
    int? seqId,
    int? round,
    bool? isMine,
    String? content,
    int? timestamp,
    String? messageId,
    bool? endFlag,
  }) {
    return ZegoSubtitlesMessageModel(
      seqId: seqId ?? this.seqId,
      round: round ?? this.round,
      isMine: isMine ?? this.isMine,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      messageId: messageId ?? this.messageId,
      endFlag: endFlag ?? this.endFlag,
    );
  }

  /// 从协议消息创建模型
  factory ZegoSubtitlesMessageModel.fromProtocol(
      ZegoSubtitlesMessageProtocol protocol, bool isMine) {
    String content = '';
    if (isMine && protocol.asrTextData?.text != null) {
      content = protocol.asrTextData!.text;
    } else if (!isMine && protocol.llmTextData?.text != null) {
      content = protocol.llmTextData!.text;
    }
    return ZegoSubtitlesMessageModel(
      seqId: protocol.seqId,
      round: protocol.round,
      isMine: isMine,
      content: content,
      timestamp: protocol.timestamp,
      messageId: protocol.data['message_id'] ?? '',
      endFlag: protocol.data['end_flag'] ?? false,
    );
  }
}
