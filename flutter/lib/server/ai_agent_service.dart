import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

import 'package:ai_agent_quickstart_flutter/server/zego_key.dart';
import 'package:ai_agent_quickstart_flutter/audio/subtitles/protocol/message_dispatcher.dart';
import 'package:ai_agent_quickstart_flutter/digital_human/defines.dart';

import 'http_utils.dart';
import 'token_response.dart';

/// AI Agent 服务响应类
class AIAgentServiceResponse {
  final bool success;
  final int errorCode;
  final String errorMessage;
  final String? digitalHumanEncodeConfig;
  final String? agentInstanceId;

  AIAgentServiceResponse({
    required this.success,
    required this.errorCode,
    required this.errorMessage,
    this.digitalHumanEncodeConfig,
    this.agentInstanceId,
  });

  /// 成功响应
  factory AIAgentServiceResponse.success({
    String? digitalHumanEncodeConfig,
    String? agentInstanceId,
  }) {
    return AIAgentServiceResponse(
      success: true,
      errorCode: 0,
      errorMessage: '',
      digitalHumanEncodeConfig: digitalHumanEncodeConfig,
      agentInstanceId: agentInstanceId,
    );
  }

  /// 失败响应
  factory AIAgentServiceResponse.failure({
    required int errorCode,
    required String errorMessage,
  }) {
    return AIAgentServiceResponse(
      success: false,
      errorCode: errorCode,
      errorMessage: errorMessage,
    );
  }
}

/// 负责与AI服务端通信和状态管理
class ZegoAIAgentService {
  static final ZegoAIAgentService _instance = ZegoAIAgentService._internal();
  factory ZegoAIAgentService() => _instance;

  ZegoAIAgentService._internal() {
    // 随机生成本地用户相关信息
    _userId = _generateRandomIdWithPrefix('user_');
    _roomId = _generateRandomIdWithPrefix('room_');
    _userStreamId = _generateRandomIdWithPrefix('stream_user_');
  }

  /// 业务后台地址
  String get _currentBaseUrl => ZegoKey.kBaseURL;

  /// 随机生成的本地用户相关信息
  late final String _userId;
  late final String _roomId;
  late final String _userStreamId;

  /// 数字人相关配置
  final String _digitalHumanConfigId = 'web';
  ZegoDigitalHumanStreamInfo? digitalHumanStreamInfo;

  /// 后台返回的 agent 信息（动态赋值）
  String? _agentId;
  String? _agentUserId;
  String? _agentName;
  String? _agentRobotId;
  String? _agentStreamId;
  String? _agentInstanceId;

  /// 添加token缓存相关字段
  String? _cachedToken;

  /// 存储毫秒时间戳
  double? _tokenExpireTime;

  String? getAgentId() => _agentId;
  String? getAgentUserId() => _agentUserId;
  String? getAgentName() => _agentName;
  String? getAgentRobotId() => _agentRobotId;
  String? getAgentStreamId() => _agentStreamId;
  String? getAgentInstanceId() => _agentInstanceId;
  String getUserId() => _userId;
  String getRoomId() => _roomId;

  Future<void> init() async {
    /// 初始化ZegoExpressEngine
    await ZegoExpressEngine.createEngineWithProfile(
      ZegoEngineProfile(ZegoKey.appId, ZegoScenario.HighQualityChatroom),
    );

    ZegoExpressEngine.onRecvExperimentalAPI = _onRecvExperimentalAPI;
    ZegoExpressEngine.onPlayerStateUpdate = _onPlayerStateUpdate;
    ZegoExpressEngine.onRoomStreamUpdate = _onRoomStreamUpdate;
  }

  Future<void> uninit() async {
    ZegoExpressEngine.onRecvExperimentalAPI = null;
    ZegoExpressEngine.onPlayerStateUpdate = null;
    ZegoExpressEngine.onRoomStreamUpdate = null;

    /// 销毁引擎
    await ZegoExpressEngine.destroyEngine();
  }

