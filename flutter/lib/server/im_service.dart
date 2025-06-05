import 'dart:async';
import 'package:flutter/cupertino.dart';

import 'package:zego_zim/zego_zim.dart';

import 'package:ai_agent_quickstart_flutter/server/zego_key.dart';
import 'package:ai_agent_quickstart_flutter/im/message.dart';
import 'ai_agent_service.dart';

class ZegoIMService {
  static final ZegoIMService _instance = ZegoIMService._internal();
  factory ZegoIMService() => _instance;
  ZegoIMService._internal();

  StreamController<ZegoIMMessage>? _messageController;
  Stream<ZegoIMMessage> get messageStream =>
      _messageController?.stream ?? Stream.empty();

  ZIM? _zim;
  bool _isInitialized = false;

  Future<bool> initialize() async {
    if (_isInitialized) {
      return true;
    }

    /// 创建新的消息控制器
    _messageController ??= StreamController<ZegoIMMessage>.broadcast();

    /// 创建ZIM实例
    ZIMAppConfig appConfig = ZIMAppConfig()..appID = ZegoKey.appId;
    _zim = ZIM.create(appConfig);
    if (_zim == null) {
      debugPrint('[im] 创建ZIM实例失败');
      return false;
    }

    /// 设置事件处理器
    _registerEventHandlers();

    _isInitialized = true;
    return true;
  }

  Future<bool> login() async {
    if (!_isInitialized) {
      final initResult = await initialize();
      if (!initResult) {
        return false;
      }
    }

    try {
      /// 获取token
      final token = await ZegoAIAgentService().getToken();
      final userId = ZegoAIAgentService().getUserId();

      /// 登录配置
      ZIMLoginConfig config = ZIMLoginConfig()
        ..userName = userId
        ..token = token;

      /// 登录
      await _zim!.login(userId, config);
      debugPrint('[im] ZIM登录成功，用户ID: $userId');

      /// 获取历史消息
      await fetchHistoryMessages();
      return true;
    } catch (e) {
      debugPrint('[im] ZIM登录失败：$e');
      return false;
    }
  }

  Future<bool> sendMessage(String content) async {
    if (!_isInitialized) {
      final initResult = await initialize();
      if (!initResult) {
        return false;
      }
    }

    try {
      /// 创建ZIM文本消息
      ZIMTextMessage zimMessage = ZIMTextMessage(message: content);

      /// 消息发送配置
      ZIMMessageSendConfig config = ZIMMessageSendConfig()
        ..priority = ZIMMessagePriority.medium;

      /// 发送消息
      final result = await _zim!.sendMessage(
        zimMessage,
        ZegoAIAgentService().getAgentRobotId(),
        ZIMConversationType.peer,
        config,
      );

      /// 使用返回的消息对象创建Flutter消息
      final userMessage = ZegoIMMessage(
        content: content,
        isFromUser: true,
        timestamp:
            DateTime.fromMillisecondsSinceEpoch(result.message.timestamp),
        orderKey: result.message.orderKey,
      );
      debugPrint(
        '[im] 发送消息,'
        'orderKey:${userMessage.orderKey}, '
        'timestamp:${userMessage.timestamp}, '
        'message:${userMessage.content}, ',
      );
      _messageController?.add(userMessage);

      return true;
    } catch (e) {
      debugPrint('[im] 消息发送失败：$e');
      return false;
    }
  }

  Future<void> fetchHistoryMessages() async {
    if (!_isInitialized) {
      return;
    }

    try {
      ZIMMessageQueryConfig config = ZIMMessageQueryConfig()
        ..count = 50
        ..reverse = true;

      final result = await _zim!.queryHistoryMessage(
        ZegoAIAgentService().getAgentRobotId(),
        ZIMConversationType.peer,
        config,
      );

      for (var message in result.messageList) {
        if (message is ZIMTextMessage) {
          debugPrint(
            '[im] 收到历史消息,'
            'senderUserID:${message.senderUserID}, '
            'orderKey:${message.orderKey}, '
            'timestamp:${message.timestamp}, '
            'messageSeq:${message.messageSeq}, '
            'message:${message.message}, ',
          );

          final flutterMessage = ZegoIMMessage(
            content: message.message,
            isFromUser:
                message.senderUserID == ZegoAIAgentService().getUserId(),
            timestamp: DateTime.fromMillisecondsSinceEpoch(message.timestamp),
            orderKey: message.orderKey,
          );
          _messageController?.add(flutterMessage);
        }
      }
    } catch (e) {
      debugPrint('[im] 获取历史消息失败：$e');
    }
  }

  void deinitialize() {
    _messageController?.close();
    _messageController = null;

    if (_isInitialized && _zim != null) {
      _unregisterEventHandlers();
      _zim!.logout();
      _zim!.destroy();
      _isInitialized = false;
    }
  }

  void _handleError(ZIM zim, ZIMError errorInfo) {
    debugPrint('[im] ZIM错误: ${errorInfo.message}');
  }

  void _handleConnectionStateChanged(ZIM zim, ZIMConnectionState state,
      ZIMConnectionEvent event, Map<dynamic, dynamic> extendedData) {
    debugPrint('[im] ZIM连接状态变化: $state');
  }

  void _handlePeerMessageReceived(
    ZIM zim,
    List<ZIMMessage> messageList,
    ZIMMessageReceivedInfo info,
    String fromUserID,
  ) {
    for (var message in messageList) {
      if (message is ZIMTextMessage) {
        debugPrint(
          '[im] 收到单聊消息,'
          'senderUserID:${message.senderUserID}, '
          'orderKey:${message.orderKey}, '
          'timestamp:${message.timestamp}, '
          'messageSeq:${message.messageSeq}, '
          'message:${message.message}, ',
        );

        final flutterMessage = ZegoIMMessage(
          content: message.message,
          isFromUser: message.senderUserID == ZegoAIAgentService().getUserId(),
          timestamp: DateTime.fromMillisecondsSinceEpoch(message.timestamp),
          orderKey: message.orderKey,
        );
        _messageController?.add(flutterMessage);
      }
    }
  }

  void _registerEventHandlers() {
    ZIMEventHandler.onError = _handleError;
    ZIMEventHandler.onConnectionStateChanged = _handleConnectionStateChanged;
    ZIMEventHandler.onPeerMessageReceived = _handlePeerMessageReceived;
  }

  void _unregisterEventHandlers() {
    ZIMEventHandler.onError = null;
    ZIMEventHandler.onConnectionStateChanged = null;
    ZIMEventHandler.onPeerMessageReceived = null;
  }
}
