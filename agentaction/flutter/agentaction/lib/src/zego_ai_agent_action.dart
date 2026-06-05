import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:protobuf/protobuf.dart';

import 'defines.dart';
import 'generated/ai_agent_action.pb.dart';
import 'logger.dart';

/// 套件透传给业务方的发送参数，业务侧在 [ZegoAIAgentActionSender] 回调中拿到。
///
/// 该结构与 [ZegoAIAgentActionClient] 内部的 Express 协议一致：
///   - 调用 [ZegoExpressEngine.callExperimentalAPI] 时，业务方只需要把
///     `formatedJson` 透传给 Express SDK 即可；
///   - [msgContent] 字段在 [ZegoAIAgentActionClient] 内部已构造完成，可用于业务
///     侧在日志中记录请求体内容。
class ZegoAIAgentActionSendParams {
  /// 业务侧请求的目标 RTC 房间 ID，对应 Express 协议 `room_id`。
  final String roomId;

  /// Express 消息类型，本期仅使用 `20`（请求）。
  final int msgType;

  /// 业务链路追踪标识（与 `msgContent.Seq` 一致），业务侧可用于日志关联。
  final String seq;

  /// 业务请求 `msg_content` 字符串，已被 [ZegoAIAgentActionClient] 序列化为 JSON。
  final String msgContent;

  /// 接收方用户列表，本期通常为单个智能体 userId。
  final List<String> userList;

  ZegoAIAgentActionSendParams({
    required this.roomId,
    required this.msgType,
    required this.seq,
    required this.msgContent,
    required this.userList,
  });

  /// 转换为 Map，便于业务侧在日志中直接打印。
  Map<String, dynamic> toJson() => {
        'roomId': roomId,
        'msgType': msgType,
        'seq': seq,
        'msgContent': msgContent,
        'userList': userList,
      };

  @override
  String toString() => toJson().toString();
}

/// [ZegoAIAgentActionSender] 的返回结果。
///
/// 业务侧调用 [ZegoExpressEngine.callExperimentalAPI] 时只需把
/// `formatedJson` 透传给 Express SDK；SDK 成功调用后 [errorCode] 应为
/// [ZegoAIAgentActionErrorCodes.success]；否则 Kit 会将此次请求标记为
/// "express 发送失败" 并触发 onError 回调。
class ZegoAIAgentActionSendResult {
  /// 0 表示成功；其它值由 Express SDK 内部定义。
  final int errorCode;

  /// 业务链路追踪标识。
  final String seq;

  ZegoAIAgentActionSendResult({required this.errorCode, required this.seq});
}

/// 智能体实例控制响应，由 [ZegoAIAgentActionClient] 在收到 `msg_type=22` 响应时构造。
class ZegoAIAgentActionResponse {
  /// 原始 Action，例如 `SendAgentInstanceTTS`。
  final String action;

  /// 业务链路追踪标识（与上行请求 `msg_content.Seq` 一致）。
  final String seq;

  /// 处理结果码，0 表示成功；其它值由 PaaS 端定义。
  final int code;

  /// 处理结果说明，失败时包含错误信息。
  final String message;

  /// PaaS 调用的智能体控制接口返回的 RequestId。
  final String requestId;

  /// PaaS 返回的业务数据，可为空。
  final Object? data;

  /// 原始 `msg_content` JSON 字符串，便于业务侧二次解析。
  final String rawMessage;

  ZegoAIAgentActionResponse({
    required this.action,
    required this.seq,
    required this.code,
    required this.message,
    this.requestId = '',
    this.data,
    this.rawMessage = '',
  });

  @override
  String toString() => 'ZegoAIAgentActionResponse(seq=$seq, code=$code, action=$action, message=$message)';
}

/// 智能体实例控制错误。
///
/// 可能在以下场景触发：
///   - PaaS 端业务处理失败（[code] 不为 0）；
///   - Express 发送失败（[code] 为 [ZegoAIAgentActionErrorCodes.sendFailed]）；
///   - 请求超时（[code] 为 [ZegoAIAgentActionErrorCodes.timeout]）；
///   - 主动取消（[code] 为 [ZegoAIAgentActionErrorCodes.canceled]）。
class ZegoAIAgentActionError implements Exception {
  /// 业务链路追踪标识。
  final String seq;

  /// 原始 Action。
  final String action;

  /// 错误码。
  ///
  /// PaaS 端业务错误时为业务返回的 `Code`；本地套件错误时为
  /// [ZegoAIAgentActionErrorCodes] 中的预定义值。
  final Object code;

  /// 错误描述。
  final String message;