  /// 获取Token
  Future<String> getToken() async {
    /// 检查缓存的token是否有效
    if (_cachedToken != null && _tokenExpireTime != null) {
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      if (currentTime < _tokenExpireTime!) {
        debugPrint(
            '使用缓存的token，将在 ${DateTime.fromMillisecondsSinceEpoch(_tokenExpireTime!.toInt()).toLocal()} 过期');
        return _cachedToken!;
      }
      debugPrint('缓存的token已过期，重新获取');
    }

    final url = '$_currentBaseUrl/api/zego-token?userId=$_userId';
    final response = await HttpUtil.get<ZegoTokenResponse>(
      url,
      fromJson: ZegoTokenResponse.fromJson,
    );

    if (!response.isSuccess) {
      debugPrint('获取token失败: ${response.message}');
      return '';
    }

    /// 更新token缓存和过期时间
    _cachedToken = response.data?.token;
    _tokenExpireTime = response.data?.expireTime;
    if (_tokenExpireTime != null) {
      debugPrint(
          'Token将在 ${DateTime.fromMillisecondsSinceEpoch(_tokenExpireTime!.toInt()).toLocal()} 过期');
    }

    return _cachedToken ?? '';
  }

  /// 启动与AI智能体的语音会话
  Future<AIAgentServiceResponse> startAudioCall() async {
    debugPrint('开始启动AI会话...');

    /// 通知业务后台开始通话
    debugPrint('通知业务后台开始通话...');
    final url = '$_currentBaseUrl/api/start';
    final requestData = {
      'room_id': _roomId,
      'user_id': _userId,
      'user_stream_id': _userStreamId,
    };
    final response =
        await HttpUtil.post(url, body: requestData, fromJson: (json) => json);
    if (!response.isSuccess) {
      debugPrint('通知业务后台开始通话失败: ${response.message}');
      return AIAgentServiceResponse.failure(
        errorCode: response.code,
        errorMessage: response.message,
      );
    }

    // 从响应中获取后端返回的信息
    if (response.data != null && response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      _agentId = data['agent_id'];
      _agentName = data['agent_name'];
      _agentStreamId = data['agent_stream_id'];
      _agentUserId = data['agent_user_id'];
      _agentInstanceId = data['agent_instance_id'];
      debugPrint(
          '获取到agent信息: agentId=$_agentId, agentStreamId=$_agentStreamId');
    }
    debugPrint('通知业务后台开始通话成功');

    /// 获取Token
    final token = await getToken();
    if (token.isEmpty) {
      debugPrint('获取token失败，无法继续启动会话');
      return AIAgentServiceResponse.failure(
        errorCode: -1,
        errorMessage: '获取token失败',
      );
    }
    debugPrint('成功获取token');

    try {
      debugPrint('开始配置Zego引擎...');

      /// 下面用来做应答延迟优化的，需要集成对应版本的ZegoExpressEngine sdk，请联系即构同学
      ZegoExpressEngine.setEngineConfig(
        ZegoEngineConfig(
          advancedConfig: {
            /**该配置是用来做音量闪避的**/
            'set_audio_volume_ducking_mode': '1',
            /**该配置是用来做播放音量自适用**/
            'enable_rnd_volume_adaptive': 'true'
          },
        ),
      );
      debugPrint('引擎配置完成');

      /// 启用3A
      debugPrint('开始配置3A...');

      /// 启用AGC（自动增益控制）
      ZegoExpressEngine.instance.enableAGC(true);
      debugPrint('AGC已启用');

      /// 启用AEC（回声消除）
      ZegoExpressEngine.instance.enableAEC(true);
      if (!kIsWeb) {
        /// web尚未实现
        ZegoExpressEngine.instance.setAECMode(ZegoAECMode.AIAggressive2);

        /// 这个设置只影响AEC（回声消除），我们这里设置为Mode General，是会走我们自研的回声消除，这比较可控，
        /// 如果其他选项，可能会走系统的回声消除，这在iphone手机上效果可能会更好，但如果在一些android机上效果可能不好
        ZegoExpressEngine.instance.setAudioDeviceMode(
          ZegoAudioDeviceMode.General,
        );
      }
      debugPrint('AEC已启用');

      /// 启用ANS（噪声抑制）
      ZegoExpressEngine.instance.enableANS(true);
      ZegoExpressEngine.instance.setANSMode(ZegoANSMode.Medium);
      debugPrint('ANS已启用');

      /// 登录房间
      debugPrint('开始登录房间...');
      final user = ZegoUser(_userId, _userId);
      final roomConfig = ZegoRoomConfig.defaultConfig()
        ..isUserStatusNotify = true
        ..token = token;
      final loginResult = await ZegoExpressEngine.instance.loginRoom(
        _roomId,
        user,
        config: roomConfig,
      );
      if (0 != loginResult.errorCode && 1002001 != loginResult.errorCode) {
        debugPrint('登录房间失败，错误码: ${loginResult.errorCode}');
        return AIAgentServiceResponse.failure(
          errorCode: loginResult.errorCode,
          errorMessage: '进入语音房间失败:${loginResult.errorCode}',
        );
      }
      debugPrint('房间登录成功');

      /// 下面用来做应答延迟优化的，需要集成对应版本的ZegoExpressEngine sdk，请联系即构同学
      debugPrint('配置发布延迟模式...');
      await ZegoExpressEngine.instance.callExperimentalAPI(
        '{"method":"liveroom.audio.set_publish_latency_mode","params":{"mode":1,"channel":0}}',
      );

      /// 开始推流（打开麦克风）
      debugPrint('开始推流$_userStreamId...');
      await ZegoExpressEngine.instance.muteMicrophone(false);
      await ZegoExpressEngine.instance.startPublishingStream(_userStreamId);
      debugPrint('推流启动成功');

      /// 拉流（播放AI语音）
      if (_agentStreamId != null) {
      } else {
        debugPrint('agentStreamId为空，跳过拉流');
      }

      debugPrint('AI会话启动完成');
      return AIAgentServiceResponse.success(agentInstanceId: _agentInstanceId);
    } catch (e, stackTrace) {
      debugPrint('启动会话失败: $e');
      debugPrint('错误堆栈: $stackTrace');
      return AIAgentServiceResponse.failure(
        errorCode: -1,
        errorMessage: '启动会话失败: $e',
      );
    }
  }

