# Flutter Usage

## Directory Layout

- `flutter/agentaction`: copyable Flutter package.
- `flutter/demo`: runnable Flutter demo app.

> Chinese version: [README.md](./README.md)

## Copy Into Your Project

Copy `flutter/agentaction` into your Flutter workspace, then add a path dependency from your app:

```yaml
dependencies:
  zego_ai_agent_action:
    path: ./agentaction
```

Import the package and use generated protobuf params objects:

```dart
import 'package:zego_ai_agent_action/zego_ai_agent_action.dart';

final client = ZegoAIAgentActionClient(
  roomId: 'room_1',
  agentUserId: 'agent_1',
  userId: 'client_A',
  sender: (params) async {
    // Replace with ZEGO Express room channel message bridge.
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

Forward Express room channel callbacks to:

```dart
client.handleRoomChannelMessage(msgType: msgType, msgContent: msgContent);
```

## Run Demo

```bash
cd agentaction/flutter/demo
flutter pub get
flutter run
```