  ZegoAIAgentActionError(this.seq, this.action, this.code, this.message);

  @override
  String toString() => 'ZegoAIAgentActionError($code, $action, $seq, $message)';
}

/// 业务侧实现的发送回调。
///
/// 业务侧在该回调中应：
///   1. 将 [formatedJson] 直接透传给 [ZegoExpressEngine.callExperimentalAPI]；
///   2. SDK 回调成功时通过 [ZegoAIAgentActionSendResult.errorCode] 标记为
///      [ZegoAIAgentActionErrorCodes.success]；
///   3. SDK 回调失败时使用 SDK 原始错误码并保持 [ZegoAIAgentActionSendResult.seq]
///      不变，Kit 会将此次请求标记为失败并触发 [ZegoAIAgentActionErrorHandler]。
typedef ZegoAIAgentActionSender = Future<ZegoAIAgentActionSendResult> Function(
    ZegoAIAgentActionSendParams params, String formatedJson);

/// 业务侧实现的响应回调。
///
/// 每次收到 PaaS 端业务响应时（无论成功或失败）都会触发；如果仅关心成功响应，
/// 可以忽略非零 [ZegoAIAgentActionResponse.code] 的回调。
typedef ZegoAIAgentActionResponseHandler = void Function(
    ZegoAIAgentActionResponse response);

/// 业务侧实现的错误回调。
///
/// 触发时机：
///   - PaaS 端业务处理失败（[ZegoAIAgentActionError.code] 为 PaaS 返回码）；
///   - Express 发送失败 / 超时 / 主动取消（[ZegoAIAgentActionError.code] 为
///     [ZegoAIAgentActionErrorCodes] 中的预定义值）。
typedef ZegoAIAgentActionErrorHandler = void Function(
    ZegoAIAgentActionError error);

/// 智能体实例控制客户端。
///
/// 负责将业务侧发起的 TTS / LLM / 打断 / 聆听等请求透明地上送到 PaaS，
/// 并在收到 PaaS 响应后回传给业务侧。
///
/// 使用流程：
///   1. 业务侧构造一个 [ZegoAIAgentActionSender]（通常实现为直接调用
///      [ZegoExpressEngine.callExperimentalAPI]），传入构造函数；
///   2. 在 [ZegoExpressEngine.onRecvExperimentalAPI] 回调中，将实验性 API
///      回调内容（`content` 字符串）原样传给 [handleRoomChannelMessage]；
///   3. 调用 [sendAgentInstanceTTS] / [sendAgentInstanceLLM] / 等方法发起请求；
///   4. 通过 `Future` 等待结果，或在 [onResponse] / [onError] 中接收异步通知。
class ZegoAIAgentActionClient {
  /// 业务侧请求的目标 RTC 房间 ID。
  final String roomId;

  /// 目标智能体实例的 userId，上行消息将定向发送给该用户。
  final String agentUserId;

  /// 当前客户端的 userId，用于生成本地业务链路追踪标识。
  final String userId;

  /// 设备 ID，本地自增 seq 时会拼接，确保多端命名空间隔离。
  final String deviceId;

  /// 请求默认超时时间（毫秒），可通过各方法的 `timeoutMs` 参数覆盖。
  final int timeoutMs;

  /// 业务侧实现的发送回调。
  final ZegoAIAgentActionSender sender;

  /// 业务侧实现的响应回调（可选）。
  final ZegoAIAgentActionErrorHandler? onError;

  /// 业务侧实现的错误回调（可选）。
  final ZegoAIAgentActionResponseHandler? onResponse;

  final Map<String, _PendingAction> _pending = {};
  final Map<int, String> _expressPending = {};
  int _localSeq = 0;
  int _expressSeq = 0;

  /// 构造一个客户端实例。
  ///
  /// [roomId]、[agentUserId]、[userId] 必填且不能为空；[sender] 为 Express SDK
  /// 透传回调。
  ZegoAIAgentActionClient({
    required this.roomId,
    required this.agentUserId,
    required this.userId,
    required this.sender,
    String? deviceId,
    this.timeoutMs = 5000,
    this.onResponse,
    this.onError,
  }) : deviceId = deviceId ?? _createDeviceId() {
    _requireString(roomId, 'roomId');
    _requireString(agentUserId, 'agentUserId');
    _requireString(userId, 'userId');
  }