  /// 停止与AI智能体的语音会话
  Future<AIAgentServiceResponse> stopAudioCall() async {
    debugPrint('开始停止AI会话...');

    /// 通知业务后台停止通话
    debugPrint('通知业务后台停止通话...');
    final url = '$_currentBaseUrl/api/stop';
    final requestData = <String, dynamic>{};
    if (_agentInstanceId != null) {
      requestData['agent_instance_id'] = _agentInstanceId;
    }
    final response =
        await HttpUtil.post(url, body: requestData, fromJson: (json) => json);
    if (!response.isSuccess) {
      debugPrint('通知业务后台停止通话失败: ${response.message}');
    } else {
      debugPrint('通知业务后台停止通话成功');
    }

    try {
      final engine = ZegoExpressEngine.instance;

      /// 停止拉流
      if (_agentStreamId != null) {
        debugPrint('停止拉流...');
        await engine.stopPlayingStream(_agentStreamId!);
        debugPrint('拉流已停止');
      }

      /// 停止推流
      debugPrint('停止推流...');
      await engine.stopPublishingStream();
      debugPrint('推流已停止');

      /// 登出房间
      debugPrint('登出房间...');
      await engine.logoutRoom(_roomId);
      debugPrint('房间已登出');

      // 清空后台返回的agent instance数据
      _agentId = null;
      _agentName = null;
      _agentStreamId = null;
      _agentInstanceId = null;

      debugPrint('AI会话停止完成');
      return AIAgentServiceResponse.success();
    } catch (e, stackTrace) {
      debugPrint('停止会话失败: $e');
      debugPrint('错误堆栈: $stackTrace');
      return AIAgentServiceResponse.failure(
        errorCode: -1,
        errorMessage: '停止会话失败: $e',
      );
    }
  }

