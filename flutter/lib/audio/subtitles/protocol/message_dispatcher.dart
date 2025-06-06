import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'message_protocol.dart';
import 'message_command.dart';

/// 字幕消息事件处理器接口
abstract class ZegoSubtitlesEventHandler {
  /// 收到ASR字幕消息回调
  void onRecvAsrChatMsg(ZegoSubtitlesMessageProtocol message);

  /// 收到LLM字幕消息回调
  void onRecvLLMChatMsg(ZegoSubtitlesMessageProtocol message);
}

/// 字幕消息分发器（单例）
class ZegoSubtitlesMessageDispatcher {
  static final ZegoSubtitlesMessageDispatcher _instance =
      ZegoSubtitlesMessageDispatcher._internal();
  factory ZegoSubtitlesMessageDispatcher() => _instance;
  ZegoSubtitlesMessageDispatcher._internal();

  final List<ZegoSubtitlesEventHandler> _eventHandlers = [];
  final StreamController<ZegoSubtitlesMessageProtocol> _messageController =
      StreamController<ZegoSubtitlesMessageProtocol>.broadcast();

  /// 注册字幕事件处理器
  void registerEventHandler(ZegoSubtitlesEventHandler handler) {
    if (!_eventHandlers.contains(handler)) {
      _eventHandlers.add(handler);
    }
  }

  /// 注销字幕事件处理器
  void unregisterEventHandler(ZegoSubtitlesEventHandler handler) {
    _eventHandlers.remove(handler);
  }

  /// 分发收到的字幕消息
  void handleMessage(ZegoSubtitlesMessageProtocol message) {
    _messageController.add(message);
    switch (message.cmdType) {
      case ZegoSubtitlesMessageCommand.asrText:
        for (var handler in _eventHandlers) {
          handler.onRecvAsrChatMsg(message);
        }
        break;
      case ZegoSubtitlesMessageCommand.llmText:
        for (var handler in _eventHandlers) {
          handler.onRecvLLMChatMsg(message);
        }
        break;
      default:
        break;
    }
  }

  /// 获取消息流
  Stream<ZegoSubtitlesMessageProtocol> get messageStream =>
      _messageController.stream;

  /// 销毁分发器
  void dispose() {
    _messageController.close();
    _eventHandlers.clear();
  }

  /// 统一处理原始ExperimentalAPI内容
  /// Unified handler for raw ExperimentalAPI content
  static void handleExpressExperimentalAPIContent(String content) {
    try {
      final contentMap = jsonDecode(content);
      if (contentMap['method'] !=
          'liveroom.room.on_recive_room_channel_message') {
        debugPrint('[SubtitlesDispatcher] 非字幕消息，method不匹配，直接返回');
        return;
      }

      final params = contentMap['params'];
      if (params == null) {
        debugPrint('[SubtitlesDispatcher] params为null，直接返回');
        return;
      }

      final msgContent = params['msg_content'];
      if (msgContent == null) {
        debugPrint('[SubtitlesDispatcher] msg_content为null，直接返回');
        return;
      }

      final msgMap = jsonDecode(msgContent);
      final protocol = ZegoSubtitlesMessageProtocol.fromJson(msgMap);
      ZegoSubtitlesMessageDispatcher().handleMessage(protocol);
    } catch (e) {
      debugPrint('handleExpressExperimentalAPIContent: 解析$content失败');
    }
  }
}