  /// 主动调用 TTS。
  ///
  /// 对应 5 类控制能力中的"主动调用 TTS"，业务侧传入 [SendAgentInstanceTTSParams]
  /// 即可发起。
  Future<ZegoAIAgentActionResponse> sendAgentInstanceTTS(
    SendAgentInstanceTTSParams params, {
    int? timeoutMs,
  }) {
    _requireString(params.text, 'text');
    return _send(
      ZegoAIAgentActionNames.sendAgentInstanceTTS,
      params,
      timeoutMs: timeoutMs,
    );
  }

  /// 主动调用 LLM。
  ///
  /// 对应 5 类控制能力中的"主动调用 LLM"，业务侧传入 [SendAgentInstanceLLMParams]
  /// 即可发起。
  Future<ZegoAIAgentActionResponse> sendAgentInstanceLLM(
    SendAgentInstanceLLMParams params, {
    int? timeoutMs,
  }) {
    _requireString(params.text, 'text');
    return _send(
      ZegoAIAgentActionNames.sendAgentInstanceLLM,
      params,
      timeoutMs: timeoutMs,
    );
  }

  /// 打断智能体实例。
  ///
  /// 对应 5 类控制能力中的"打断智能体实例"。
  Future<ZegoAIAgentActionResponse> interruptAgentInstance({int? timeoutMs}) {
    return _send(
      ZegoAIAgentActionNames.interruptAgentInstance,
      InterruptAgentInstanceParams(),
      timeoutMs: timeoutMs,
    );
  }

  /// 智能体开始聆听。
  ///
  /// 对应 5 类控制能力中的"开始聆听"，业务侧可传入 [StartListeningParams] 指定聆听用户。
  Future<ZegoAIAgentActionResponse> startListening(
    StartListeningParams params, {
    int? timeoutMs,
  }) {
    return _send(
      ZegoAIAgentActionNames.startListening,
      params,
      timeoutMs: timeoutMs,
    );
  }

  /// 智能体结束聆听。
  ///
  /// 对应 5 类控制能力中的"结束聆听"，业务侧可传入 [StopListeningParams] 指定聆听用户。
  Future<ZegoAIAgentActionResponse> stopListening(
    StopListeningParams params, {
    int? timeoutMs,
  }) {
    return _send(
      ZegoAIAgentActionNames.stopListening,
      params,
      timeoutMs: timeoutMs,
    );
  }

  /// 接收 Express 实验性 API 回调内容。
  ///
  /// 业务侧应在 [ZegoExpressEngine.onRecvExperimentalAPI] 回调中调用此方法，
  /// 把回调中的 `content` 字符串原样传入；Kit 会自动识别 `on_recive_room_channel_message`
  /// 与 `on_send_room_channel_message` 两种回调，匹配到对应的请求。
  ///
  /// 返回 `true` 表示该消息被本客户端消费，`false` 表示与本客户端无关（可能是其他
  /// 业务消息或解析失败）。
  bool handleRoomChannelMessage(String content) {
    ZegoAIAgentActionLogger.debug('handleRoomChannelMessage recv: $content');
    try {
      final data = jsonDecode(content) as Map<String, dynamic>;
      final method = data[ZegoAIAgentActionExpressKeys.method] as String?;

      if (method == ZegoAIAgentActionExpressMethods.onReciveRoomChannelMessage) {
        final params = data[ZegoAIAgentActionExpressKeys.params] as Map<String, dynamic>?;
        if (params == null) return false;

        final msgType = params[ZegoAIAgentActionExpressKeys.msgType] as int?;
        final msgContent = params[ZegoAIAgentActionExpressKeys.msgContent] as String?;
        if (msgType == null || msgContent == null) return false;

        if (msgType != ZegoAIAgentActionMsgTypes.response) return false;
        final contentMap = jsonDecode(msgContent) as Map<String, dynamic>;
        final responsePb = _decodeResponse(contentMap);
        final seq = responsePb.seq;
        if (seq.isEmpty || responsePb.action.isEmpty || !contentMap.containsKey(ZegoAIAgentActionProtocolKeys.code)) {
          ZegoAIAgentActionLogger.warn('on_recive_room_channel_message missing required fields: $contentMap');
          return false;
        }
        final pending = _pending.remove(seq);
        if (pending == null) {
          ZegoAIAgentActionLogger.warn('on_recive_room_channel_message orphan seq=$seq');
          return false;
        }
        pending.timer.cancel();

        // 同时也清理 expressPending
        _expressPending.removeWhere((key, value) => value == seq);

        final response = ZegoAIAgentActionResponse(
          action: responsePb.action,
          seq: seq,
          code: responsePb.code,
          message: responsePb.message,
          requestId: responsePb.requestId,
          data: contentMap[ZegoAIAgentActionProtocolKeys.data],
          rawMessage: msgContent,
        );
        ZegoAIAgentActionLogger.info('recv action=${response.action} seq=${response.seq} code=${response.code} message=${response.message}');
        onResponse?.call(response);
        if (response.code == ZegoAIAgentActionErrorCodes.success) {
          pending.completer.complete(response);
        } else {
          final error = ZegoAIAgentActionError(
              response.seq, response.action, response.code, response.message);
          onError?.call(error);
          pending.completer.completeError(error);
        }
        return true;
      } else if (method == ZegoAIAgentActionExpressMethods.onSendRoomChannelMessage) {
        final params = data[ZegoAIAgentActionExpressKeys.params] as Map<String, dynamic>?;
        if (params == null) return false;

        final errorCode = params[ZegoAIAgentActionExpressKeys.errorCode] as int?;
        final expressSeq = params[ZegoAIAgentActionExpressKeys.seq] as int?;

        if (errorCode != null && errorCode != ZegoAIAgentActionErrorCodes.success && expressSeq != null) {
          final seq = _expressPending.remove(expressSeq);
          if (seq != null) {
            final pending = _pending.remove(seq);
            if (pending != null) {
              pending.timer.cancel();
              final errorMessage = (params[ZegoAIAgentActionExpressKeys.errorMessage] as String?) ?? '';
              ZegoAIAgentActionLogger.warn('on_send_room_channel_message error seq=$seq errorCode=$errorCode message=$errorMessage');
              final error = ZegoAIAgentActionError(
                seq,
                pending.action,
                errorCode,
                errorMessage,
              );
              onError?.call(error);
              pending.completer.completeError(error);
            }
          }
        }
        return true;
      }

      return false;
    } catch (e, stack) {
      ZegoAIAgentActionLogger.error('handleRoomChannelMessage parse error: $e\n$stack');
      return false;
    }
  }

