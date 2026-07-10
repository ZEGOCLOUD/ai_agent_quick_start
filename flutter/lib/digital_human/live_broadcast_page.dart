import 'package:flutter/material.dart';

import '../local_strings.dart';
import '../server/ai_agent_service.dart';
import '../server/zego_key.dart';
import 'defines.dart';

/// 数字人播报页面（单向 TTS 推送）
///
/// 与数字人对话页面的差异：
/// - 不需要麦克风权限；
/// - 本地不推送麦克风流，只拉智能体音视频流；
/// - 通过 /api/send-agent-instance-tts 主动下发文本给数字人朗读。
class ZegoAIAgentDigitalHumanLiveBroadcastPage extends StatefulWidget {
  const ZegoAIAgentDigitalHumanLiveBroadcastPage({super.key});

  @override
  State<ZegoAIAgentDigitalHumanLiveBroadcastPage> createState() =>
      _ZegoAIAgentDigitalHumanLiveBroadcastPageState();
}

class _ZegoAIAgentDigitalHumanLiveBroadcastPageState
    extends State<ZegoAIAgentDigitalHumanLiveBroadcastPage> {
  // 服务实例
  late ZegoAIAgentService _aiAgentService;

  // UI 状态
  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier(false);
  final ValueNotifier<bool> _isSendingTtsNotifier = ValueNotifier(false);
  final ValueNotifier<String?> _errorMessageNotifier = ValueNotifier(null);
  final ValueNotifier<String?> _agentInstanceIdNotifier = ValueNotifier(null);

  // 视频相关（复用数字人对话页面同款 streamInfo）
  final ZegoDigitalHumanStreamInfo _streamInfo = ZegoDigitalHumanStreamInfo();

  // TTS 文本输入控制器
  final TextEditingController _ttsTextController = TextEditingController(
    text: '你好，我是一个可以播报任意文字的数字人。',
  );

  @override
  void initState() {
    super.initState();

    _aiAgentService = ZegoAIAgentService();
    _aiAgentService.init();

    _startLiveBroadcast();
  }

  @override
  void dispose() {
    _stopLiveBroadcast();

    _isLoadingNotifier.dispose();
    _isSendingTtsNotifier.dispose();
    _errorMessageNotifier.dispose();
    _agentInstanceIdNotifier.dispose();
    _ttsTextController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: '返回',
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(LocalStrings.digitalHumanLiveBroadcastPageTitle),
        backgroundColor: const Color(0xFFD9D9D9),
      ),
      body: SafeArea(
        child: Stack(
          // StackFit.expand 让非 Positioned 子项铺满 Stack 父布局，
          // 同时给它们传的是有限约束（来自父 SafeArea/Scaffold 的真实高度），
          // 而不是 tight(infinity)——避免 ZEGO texture widget 拿到 Infinity 崩溃。
          fit: StackFit.expand,
          children: [
            // 视频流 / 占位图：作为 Stack 的非 Positioned 子项，铺满整个 body
            ValueListenableBuilder<Widget?>(
              valueListenable: _streamInfo.viewNotifier,
              builder: (context, streamView, child) {
                return streamView ?? _buildPlaceholder();
              },
            ),

            // agent_instance_id 显示（浮在右上角）
            Positioned(
              top: 8,
              right: 8,
              child: ValueListenableBuilder<String?>(
                valueListenable: _agentInstanceIdNotifier,
                builder: (context, instanceId, child) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'instance: ${instanceId ?? '-'}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
              ),
            ),

            // 底部 TTS 控制条（覆盖在视频之上）
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBroadcastControlBar(),
            ),

            // 加载指示器
            ValueListenableBuilder<bool>(
              valueListenable: _isLoadingNotifier,
              builder: (context, isLoading, child) {
                if (!isLoading) return const SizedBox.shrink();
                return Positioned.fill(
                  child: Container(
                    color: Colors.black54,
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 占位图：视频流还没拉上来时显示静态头像
  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFF5F5F5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (ZegoKey.kDigitalHumanImageURL.isNotEmpty)
            Image.network(
              ZegoKey.kDigitalHumanImageURL,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _buildPlaceholderIcon(),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return _buildPlaceholderIcon();
              },
            )
          else
            _buildPlaceholderIcon(),
        ],
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.person, size: 80, color: Colors.grey[600]),
        const SizedBox(height: 20),
        Text(
          '数字人播报加载中...',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// 底部 TTS 控制条：仅文本输入框 + 发送按钮
  /// agent_instance_id 已浮在右上角，这里不再重复显示
  Widget _buildBroadcastControlBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFEFEFEF),
        border: Border(top: BorderSide(color: Color(0xFFD0D0D0), width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 文本输入框
            TextField(
              controller: _ttsTextController,
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
                hintText: '输入需要播报的文本',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              maxLines: 2,
              minLines: 1,
            ),
            const SizedBox(height: 8),
            // 发送按钮
            SizedBox(
              width: double.infinity,
              child: ValueListenableBuilder<bool>(
                valueListenable: _isSendingTtsNotifier,
                builder: (context, isSending, child) {
                  return ElevatedButton(
                    onPressed: isSending ? null : _sendTtsButtonTapped,
                    child: isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('播报 TTS'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 启动数字人播报
  Future<void> _startLiveBroadcast() async {
    // 播报数字人不需要本地推流，因此跳过麦克风权限请求
    _isLoadingNotifier.value = true;
    _errorMessageNotifier.value = null;

    try {
      final response = await _aiAgentService.startLiveDigitalHuman(_streamInfo);

      if (response.success) {
        _agentInstanceIdNotifier.value = response.agentInstanceId;
        debugPrint('数字人播报启动成功, agentInstanceId=${response.agentInstanceId}');
      } else {
        if (response.errorCode == 410001025) {
          _showErrorMessage('数字人服务繁忙，请稍后再试');
        } else {
          _showErrorMessage('启动数字人播报失败: ${response.errorMessage}');
        }
      }
    } catch (e) {
      _showErrorMessage('启动数字人播报失败: $e');
    } finally {
      _isLoadingNotifier.value = false;
    }
  }

  /// 停止数字人播报
  Future<void> _stopLiveBroadcast() async {
    try {
      final response = await _aiAgentService.stopLiveDigitalHuman();
      if (!response.success) {
        debugPrint('停止数字人播报失败: ${response.errorMessage}');
      }
    } catch (e) {
      debugPrint('停止数字人播报异常: $e');
    }
  }

  /// 发送 TTS 按钮点击
  Future<void> _sendTtsButtonTapped() async {
    final text = _ttsTextController.text.trim();
    if (text.isEmpty) {
      _showErrorMessage('播报文本不能为空');
      return;
    }

    _isSendingTtsNotifier.value = true;
    try {
      final response = await _aiAgentService.sendAgentInstanceTTS(text);
      if (!response.success) {
        _showErrorMessage('发送 TTS 失败: ${response.errorMessage}');
      } else {
        debugPrint('发送 TTS 成功');
      }
    } catch (e) {
      _showErrorMessage('发送 TTS 异常: $e');
    } finally {
      _isSendingTtsNotifier.value = false;
    }
  }

  /// 显示错误信息
  void _showErrorMessage(String message) {
    _errorMessageNotifier.value = message;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
