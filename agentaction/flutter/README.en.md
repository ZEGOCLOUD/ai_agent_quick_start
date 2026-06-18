# Flutter Usage

This folder provides the Flutter AI Agent Action client suite. It controls AI Agent instances through ZEGO Express room channel messages.

## Directory Layout

- `agentaction/`: copyable Flutter package.
- `demo/`: runnable Flutter demo app. See [demo/README.md](./demo/README.md).

> Chinese version: [README.md](./README.md)

## Integration

### 1. Copy the package

Copy `flutter/agentaction` into your Flutter workspace, then add a path dependency in your app `pubspec.yaml`:

```yaml
dependencies:
  zego_ai_agent_action:
    path: ./agentaction
```

Run:

```bash
flutter pub get
```

### 2. Add ZEGO Express

Your app should integrate the ZEGO Express Flutter SDK, for example:

```yaml
dependencies:
  zego_express_engine: ^3.15.0
```

### 3. Implement the Sender

The `sender` receives the JSON envelope assembled by the suite plus metadata such as `roomId / msgType / userList / seq`. For real traffic, pass `formatedJson` directly to `ZegoExpressEngine.instance.callExperimentalAPI`.

```dart
import 'package:zego_ai_agent_action/zego_ai_agent_action.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

final client = ZegoAIAgentActionClient(
  roomId: 'room_1',
  agentUserId: 'agent_1',
  userId: 'client_A',
  sender: (params, formatedJson) async {
    try {
      final result = await ZegoExpressEngine.instance.callExperimentalAPI(formatedJson);
      print('callExperimentalAPI result=$result');
      return ZegoAIAgentActionSendResult(
        errorCode: ZegoAIAgentActionErrorCodes.success,
        seq: params.seq,
      );
    } catch (e) {
      return ZegoAIAgentActionSendResult(
        errorCode: ZegoAIAgentActionErrorCodes.sendFailed,
        seq: params.seq,
      );
    }
  },
  onResponse: (response) {
    print('recv ${response.action} seq=${response.seq} code=${response.code} msg=${response.message}');
  },
  onError: (error) {
    print('err ${error.action} seq=${error.seq} code=${error.code} msg=${error.message}');
  },
);
```

### 4. Send Actions

```dart
final params = SendAgentInstanceTTSParams(
  text: '你好',
  addHistory: true,
  priority: 'Medium',
  samePriorityOption: 'ClearAndInterrupt',
);

final response = await client.sendAgentInstanceTTS(params);
print('tts ok seq=${response.seq}');
```

The other four methods are symmetrical:

```dart
final llm = SendAgentInstanceLLMParams(
  text: 'hi',
  systemPrompt: '',
  addQuestionToHistory: false,
  addAnswerToHistory: true,
  priority: 'Medium',
  samePriorityOption: 'ClearAndInterrupt',
);
await client.sendAgentInstanceLLM(llm);

await client.interruptAgentInstance();
await client.startListening(StartListeningParams());
await client.stopListening(StopListeningParams());
```

`text` is limited to 300 characters. The default timeout is 5 seconds and can be overridden with each method's `timeoutMs` argument.

### 5. Forward Room Channel Callbacks

Forward Express `onRecvExperimentalAPI` content to `client.handleRoomChannelMessage(content)`. The suite decides whether the payload is an AI Agent Action message:

- AI Agent Action response: parse `Action/Seq/Code/Message/RequestId/Data` and trigger `onResponse` or `onError`; returns `true`.
- AI Agent Action send receipt: when `errorCode != 0`, mark the matching `seq` as failed; returns `true`.
- Other messages return `false`.

```dart
ZegoExpressEngine.onRecvExperimentalAPI = (content) {
  final consumed = client.handleRoomChannelMessage(content);
  if (consumed) {
    print('agentaction message consumed');
  }
};
```

### 6. Cancel and Clean Up

```dart
client.cancelAll('logout');
await ZegoExpressEngine.destroyEngine();
```

### 7. Logging

```dart
ZegoAIAgentActionLogger.setLevel(ZegoAIAgentActionLogger.levelDebug);
ZegoAIAgentActionLogger.installSink((line) {
  print('[AgentAction] $line');
});
```

## Error Codes

`ZegoAIAgentActionErrorCodes`:

| Constant | Value | Trigger |
|---|---:|---|
| `success` | `0` | Suite-level success |
| `timeout` | `-1` | No AI Agent Action response within the default 5 seconds |
| `sendFailed` | `-2` | `sender` throws or Express send fails |
| `canceled` | `-3` | `client.cancelAll()` is called |

## Run Demo

```bash
cd agentaction/flutter/demo
flutter pub get
flutter run
```