  /// 取消所有未完成请求。
  ///
  /// 主动调用此方法时，未收到响应的请求会以 [ZegoAIAgentActionErrorCodes.canceled]
  /// 触发 onError 回调。
  void cancelAll([String message = 'agent action canceled']) {
    final pending = List.of(_pending.entries);
    _pending.clear();
    ZegoAIAgentActionLogger.warn('cancelAll size=${pending.length} message=$message');
    for (final entry in pending) {
      entry.value.timer.cancel();
      entry.value.completer.completeError(
          ZegoAIAgentActionError(entry.key, entry.value.action, ZegoAIAgentActionErrorCodes.canceled, message));
    }
  }

  Future<ZegoAIAgentActionResponse> _send(
    String action,
    GeneratedMessage params, {
    String? agentUserId,
    int? timeoutMs,
  }) {
    final targetAgentUserId = agentUserId ?? this.agentUserId;
    _requireString(targetAgentUserId, 'agentUserId');
    final seq = _nextSeq();
    final completer = Completer<ZegoAIAgentActionResponse>();
    final timer = Timer(Duration(milliseconds: timeoutMs ?? this.timeoutMs), () {
      _pending.remove(seq);
      ZegoAIAgentActionLogger.warn('timeout action=$action seq=$seq');
      completer.completeError(ZegoAIAgentActionError(seq, action, ZegoAIAgentActionErrorCodes.timeout, 'agent action timeout'));
    });
    _pending[seq] = _PendingAction(action, completer, timer);

    final envelope = AgentActionEnvelope(
      action: action,
      seq: seq,
      params: params.writeToBuffer(),
    );
    final msgContent = jsonEncode(_encodeEnvelope(envelope, params));

    _expressSeq += 1;
    final currentExpressSeq = _expressSeq;
    _expressPending[currentExpressSeq] = seq;

    final expressJson = jsonEncode({
      ZegoAIAgentActionExpressKeys.method: ZegoAIAgentActionExpressMethods.sendRoomChannelMessage,
      ZegoAIAgentActionExpressKeys.params: {
        ZegoAIAgentActionExpressKeys.roomId: roomId,
        ZegoAIAgentActionExpressKeys.msgType: ZegoAIAgentActionMsgTypes.request,
        ZegoAIAgentActionExpressKeys.msgContent: msgContent,
        ZegoAIAgentActionExpressKeys.userList: [targetAgentUserId],
        ZegoAIAgentActionExpressKeys.seq: currentExpressSeq,
      }
    });

    ZegoAIAgentActionLogger.info('send action=$action seq=$seq expressSeq=$currentExpressSeq msgContent=$msgContent');

    sender(
      ZegoAIAgentActionSendParams(
        roomId: roomId,
        msgType: ZegoAIAgentActionMsgTypes.request,
        seq: seq,
        msgContent: msgContent,
        userList: [targetAgentUserId],
      ),
      expressJson,
    ).then((result) {
      ZegoAIAgentActionLogger.debug('sender result action=$action seq=$seq errorCode=${result.errorCode}');
      if (result.errorCode != ZegoAIAgentActionErrorCodes.success && _pending.remove(seq) != null) {
        timer.cancel();
        completer.completeError(ZegoAIAgentActionError(seq, action, ZegoAIAgentActionErrorCodes.sendFailed, 'send failed'));
      }
    }).catchError((error) {
      ZegoAIAgentActionLogger.error('sender exception action=$action seq=$seq error=$error');
      if (_pending.remove(seq) != null) {
        timer.cancel();
        completer.completeError(ZegoAIAgentActionError(seq, action, ZegoAIAgentActionErrorCodes.sendFailed, 'send failed'));
      }
    });
    return completer.future;
  }

