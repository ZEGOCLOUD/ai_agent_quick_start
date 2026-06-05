# Flutter 使用说明

## 目录结构

- `flutter/agentaction`：可拷贝的 Flutter Package。
- `flutter/demo`：可运行的 Flutter Demo App。

> 英文版本请见 [README.en.md](./README.en.md)。

## 拷贝到你的项目

将 `flutter/agentaction` 拷贝到你的 Flutter 工程，然后在你的 App 中通过 path 方式依赖：

```yaml
dependencies:
  zego_ai_agent_action:
    path: ./agentaction
```

导入包并使用生成的 Protobuf 参数对象：

```dart
import 'package:zego_ai_agent_action/zego_ai_agent_action.dart';

final client = ZegoAIAgentActionClient(
  roomId: 'room_1',
  agentUserId: 'agent_1',
  userId: 'client_A',
  sender: (params) async {
    // 替换为 ZEGO Express 房间通道消息桥接
    return ZegoAIAgentActionSendResult(errorCode: 0, seq: params.seq);
  },
  onResponse: (response) => print(response.message),
);

final params = SendAgentInstanceLLMParams(
  text: '你好',
  systemPrompt: '',
  addQuestionToHistory: false,
  addAnswerToHistory: true,
  priority: 'Medium',
  samePriorityOption: 'ClearAndInterrupt',
);
final response = await client.sendAgentInstanceLLM(params);
```

将 Express 房间通道回调转发至：

```dart
client.handleRoomChannelMessage(msgType: msgType, msgContent: msgContent);
```

## 运行 Demo

```bash
cd agentaction/flutter/demo
flutter pub get
flutter run
```
