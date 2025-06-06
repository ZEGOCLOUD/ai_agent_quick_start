import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

import 'package:ai_agent_quickstart_flutter/server/zego_key.dart';
import 'package:ai_agent_quickstart_flutter/audio/subtitles/protocol/message_dispatcher.dart';

import 'http_utils.dart';
import 'token_response.dart';

/// 负责与AI服务端通信和状态管理
class ZegoAIAgentService {
  static final ZegoAIAgentService _instance = ZegoAIAgentService._internal();
  factory ZegoAIAgentService() => _instance;

  ZegoAIAgentService._internal();

  /// 这些属性可根据实际业务动态赋值
  final String _currentBaseUrl = 'https://cheery-squirrel-1ab760.netlify.app';
  final String _userId = 'user_id_1';
  final String _roomId = 'room_id_1';
  final String _userStreamId = 'user_stream_id_1';
  final String _agentId = 'ai_agent_example_1';
  final String _agentUserId = 'agent_user_id_1';
  final String _agentName = '李浩然';
  final String _agentRobotId = '@RBT#19574_xiaozhi_019670818747';
  final String _agentStreamId = 'agent_stream_id_1';

  /// 添加token缓存相关字段
  String? _cachedToken;

  /// 存储毫秒时间戳
  double? _tokenExpireTime;

  /// TODO: 待删除，用来修复web音频失败问题，使用视频拉流方式
  ValueNotifier<Widget?> webVideoWidgetNotifier = ValueNotifier<Widget?>(null);

  String getAgentUserId() => _agentUserId;
  String getAgentName() => _agentName;
  String getAgentRobotId() => _agentRobotId;
  String getUserId() => _userId;
  String getRoomId() => _roomId;

  Future<void> init() async {
    /// 初始化ZegoExpressEngine
    await ZegoExpressEngine.createEngineWithProfile(
      ZegoEngineProfile(ZegoKey.appId, ZegoScenario.HighQualityChatroom),
    );

    if (kIsWeb) {
      /// express web有bug，需要设置这个，否则会请求摄像头权限
      ZegoExpressEngine.instance
          .setRoomScenario(ZegoScenario.HighQualityChatroom);
    }

    ZegoExpressEngine.onRecvExperimentalAPI = _onRecvExperimentalAPI;
    ZegoExpressEngine.onPlayerStateUpdate = _onPlayerStateUpdate;
  }

  Future<void> uninit() async {
    webVideoWidgetNotifier.value = null;

    ZegoExpressEngine.onRecvExperimentalAPI = null;

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

  /// 启动与AI智能体的会话
  Future<bool> startCall() async {
    debugPrint('开始启动AI会话...');

    /// 通知业务后台开始通话
    debugPrint('通知业务后台开始通话...');
    final url = '$_currentBaseUrl/api/start';
    final response = await HttpUtil.post(url, fromJson: (json) => json);
    if (!response.isSuccess) {
      debugPrint('通知业务后台开始通话失败: ${response.message}');
      return false;
    }
    debugPrint('通知业务后台开始通话成功');

    /// 获取Token
    final token = await getToken();
    if (token.isEmpty) {
      debugPrint('获取token失败，无法继续启动会话');
      return false;
    }
    debugPrint('成功获取token');

    try {
      debugPrint('开始配置Zego引擎...');

      /// 下面用来做应答延迟优化的，需要集成对应版本的ZegoExpressEngine sdk，请联系即构同学
      ZegoExpressEngine.setEngineConfig(
        ZegoEngineConfig(
          advancedConfig: {'enforce_audio_loopback_in_sync': 'true'},
        ),
      );
      debugPrint('引擎配置完成');

      /// 这个设置只影响AEC（回声消除），我们这里设置为ModeGeneral，是会走我们自研的回声消除，这比较可控，
      /// 如果其他选项，可能会走系统的回声消除，这在iphone手机上效果可能会更好，但如果在一些android机上效果可能不好
      ZegoExpressEngine.instance.setAudioDeviceMode(
        ZegoAudioDeviceMode.General,
      );
      debugPrint('音频设备模式设置完成');

      /// 启用3A
      debugPrint('开始配置3A...');

      /// 启用AGC（自动增益控制）
      ZegoExpressEngine.instance.enableAGC(true);
      debugPrint('AGC已启用');

      /// 启用AEC（回声消除）
      ZegoExpressEngine.instance.enableAEC(true);
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
        return false;
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
      debugPrint('开始拉流$_agentStreamId...');
      if (kIsWeb) {
        await ZegoExpressEngine.instance.createCanvasView((viewID) {
          ZegoCanvas canvas = ZegoCanvas.view(viewID);
          ZegoExpressEngine.instance
              .startPlayingStream(_agentStreamId, canvas: canvas);
        }).then((Widget? widget) {
          webVideoWidgetNotifier.value = widget;
        });
      } else {
        await ZegoExpressEngine.instance.startPlayingStream(_agentStreamId);
      }
      await ZegoExpressEngine.instance.callExperimentalAPI(
        '{"method":"liveroom.audio.set_play_latency_mode","params":{"mode":1,"stream_id":"$_agentStreamId"}}',
      );
      debugPrint('拉流启动成功');

      debugPrint('AI会话启动完成');
      return true;
    } catch (e, stackTrace) {
      debugPrint('启动会话失败: $e');
      debugPrint('错误堆栈: $stackTrace');
      return false;
    }
  }

  /// 停止与AI智能体的会话
  Future<bool> stopCall() async {
    debugPrint('开始停止AI会话...');

    /// 通知业务后台停止通话
    debugPrint('通知业务后台停止通话...');
    final url = '$_currentBaseUrl/api/stop';
    final response = await HttpUtil.post(url, fromJson: (json) => json);
    if (!response.isSuccess) {
      debugPrint('通知业务后台停止通话失败: ${response.message}');
    } else {
      debugPrint('通知业务后台停止通话成功');
    }

    try {
      final engine = ZegoExpressEngine.instance;

      /// 停止拉流
      debugPrint('停止拉流...');
      await engine.stopPlayingStream(_agentStreamId);
      debugPrint('拉流已停止');

      /// 停止推流
      debugPrint('停止推流...');
      await engine.stopPublishingStream();
      debugPrint('推流已停止');

      /// 登出房间
      debugPrint('登出房间...');
      await engine.logoutRoom(_roomId);
      debugPrint('房间已登出');

      debugPrint('AI会话停止完成');
      return true;
    } catch (e, stackTrace) {
      debugPrint('停止会话失败: $e');
      debugPrint('错误堆栈: $stackTrace');
      return false;
    }
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
}