  String _nextSeq() {
    _localSeq += 1;
    return '$userId:$deviceId:$_localSeq';
  }

  static String _createDeviceId() => 'flutter_${Random().nextInt(1 << 32).toRadixString(16)}';

  static void _requireString(String value, String name) {
    if (value.trim().isEmpty) throw ArgumentError('$name is required');
  }

  static Map<String, dynamic> _encodeEnvelope(AgentActionEnvelope envelope, GeneratedMessage params) {
    return {
      ZegoAIAgentActionProtocolKeys.action: envelope.action,
      ZegoAIAgentActionProtocolKeys.seq: envelope.seq,
      ZegoAIAgentActionProtocolKeys.params: _encodeParams(params),
    };
  }

  static AgentActionResponse _decodeResponse(Map<String, dynamic> json) {
    return AgentActionResponse(
      action: (json[ZegoAIAgentActionProtocolKeys.action] ?? '') as String,
      seq: (json[ZegoAIAgentActionProtocolKeys.seq] ?? '') as String,
      code: (json[ZegoAIAgentActionProtocolKeys.code] ?? ZegoAIAgentActionErrorCodes.success) as int,
      message: (json[ZegoAIAgentActionProtocolKeys.message] ?? '') as String,
      requestId: (json[ZegoAIAgentActionProtocolKeys.requestId] ?? '') as String,
    );
  }

  static Map<String, dynamic> _encodeParams(GeneratedMessage params) {
    if (params is SendAgentInstanceTTSParams) {
      return {
        ZegoAIAgentActionProtocolKeys.text: params.text,
        ZegoAIAgentActionProtocolKeys.addHistory: params.addHistory,
        ZegoAIAgentActionProtocolKeys.priority: params.priority,
        ZegoAIAgentActionProtocolKeys.samePriorityOption: params.samePriorityOption,
        if (params.hasInterruptMode()) ZegoAIAgentActionProtocolKeys.interruptMode: params.interruptMode,
        if (params.hasEnqueueUserSpeech()) ZegoAIAgentActionProtocolKeys.enqueueUserSpeech: params.enqueueUserSpeech,
      };
    }
    if (params is SendAgentInstanceLLMParams) {
      return {
        ZegoAIAgentActionProtocolKeys.text: params.text,
        ZegoAIAgentActionProtocolKeys.systemPrompt: params.systemPrompt,
        ZegoAIAgentActionProtocolKeys.addQuestionToHistory: params.addQuestionToHistory,
        ZegoAIAgentActionProtocolKeys.addAnswerToHistory: params.addAnswerToHistory,
        ZegoAIAgentActionProtocolKeys.priority: params.priority,
        ZegoAIAgentActionProtocolKeys.samePriorityOption: params.samePriorityOption,
        if (params.hasEnqueueUserSpeech()) ZegoAIAgentActionProtocolKeys.enqueueUserSpeech: params.enqueueUserSpeech,
      };
    }
    if (params is StartListeningParams) {
      return {
        if (params.hasUserId()) ZegoAIAgentActionProtocolKeys.userId: params.userId,
      };
    }
    if (params is StopListeningParams) {
      return {
        if (params.hasUserId()) ZegoAIAgentActionProtocolKeys.userId: params.userId,
      };
    }
    if (params is InterruptAgentInstanceParams) {
      return {};
    }
    throw UnsupportedError('Unsupported protobuf params type: ${params.runtimeType}');
  }
}

class _PendingAction {
  final String action;
  final Completer<ZegoAIAgentActionResponse> completer;
  final Timer timer;

  _PendingAction(this.action, this.completer, this.timer);
}
