import 'package:flutter/material.dart';

import 'package:ai_agent_quickstart_flutter/audio/subtitles/protocol/message_protocol.dart';
import '../protocol/message_model.dart';

/// 字幕消息数据模型，负责所有数据和处理逻辑
class ZegoSubtitlesViewModel {
  /// 临时ASR消息表，key为messageId，value为消息模型
  final Map<String, ZegoSubtitlesMessageModel> tempAsrMsgMap = {};

  /// 临时LLM消息表，key为round，value为<seqId, 消息模型>的map
  final Map<int, Map<int, ZegoSubtitlesMessageModel>> tempLLMMsgMap = {};

  /// LLM消息回合endFlag管理队列
  final List<int> roundEndFlagQueue = [];

  /// 主消息表，最终显示在UI上的消息
  final List<ZegoSubtitlesMessageModel> chatMsgList = [];

  /// 外部可监听的消息历史
  final ValueNotifier<List<ZegoSubtitlesMessageModel>> historyNotifier =
      ValueNotifier([]);

  /// 处理ASR消息（与iOS TableView一致）
  void handleRecvAsrMessage(ZegoSubtitlesMessageProtocol message) {
    final asr = message.asrTextData;
    if (asr == null || asr.text.isEmpty) {
      return;
    }

    final messageId = asr.messageId;
    final seqId = message.seqId;
    final round = message.round;
    final timestamp = message.timestamp;
    final endFlag = asr.endFlag;
    final content = asr.text;

    final existModel = tempAsrMsgMap[messageId];
    if (existModel == null) {
      /// 新消息
      final model = ZegoSubtitlesMessageModel(
        seqId: seqId,
        round: round,
        isMine: true,
        content: content,
        timestamp: timestamp,
        messageId: messageId,
        endFlag: endFlag,
      );
      tempAsrMsgMap[messageId] = model;
      chatMsgList.add(model);
    } else if (existModel.messageId == messageId) {
      if (seqId < existModel.seqId) {
        /// 已有的seqId更新过了，不处理
      } else {
        /// 用copyWith新建对象并替换
        final updated = existModel.copyWith(
          content: content,
          seqId: seqId,
          timestamp: timestamp,
          endFlag: endFlag,
        );
        tempAsrMsgMap[messageId] = updated;
        final idx = chatMsgList.indexOf(existModel);
        if (idx != -1) {
          chatMsgList[idx] = updated;
        }
      }
    }
    _resortAndNotify();
  }

  /// 处理LLM消息（与iOS TableView一致）
  void handleRecvLLMMessage(ZegoSubtitlesMessageProtocol message) {
    final llm = message.llmTextData;
    if (llm == null || llm.text.isEmpty) {
      return;
    }

    final messageId = llm.messageId;
    final seqId = message.seqId;
    final round = message.round;
    final timestamp = message.timestamp;
    final endFlag = llm.endFlag;
    final content = llm.text;

    /// 1. 按round分组
    tempLLMMsgMap.putIfAbsent(round, () => {});
    final roundMap = tempLLMMsgMap[round]!;
    roundMap[seqId] = ZegoSubtitlesMessageModel(
      seqId: seqId,
      round: round,
      isMine: false,
      content: content,
      timestamp: timestamp,
      messageId: messageId,
      endFlag: endFlag,
    );

    /// 2. 检查messageId变化，清理旧消息
    if (roundMap.length > 1) {
      final first = roundMap.values.first;
      if (first.messageId != messageId) {
        /// 找最大seqId
        final maxSeqId = roundMap.keys.reduce((a, b) => a > b ? a : b);
        if (seqId > maxSeqId) {
          roundMap.clear();

          /// 主表也要删
          chatMsgList.removeWhere((m) => m.messageId == first.messageId);
        }
      }
    }

    /// 3. 拼接totalContent
    final sortedSeqIds = roundMap.keys.toList()..sort();
    String totalContent = '';
    for (final k in sortedSeqIds) {
      totalContent += roundMap[k]?.content ?? '';
    }

    /// 4. 更新主表
    final existIdx = chatMsgList.indexWhere((m) => m.messageId == messageId);
    final updated = ZegoSubtitlesMessageModel(
      seqId: seqId,
      round: round,
      isMine: false,
      content: totalContent,
      timestamp: timestamp,
      messageId: messageId,
      endFlag: endFlag,
    );
    if (existIdx == -1) {
      chatMsgList.add(updated);
    } else {
      chatMsgList[existIdx] = updated;
    }
    _resortAndNotify();

    /// 5. endFlag延迟清理
    if (!roundEndFlagQueue.contains(round)) {
      roundEndFlagQueue.add(round);
    }
    if (roundEndFlagQueue.length > 3) {
      final key = roundEndFlagQueue.removeAt(0);
      tempLLMMsgMap.remove(key);
    }
  }

  void _resortAndNotify() {
    /// 按seqId排序
    chatMsgList.sort((a, b) => a.seqId.compareTo(b.seqId));
    historyNotifier.value = List<ZegoSubtitlesMessageModel>.from(chatMsgList);
  }
}
