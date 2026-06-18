# Flutter 使用说明

本目录提供 Flutter 端 AI Agent Action 客户端套件，封装通过 ZEGO Express 房间通道消息控制 AI Agent 实例的全部交互。

## 目录结构

- `agentaction/`：可拷贝的 Flutter Package。
- `demo/`：可运行的 Flutter Demo App，详见 [demo/README.md](./demo/README.md)。

> 英文版本请见 [README.en.md](./README.en.md)。

## 集成步骤

### 1. 拷贝源码

将 `flutter/agentaction` 拷贝到你的 Flutter 工程，然后在 App 的 `pubspec.yaml` 中通过 path 方式依赖：

```yaml
dependencies:
  zego_ai_agent_action:
    path: ./agentaction
```

执行：

```bash
flutter pub get
```

### 2. 添加 ZEGO Express 依赖

业务 App 需要自行集成 ZEGO Express Flutter SDK，例如：

```yaml
dependencies:
  zego_express_engine: ^3.15.0
```

### 3. 实现 Sender，桥接到 ZEGO Express

`ZegoAIAgentActionClient` 的 `sender` 接收套件组装好的 JSON 信封与 `roomId / msgType / userList / seq` 等元数据。实际接入时只需要把 `formatedJson` 原样透传给 `ZegoExpressEngine.instance.callExperimentalAPI`。

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

### 4. 发送 Action

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

其他四个方法完全对称：

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

> `text` 长度限制 300 字符；超时默认 5 秒，可通过各方法的 `timeoutMs` 参数覆盖。

### 5. 转发房间通道回调

Express 的 `onRecvExperimentalAPI` 回调内容丢给 `client.handleRoomChannelMessage(content)`，由套件判断是否属于 AI Agent Action 消息：

- AI Agent Action 响应：解析 `Action/Seq/Code/Message/RequestId/Data` 并触发 `onResponse` 或 `onError`；返回 `true`。
- AI Agent Action 发送回执：仅在 `errorCode != 0` 时把对应 `seq` 标为失败；返回 `true`。
- 其他消息返回 `false`，可继续走业务自定义消息解析。

```dart
ZegoExpressEngine.onRecvExperimentalAPI = (content) {
  final consumed = client.handleRoomChannelMessage(content);
  if (consumed) {
    print('agentaction message consumed');
  }
};
```

### 6. 取消与清理

```dart
client.cancelAll('logout');
await ZegoExpressEngine.destroyEngine();
```

### 7. 日志接管（可选）

```dart
ZegoAIAgentActionLogger.setLevel(ZegoAIAgentActionLogger.levelDebug);
ZegoAIAgentActionLogger.installSink((line) {
  print('[AgentAction] $line');
});
```

## 错误码

`ZegoAIAgentActionErrorCodes`：

| 常量 | 值 | 触发条件 |
|---|---:|---|
| `success` | `0` | 套件内部判定的所有成功路径 |
| `timeout` | `-1` | 默认 5 秒内未收到 AI Agent Action 响应 |
| `sendFailed` | `-2` | `sender` 抛异常或 Express 发送失败 |
| `canceled` | `-3` | 主动调用 `client.cancelAll()` |

## 运行 Demo

```bash
cd agentaction/flutter/demo
flutter pub get
flutter run
```
