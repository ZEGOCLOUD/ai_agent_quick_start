import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:zego_ai_agent_action/zego_ai_agent_action.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

// 请替换为你的 AppID 和 AppSign
const int appID = 0;
const String appSign = '';

void main() {
  runApp(const DemoApp());
}

class DemoApp extends StatefulWidget {
  const DemoApp({super.key});

  @override
  State<DemoApp> createState() => _DemoAppState();
}

class _DemoAppState extends State<DemoApp> {
  static const _tag = 'ZegoAIAgentActionDemo';

  final logs = <String>[];
  late final ZegoAIAgentActionClient client;

  @override
  void initState() {
    super.initState();
    // 将 Kit 内部日志也转发到控制台与 UI 日志面板。
    ZegoAIAgentActionLogger.installSink((line) {
      _log('[kit] $line');
    });
    // 仅 Debug 模式打印到 stdout，Release 模式只走 UI 日志。
    if (!kReleaseMode) {
      ZegoAIAgentActionLogger.setLevel(ZegoAIAgentActionLogger.levelDebug);
    } else {
      ZegoAIAgentActionLogger.setLevel(ZegoAIAgentActionLogger.levelWarn);
    }

    _initSDK();
    client = ZegoAIAgentActionClient(
      roomId: 'room_test',
      agentUserId: 'agent_001',
      userId: 'client_A',
      sender: (params, formatedJson) async {
        _log('[sender] action=callExperimentalAPI seq=${params.seq}');
        _log('[sender] formatedJson=$formatedJson');
        try {
          final result = await ZegoExpressEngine.instance.callExperimentalAPI(formatedJson);
          _log('[sender] callExperimentalAPI result=$result');
        } catch (e, st) {
          _log('[sender] callExperimentalAPI error: $e\n$st');
          client.onError?.call(ZegoAIAgentActionError(
            params.seq,
            'unknown',
            ZegoAIAgentActionErrorCodes.sendFailed,
            e.toString(),
          ));
          return ZegoAIAgentActionSendResult(
            errorCode: ZegoAIAgentActionErrorCodes.sendFailed,
            seq: params.seq,
          );
        }
        return ZegoAIAgentActionSendResult(
          errorCode: ZegoAIAgentActionErrorCodes.success,
          seq: params.seq,
        );
      },
      onResponse: (response) {
        _log('[response] action=${response.action} seq=${response.seq} code=${response.code} message=${response.message}');
      },
      onError: (error) {
        _log('[error] action=${error.action} seq=${error.seq} code=${error.code} message=${error.message}');
      },
    );
  }

  Future<void> _initSDK() async {
    if (appID == 0) {
      _log('[init] Warning: appID is 0, please fill in your AppID and AppSign');
    }

    // 初始化 ZEGO Express SDK
    _log('[init] createEngineWithProfile appID=$appID');
    await ZegoExpressEngine.createEngineWithProfile(ZegoEngineProfile(
      appID,
      ZegoScenario.Default,
      appSign: appSign,
    ));

    // 监听实验性 API 回调
    ZegoExpressEngine.onRecvExperimentalAPI = (content) {
      _log('[express] recv experimental api content-length=${content.length}');
      _log('[express] $content');
      client.handleRoomChannelMessage(content);
    };

    // 登录房间（实际集成时请使用正式 Token）
    _log('[init] loginRoom roomId=room_test');
    await ZegoExpressEngine.instance
        .loginRoom('room_test', ZegoUser('client_A', 'client_A'));
    _log('[init] logged in to room_test');
  }

  void _log(String line) {
    final time = DateTime.now().toIso8601String();
    final formatted = '[$time] $line';
    developer.log(line, name: _tag);
    // ignore: avoid_print
    print('$_tag $formatted');
    if (mounted) {
      setState(() => logs.add(formatted));
    }
  }

  @override
  void dispose() {
    ZegoExpressEngine.destroyEngine();
    super.dispose();
  }

  void _runWithLog(String label, Future<void> Function() body) {
    _log('[action] $label click');
    body().catchError((e, st) {
      _log('[action] $label error: $e\n$st');
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('AI Agent Action Demo')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: () => _runWithLog('TTS', () async {
                      final r = await client.sendAgentInstanceTTS(SendAgentInstanceTTSParams(
                        text: '你好',
                        addHistory: true,
                        priority: 'Medium',
                        samePriorityOption: 'ClearAndInterrupt',
                      ));
                      _log('[action] TTS resolved seq=${r.seq}');
                    }),
                    child: const Text('TTS'),
                  ),
                  ElevatedButton(
                    onPressed: () => _runWithLog('LLM', () async {
                      final r = await client.sendAgentInstanceLLM(SendAgentInstanceLLMParams(
                        text: '你好',
                        systemPrompt: '',
                        addQuestionToHistory: false,
                        addAnswerToHistory: true,
                        priority: 'Medium',
                        samePriorityOption: 'ClearAndInterrupt',
                      ));
                      _log('[action] LLM resolved seq=${r.seq}');
                    }),
                    child: const Text('LLM'),
                  ),
                  ElevatedButton(
                    onPressed: () => _runWithLog('Interrupt', () async {
                      final r = await client.interruptAgentInstance();
                      _log('[action] Interrupt resolved seq=${r.seq}');
                    }),
                    child: const Text('Interrupt'),
                  ),
                  ElevatedButton(
                    onPressed: () => _runWithLog('StartListening', () async {
                      final r = await client.startListening(StartListeningParams());
                      _log('[action] Start resolved seq=${r.seq}');
                    }),
                    child: const Text('Start'),
                  ),
                  ElevatedButton(
                    onPressed: () => _runWithLog('StopListening', () async {
                      final r = await client.stopListening(StopListeningParams());
                      _log('[action] Stop resolved seq=${r.seq}');
                    }),
                    child: const Text('Stop'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _log('[action] cancelAll click');
                      client.cancelAll();
                    },
                    child: const Text('CancelAll'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  color: Colors.black12,
                  padding: const EdgeInsets.all(8),
                  child: ListView(
                    children: logs.reversed.map((line) => Text(line)).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
