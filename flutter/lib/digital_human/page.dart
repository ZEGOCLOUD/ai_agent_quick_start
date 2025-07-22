import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

import '../local_strings.dart';
import '../server/ai_agent_service.dart';
import '../server/zego_key.dart';
import 'defines.dart';

/// 数字人智能体对话页面
///
/// 该页面负责呈现和管理与数字人AI智能体的交互界面，包括视频显示和语音交互。
/// 它处理视频渲染、音频权限请求、建立与ZEGO AI服务的连接、管理对话生命周期，
/// 并提供友好的用户界面以展示数字人AI智能体的视觉和语音回复。
class ZegoAIAgentDigitalHumanPage extends StatefulWidget {
  const ZegoAIAgentDigitalHumanPage({super.key});

  @override
  State<ZegoAIAgentDigitalHumanPage> createState() =>
      _ZegoAIAgentDigitalHumanPageState();
}

class _ZegoAIAgentDigitalHumanPageState
    extends State<ZegoAIAgentDigitalHumanPage> {
  // 服务实例
  late ZegoAIAgentService _aiAgentService;

  // UI 状态 - 使用 ValueNotifier
  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier(false);
  final ValueNotifier<String?> _errorMessageNotifier = ValueNotifier(null);

  // 视频相关
  ZegoDigitalHumanStreamInfo streamInfo = ZegoDigitalHumanStreamInfo();

  // 数字人配置
  final ValueNotifier<String?> _digitalHumanEncodeConfigNotifier =
      ValueNotifier(null);

  @override
  void initState() {
    super.initState();

    _aiAgentService = ZegoAIAgentService();
    _aiAgentService.init();

    _startDigitalHumanChat();
  }

  @override
  void dispose() {
    _stopDigitalHumanChat();

    // 释放 ValueNotifier 资源
    _isLoadingNotifier.dispose();
    _errorMessageNotifier.dispose();
    _digitalHumanEncodeConfigNotifier.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), // 返回箭头图标
          tooltip: '返回',
          onPressed: () {
            Navigator.of(context).pop(); // 返回上一个页面
          },
        ),
        title: const Text(LocalStrings.digitalHumanPageTitle),
        backgroundColor: const Color(0xFFD9D9D9),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                return ValueListenableBuilder<Widget?>(
                  valueListenable: streamInfo.viewNotifier,
                  builder: (context, streamView, child) {
                    return SizedBox(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      child: streamView ?? staticImage(),
                    );
                  },
                );
              },
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

  /// 设置静态图片
  Widget staticImage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFF5F5F5), // 浅灰色背景
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 如果有网络图片URL，可以在这里加载
          if (ZegoKey.kDigitalHumanImageURL.isNotEmpty)
            Image.network(
              ZegoKey.kDigitalHumanImageURL,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildPlaceholderWidget();
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return _buildPlaceholderWidget();
              },
            )
          else
            _buildPlaceholderWidget(),
        ],
      ),
    );
  }

  /// 构建占位图标
  Widget _buildPlaceholderWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.person,
          size: 80,
          color: Colors.grey[600],
        ),
        const SizedBox(height: 20),
        Text(
          '数字人加载中...',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// 开始数字人聊天
  Future<void> _startDigitalHumanChat() async {
    /// 检查权限
    final microphoneStatus = await Permission.microphone.request();
    if (!microphoneStatus.isGranted) {
      _showErrorMessage('需要麦克风权限才能进行语音交互');
      return;
    }

    _isLoadingNotifier.value = true;
    _errorMessageNotifier.value = null;

    try {
      final response = await _aiAgentService.startDigitalHuman(streamInfo);

      if (response.success) {
        _digitalHumanEncodeConfigNotifier.value =
            response.digitalHumanEncodeConfig;

        // 数字人启动成功，这里可以添加视频渲染逻辑
        debugPrint('数字人配置: ${_digitalHumanEncodeConfigNotifier.value}');

        debugPrint('数字人聊天启动成功');
      } else {
        // 检查是否是并发数超出限制的错误（410001025）
        if (response.errorCode == 410001025) {
          _showErrorMessage('数字人服务繁忙，请稍后再试');
          // 这里可以考虑转为音频聊天模式
        } else {
          _showErrorMessage('启动数字人聊天失败: ${response.errorMessage}');
        }
      }
    } catch (e) {
      _showErrorMessage('启动数字人聊天失败: $e');
    } finally {
      _isLoadingNotifier.value = false;
    }
  }

  /// 停止数字人聊天
  Future<void> _stopDigitalHumanChat() async {
    try {
      final response = await _aiAgentService.stopDigitalHuman();
      if (!response.success) {
        debugPrint('停止数字人聊天失败: ${response.errorMessage}');
      }
    } catch (e) {
      debugPrint('停止数字人聊天异常: $e');
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