  /// 启动数字人会话
  Future<AIAgentServiceResponse> startDigitalHuman(
    ZegoDigitalHumanStreamInfo streamInfo,
  ) async {
    debugPrint('开始启动数字人会话...');

    /// 通知业务后台开始数字人通话
    debugPrint('通知业务后台开始数字人通话...');
    final url = '$_currentBaseUrl/api/start-digital-human';
    final requestData = {
      'room_id': _roomId,
      'user_id': _userId,
      'user_stream_id': _userStreamId,
      'digital_human_id': ZegoKey.kDigitalHumanId,
      'config_id': _digitalHumanConfigId,
    };
    final response =
        await HttpUtil.post(url, body: requestData, fromJson: (json) => json);
    if (!response.isSuccess) {
      debugPrint('通知业务后台开始数字人通话失败: ${response.message}');
      return AIAgentServiceResponse.failure(
        errorCode: response.code,
        errorMessage: response.message,
      );
    }

    // 从响应中获取后端返回的信息
    String? digitalHumanConfig;
    if (response.data != null && response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      _agentId = data['agent_id'];
      _agentName = data['agent_name'];
      _agentStreamId = data['agent_stream_id'];
      _agentUserId = data['agent_user_id'];
      _agentInstanceId = data['agent_instance_id'];
      digitalHumanConfig = data['digital_human_config'];
      debugPrint(
          '获取到数字人agent信息: agentId=$_agentId, agentStreamId=$_agentStreamId');
    }
    debugPrint('通知业务后台开始数字人通话成功');

    /// 获取Token
    final token = await getToken();
    if (token.isEmpty) {
      debugPrint('获取token失败，无法继续启动数字人会话');
      return AIAgentServiceResponse.failure(
        errorCode: -1,
        errorMessage: '获取token失败',
      );
    }
    debugPrint('成功获取token');

    /// 更新数字人拉流信息
    digitalHumanStreamInfo = streamInfo;

    try {
      debugPrint('开始配置Zego引擎...');

      /// 登录房间
      debugPrint('开始登录房间...');
      final user = ZegoUser(_userId, _userId);
      final roomConfig = ZegoRoomConfig.defaultConfig()
        ..isUserStatusNotify = true
        ..token = token;
      final loginResult = await ZegoExpressEngine.instance.loginRoom(
        _roomId,
        user,
        config: roomConfig,
      );
      if (0 != loginResult.errorCode && 1002001 != loginResult.errorCode) {
        debugPrint('登录房间失败，错误码: ${loginResult.errorCode}');
        return AIAgentServiceResponse.failure(
          errorCode: loginResult.errorCode,
          errorMessage: '进入数字人房间失败:${loginResult.errorCode}',
        );
      }
      debugPrint('房间登录成功');

      /// 下面用来做应答延迟优化的，需要集成对应版本的ZegoExpressEngine sdk，请联系即构同学
      debugPrint('配置发布延迟模式...');
      await ZegoExpressEngine.instance.callExperimentalAPI(
        '{"method":"liveroom.audio.set_publish_latency_mode","params":{"mode":1,"channel":0}}',
      );

      /// 开始推流（打开麦克风）
      debugPrint('开始推流$_userStreamId...');
      await ZegoExpressEngine.instance.muteMicrophone(false);
      await ZegoExpressEngine.instance.startPublishingStream(_userStreamId);
      debugPrint('推流启动成功');

      debugPrint('数字人会话启动完成');
      return AIAgentServiceResponse.success(
        digitalHumanEncodeConfig: digitalHumanConfig ?? '',
        agentInstanceId: _agentInstanceId,
      );
    } catch (e, stackTrace) {
      debugPrint('启动数字人会话失败: $e');
      debugPrint('错误堆栈: $stackTrace');
      return AIAgentServiceResponse.failure(
        errorCode: -1,
        errorMessage: '启动数字人会话失败: $e',
      );
    }
  }

