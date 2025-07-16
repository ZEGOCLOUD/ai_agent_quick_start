import 'package:flutter/material.dart';

import 'audio/page.dart';
import 'digital_human/page.dart';

/// AI Agent 首页
///
/// 该页面提供了AI功能的入口，用户可以选择体验语音通话或数字人对话功能。
class ZegoAIAgentHomePage extends StatefulWidget {
  const ZegoAIAgentHomePage({super.key});

  @override
  State<ZegoAIAgentHomePage> createState() => _ZegoAIAgentHomePageState();
}

class _ZegoAIAgentHomePageState extends State<ZegoAIAgentHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 80),

              // 主标题
              const Text(
                'AI Agent Quick Start',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // 副标题
              Text(
                '选择您想要体验的AI功能',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 100),

              // 语音通话按钮
              _buildFeatureButton(
                title: 'Start Audio Call',
                subtitle: '与AI进行语音对话',
                color: const Color(0xFF3399FF), // 蓝色
                icon: Icons.mic,
                onTap: () => _navigateToAudioCall(),
              ),

              const SizedBox(height: 30),

              // 数字人通话按钮
              _buildFeatureButton(
                title: 'Start Digital Human Call',
                subtitle: '与数字人进行视频对话',
                color: const Color(0xFFCC4DFF), // 紫色
                icon: Icons.person,
                onTap: () => _navigateToDigitalHuman(),
              ),

              const Spacer(),

              // 底部说明文字
              Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Text(
                  '请确保已启动对应的后台服务',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建功能按钮
  Widget _buildFeatureButton({
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return Container(
      width: double.infinity,
      height: 90,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                // 图标
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),

                const SizedBox(width: 16),

                // 文字内容
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),

                // 箭头图标
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withValues(alpha: 0.8),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 导航到语音通话页面
  void _navigateToAudioCall() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ZegoAudioPage(),
        fullscreenDialog: true,
      ),
    );
  }

  /// 导航到数字人页面
  void _navigateToDigitalHuman() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('尚未支持'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );

    return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ZegoAIAgentDigitalHumanPage(),
        fullscreenDialog: true,
      ),
    );
  }
}

/// 应用程序入口
class AIAgentApp extends StatelessWidget {
  const AIAgentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Agent Quick Start',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ZegoAIAgentHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
