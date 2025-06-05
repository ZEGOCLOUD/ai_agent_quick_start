import 'package:flutter/material.dart';

import 'im/page.dart';

void main() {
  runApp(const MyApp());
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
      home: const ZegoIMPage(),
    );
  }
}