  /// 启动数字人播报（单向 TTS，不需要本地推流）
  ///
  /// 与 startDigitalHuman 的差异：
  /// - 业务后台接口使用 /api/start-live-digital-human，由服务端自动生成 agent_user_id / agent_stream_id；
  /// - 本地不推送麦克风流，只拉智能体音视频流；
  /// - 不需要麦克风权限。
  Future<AIAgentServiceResponse> startLiveDigitalHuman(
    ZegoDigitalHumanStreamInfo streamInfo,
  ) async {
    debugPrint('开始启动数字人播报...');

    /// 通知业务后台开始数字人播报（不传 user_id / user_stream_id，服务端自动生成）
    debugPrint('通知业务后台开始数字人播报...');
    final url = '$_currentBaseUrl/api/start-live-digital-human';
    final requestData = <String, dynamic>{
      'room_id': _roomId,
      'digital_human_id': ZegoKey.kDigitalHumanId,
      'config_id': _digitalHumanConfigId,
    };
    final response =
        await HttpUtil.post(url, body: requestData, fromJson: (json) => json);
    if (!response.isSuccess) {
      debugPrint('通知业务后台开始数字人播报失败: ${response.message}');
      return AIAgentServiceResponse.failure(
        errorCode: response.code,
        errorMessage: response.message,
      );
    }

    // 从响应中获取后端返回的信息
    String? digitalHumanConfig;
    if (response.data != null && response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      _agentId = data['agent_id'];
      _agentName = data['agent_name'];
      _agentStreamId = data['agent_stream_id'];
      _agentUserId = data['agent_user_id'];
      _agentInstanceId = data['agent_instance_id'];
      digitalHumanConfig = data['digital_human_config'];
      debugPrint(
          '获取到播报数字人agent信息: agentId=$_agentId, agentStreamId=$_agentStreamId, agentInstanceId=$_agentInstanceId');
    }
    debugPrint('通知业务后台开始数字人播报成功');

    /// 获取Token
    final token = await getToken();
    if (token.isEmpty) {
      debugPrint('获取token失败，无法继续启动数字人播报');
      return AIAgentServiceResponse.failure(
        errorCode: -1,
        errorMessage: '获取token失败',
      );
    }
    debugPrint('成功获取token');

    /// 更新数字人拉流信息
    digitalHumanStreamInfo = streamInfo;

    try {
      /// 登录房间（播报场景下不推本地音频流）
      debugPrint('开始登录房间...');
      final user = ZegoUser(_userId, _userId);
      final roomConfig = ZegoRoomConfig.defaultConfig()
        ..isUserStatusNotify = true
        ..token = token;
      final loginResult = await ZegoExpressEngine.instance.loginRoom(
        _roomId,
        user,
        config: roomConfig,
      );
      if (0 != loginResult.errorCode && 1002001 != loginResult.errorCode) {
        debugPrint('登录房间失败，错误码: ${loginResult.errorCode}');
        return AIAgentServiceResponse.failure(
          errorCode: loginResult.errorCode,
          errorMessage: '进入播报数字人房间失败:${loginResult.errorCode}',
        );
      }
      debugPrint('房间登录成功');

      /// 注意：播报数字人场景不调用 startPublishingStream，避免占用麦克风
      debugPrint('数字人播报启动完成（无需本地推流）');
      return AIAgentServiceResponse.success(
        digitalHumanEncodeConfig: digitalHumanConfig ?? '',
        agentInstanceId: _agentInstanceId,
      );
    } catch (e, stackTrace) {
      debugPrint('启动数字人播报失败: $e');
      debugPrint('错误堆栈: $stackTrace');
      return AIAgentServiceResponse.failure(
        errorCode: -1,
        errorMessage: '启动数字人播报失败: $e',
      );
    }
  }

  /// 停止数字人会话
  Future<AIAgentServiceResponse> stopDigitalHuman() async {
    debugPrint('开始停止数字人会话...');

    /// 清除视频canvas
    ZegoExpressEngine.instance.destroyCanvasView(
      digitalHumanStreamInfo?.viewIDNotifier.value ?? -1,
    );
    digitalHumanStreamInfo = null;

    /// 通知业务后台停止数字人通话
    debugPrint('通知业务后台停止数字人通话...');
    final url = '$_currentBaseUrl/api/stop';
    final requestData = <String, dynamic>{};
    if (_agentInstanceId != null) {
      requestData['agent_instance_id'] = _agentInstanceId;
    }
    final response =
        await HttpUtil.post(url, body: requestData, fromJson: (json) => json);
    if (!response.isSuccess) {
      debugPrint('通知业务后台停止数字人通话失败: ${response.message}');
    } else {
      debugPrint('通知业务后台停止数字人通话成功');
    }

    try {
      final engine = ZegoExpressEngine.instance;

      /// 停止推流
      debugPrint('停止推流...');
      await engine.stopPublishingStream();
      debugPrint('推流已停止');

      /// 登出房间
      debugPrint('登出房间...');
      await engine.logoutRoom(_roomId);
      debugPrint('房间已登出');

      // 清空后台返回的agent instance数据
      _agentId = null;
      _agentName = null;
      _agentStreamId = null;
      _agentInstanceId = null;

      debugPrint('数字人会话停止完成');
      if (response.isSuccess) {
        return AIAgentServiceResponse.success();
      } else {
        return AIAgentServiceResponse.failure(
          errorCode: response.code,
          errorMessage: response.message,
        );
      }
    } catch (e, stackTrace) {
      debugPrint('停止数字人会话失败: $e');
      debugPrint('错误堆栈: $stackTrace');
      return AIAgentServiceResponse.failure(
        errorCode: -1,
        errorMessage: '停止数字人会话失败: $e',
      );
    }
  }

