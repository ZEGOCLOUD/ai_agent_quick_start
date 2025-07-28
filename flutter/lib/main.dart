import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  Permission.microphone.request().then((status) {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Agent Quick Start',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        fontFamily: 'NotoSansSC',
        textTheme: const TextTheme(
          bodyMedium: TextStyle(
            fontFamilyFallback: [
              'Noto Sans SC',
              'PingFang SC',
              'Microsoft YaHei',
              'Heiti SC',
              'WenQuanYi Micro Hei',
              'sans-serif',
            ],
          ),
        ),
      ),
      home: const ZegoAIAgentHomePage(),
    );
  }
}