  /// 停止数字人播报（与 stopDigitalHuman 共用停止逻辑）
  Future<AIAgentServiceResponse> stopLiveDigitalHuman() {
    debugPrint('开始停止数字人播报...');
    return stopDigitalHuman();
  }

  /// 向数字人播报实例发送自定义 TTS 内容
  Future<AIAgentServiceResponse> sendAgentInstanceTTS(String text) async {
    debugPrint('开始发送TTS: text=$text');

    /// 本地校验：播报文本不可为空
    if (text.isEmpty) {
      return AIAgentServiceResponse.failure(
        errorCode: 400,
        errorMessage: '播报文本不能为空',
      );
    }

    /// 本地校验：必须先有可用的播报数字人实例
    if (_agentInstanceId == null || _agentInstanceId!.isEmpty) {
      return AIAgentServiceResponse.failure(
        errorCode: 400,
        errorMessage: '当前没有可用的播报数字人实例',
      );
    }

    final url = '$_currentBaseUrl/api/send-agent-instance-tts';
    final requestData = <String, dynamic>{
      'agent_instance_id': _agentInstanceId,
      'text': text,
    };
    final response =
        await HttpUtil.post(url, body: requestData, fromJson: (json) => json);
    if (!response.isSuccess) {
      debugPrint('发送TTS失败: ${response.message}');
      return AIAgentServiceResponse.failure(
        errorCode: response.code,
        errorMessage: response.message,
      );
    }
    debugPrint('发送TTS成功');
    return AIAgentServiceResponse.success();
  }

  Future<void> _startPlayingStream(String streamId) async {
    debugPrint('开始拉流$streamId...');

    if (digitalHumanStreamInfo != null) {
      /// 视频流
      await ZegoExpressEngine.instance.createCanvasView((viewID) {
        debugPrint('数字人流widget成功渲染');

        digitalHumanStreamInfo?.viewIDNotifier.value = viewID;

        ZegoCanvas canvas = ZegoCanvas.view(viewID);
        ZegoExpressEngine.instance.startPlayingStream(streamId, canvas: canvas);
      }).then((widget) {
        debugPrint('数字人流widget成功构建');
        digitalHumanStreamInfo?.viewNotifier.value = widget;
      });
    } else {
      await ZegoExpressEngine.instance.startPlayingStream(streamId);
    }

    await ZegoExpressEngine.instance.callExperimentalAPI(
      '{"method":"liveroom.audio.set_play_latency_mode","params":{"mode":1,"stream_id":"$streamId"}}',
    );
    debugPrint('拉流启动成功');
  }

  void _onRecvExperimentalAPI(String content) {
    debugPrint('onRecvExperimentalAPI:$content');
    ZegoSubtitlesMessageDispatcher.handleExpressExperimentalAPIContent(content);
  }

  void _onPlayerStateUpdate(
    String streamID,
    ZegoPlayerState state,
    int errorCode,
    Map<String, dynamic> extendedData,
  ) {
    debugPrint('onPlayerStateUpdate, '
        'stream id:$streamID, '
        'state:$state, '
        'errorCode:$errorCode, '
        'extendedData:$extendedData');
  }

  void _onRoomStreamUpdate(
    String roomID,
    ZegoUpdateType updateType,
    List<ZegoStream> streamList,
    Map<String, dynamic> extendedData,
  ) {
    debugPrint('onRoomStreamUpdate, roomID:$roomID, update type:$updateType'
        ", stream list:${streamList.map((e) => 'ZegoStreamExtension{'
            'user:(${e.user.userID},${e.user.userName}), '
            'streamID:${e.streamID}, '
            'extraInfo:${e.extraInfo}, '
            '}')},"
        ' extended data:$extendedData');

    if (updateType == ZegoUpdateType.Add) {
      streamList.forEach((stream) async {
        if (_agentStreamId == stream.streamID) {
          _startPlayingStream(stream.streamID);
        }
      });
    } else if (updateType == ZegoUpdateType.Delete) {
      streamList.forEach((stream) async {
        if (_agentStreamId == stream.streamID) {
          ZegoExpressEngine.instance.stopPlayingStream(stream.streamID);
        }
      });
    }
  }

  /// 生成随机ID
  String _generateRandomIdWithPrefix(String prefix) {
    final random = Random();
    final randomString = random.nextInt(100000000).toString().padLeft(8, '0');
    return '$prefix$randomString';
  }
}
