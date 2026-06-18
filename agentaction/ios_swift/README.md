# iOS Swift 使用说明

本目录提供 iOS Swift 端的 AI Agent Action 客户端套件，封装通过 ZEGO Express 房间通道消息控制 AI Agent 实例的全部交互。

## 目录结构

- `agentaction/`：可拷贝的 Swift Package 套件源码。
- `demo/`：可运行的 Swift Demo Package。

> 英文版本请见 [README.en.md](./README.en.md)。

## 套件源码

```text
agentaction/Sources/ZegoAIAgentAction/
├── Defines.swift                  # 错误码、Action 名、Express 字段名常量
├── Logger.swift                   # 可接管日志
├── ZegoAIAgentActionClient.swift  # 套件核心 Client（发送/接收/超时管理）
└── Generated/ai_agent_action.pb.swift  # Protobuf Swift 运行时生成的协议类
```

依赖：[`apple/swift-protobuf`](https://github.com/apple/swift-protobuf) `1.38.0+`，由 `Package.swift` 自动拉取。

## 集成步骤

### 1. 引入方式

**方式 A：本地 Swift Package（推荐）**

将 `ios_swift/agentaction/` 拷贝到你的项目工作区，在 Xcode 中 File → Add Package Dependencies → Add Local… 选中该目录；或者在另一个 `Package.swift` 中：

```swift
.package(path: "./agentaction")
```

并声明依赖：

```swift
.product(name: "ZegoAIAgentAction", package: "agentaction")
```

**方式 B：直接拷贝源码**

把 `Sources/ZegoAIAgentAction/` 整目录（含 `Generated/`）和 `Package.swift` 里的 `SwiftProtobuf` 依赖一起加入工程 target；最低部署目标 iOS 13+ / macOS 12+。

> iOS 工程如果用 CocoaPods + Objective-C，更推荐 [`../ios_oc`](../ios_oc/README.md) 目录下的 OC 版本套件。

### 2. 实现 Sender，桥接到 ZEGO Express

`ZegoAIAgentActionClient` 的 `Sender` 是一个 `(params, formatedJson, callback)` 闭包，由你直接透传给 ZEGO Express 的 `callExperimentalAPI`。

`formatedJson` 形如：

```json
{
  "method": "liveroom.room.send_room_channel_message",
  "params": {
    "room_id":     "room_1",
    "msg_content": "{\"Action\":\"...\",\"Seq\":\"...\",\"Params\":{...}}",
    "user_list":   ["agent_1"],
    "seq":         1
  }
}
```

### 3. 构造 Client

```swift
import ZegoAIAgentAction

let client = ZegoAIAgentActionClient(
    roomId: "room_1",
    agentUserId: "agent_1",
    userId: "client_A",
    deviceId: nil,                    // 缺省时自动生成 "ios_<uuid8>"
    timeoutMs: 5000,                  // 默认 5s
    sender: { params, formatedJson, callback in
        do {
            let result = try ZegoExpressEngine.shared()?.callExperimentalAPI(formatedJson)
            print("callExperimentalAPI 返回: \(result ?? "")")
            callback(ZegoAIAgentActionSendResult(errorCode: ZegoAIAgentActionErrorCodes.success,
                                                 seq: params.seq))
        } catch {
            callback(ZegoAIAgentActionSendResult(errorCode: ZegoAIAgentActionErrorCodes.sendFailed,
                                                 seq: params.seq))
        }
    },
    onResponse: { response in
        print("recv \(response.action) seq=\(response.seq) code=\(response.code) msg=\(response.message)")
    },
    onError: { error in
        print("err  \(error.action)   seq=\(error.seq)   code=\(error.code) msg=\(error.message)")
    }
)
```

### 4. 发送 Action

```swift
var params = ZegoSendAgentInstanceTTSParams()
params.text = "你好"
params.addHistory = true
params.priority = "Medium"
params.samePriorityOption = "ClearAndInterrupt"

client.sendAgentInstanceTTS(params) { result in
    switch result {
    case .success(let response): print("tts ok \(response.seq)")
    case .failure(let error):    print("tts err \(error.code) \(error.message)")
    }
}
```

其他四个方法完全对称：

```swift
// LLM
var llm = ZegoSendAgentInstanceLLMParams()
llm.text = "hi"
client.sendAgentInstanceLLM(llm) { result in /* ... */ }

// Interrupt
client.interruptAgentInstance { result in /* ... */ }

// StartListening / StopListening
let start = ZegoStartListeningParams()
client.startListening(start) { result in /* ... */ }
let stop = ZegoStopListeningParams()
client.stopListening(stop) { result in /* ... */ }
```

> `text` 长度限制 300 字符；超时可通过 `sendAgentInstanceTTS(params, timeoutMs: 8000)` 重载覆盖。

### 5. 转发房间通道回调

Express 的房间通道消息（来自 `onRecvExperimentalAPI`）丢给 `client.handleRoomChannelMessage(content:)`。套件会判断是否属于 AI Agent Action 消息：

- AI Agent Action 响应：解析 `Action/Seq/Code/Message/RequestId/Data` 并触发 `onResponse` 或 `onError`；返回 `true`。
- AI Agent Action 发送回执：仅在 `errorCode != 0` 时把对应 `seq` 标为失败；返回 `true`。
- 其他消息返回 `false`，可继续走业务自定义消息解析。

```swift
@discardableResult
func onRecvExperimentalAPI(_ content: String) -> Bool {
    let consumed = client.handleRoomChannelMessage(content: content)
    if consumed {
        print("已被 agentaction 套件消费")
    }
    return consumed
}
```

### 5.1 接入 Express 接收回调

`onRecvExperimentalAPI(_:)` 是 ZEGO Express SDK 暴露的实验性 API 回调入口，凡是走房间通道下发的消息都会以原始 JSON 字符串形式送到这个回调。AI Agent Action 的响应也走这里。

接入步骤：

1. 实现 `ZegoExpressEventHandler` 协议（只覆盖关心的事件即可）；
2. 在事件处理器里实现 `onRecvExperimentalAPI(_ content: String)`；
3. 把收到的 `content` 原文丢给 `client.handleRoomChannelMessage(content:)`，由套件判断是否属于 AI Agent Action 消息并触发 `onResponse` / `onError`。

示例代码（与 5. 节配合）：

```swift
final class AgentActionExpressHandler: NSObject, ZegoExpressEventHandler {
    let actionClient: ZegoAIAgentActionClient

    init(actionClient: ZegoAIAgentActionClient) {
        self.actionClient = actionClient
    }

    func onRecvExperimentalAPI(_ content: String) {
        // 委托给套件：消费了返回 true，未消费可继续走业务自定义消息解析
        _ = actionClient.handleRoomChannelMessage(content: content)
    }
}

// 创建 Express 时把 handler 注入
let profile = ZegoEngineProfile()
profile.appID = YOUR_APP_ID
profile.scenario = .default

let handler = AgentActionExpressHandler(actionClient: client)
ZegoExpressEngine.createEngine(profile, withEventHandler: handler)
```

> `onRecvExperimentalAPI(_:)` 在 `ZegoExpressEventHandler` 协议中是可选实现，只有覆写了才会收到事件；房间通道响应会以原始 JSON 字符串形式作为 `content` 传入。

### 6. 取消与清理

```swift
// 离开房间 / 退出 Agent 会话时主动取消在途请求
client.cancelAll(message: "logout")
```

### 7. 日志接管（可选）

```swift
ZegoAIAgentActionLogger.setLevel(.debug)
ZegoAIAgentActionLogger.installSink { line in
    print("[AgentAction] \(line)")
}
```

## 错误码

`ZegoAIAgentActionErrorCodes`：

| 常量 | 值 | 触发条件 |
|---|---:|---|
| `success` | `0` | 套件内部判定的所有成功路径 |
| `timeout` | `-1` | 默认 5 秒内未收到 AI Agent Action 响应 |
| `sendFailed` | `-2` | `Sender` 抛异常或 Express 发送失败 |
| `canceled` | `-3` | 主动调用 `client.cancelAll(message:)` |

## 默认值

- `priority`：`Medium`
- `samePriorityOption`：`ClearAndInterrupt`
- TTS `addHistory`：`true`
- LLM `addQuestionToHistory`：`false`，`addAnswerToHistory`：`true`
- 默认超时：`5000ms`

## 运行 Demo

```bash
cd agentaction/ios_swift/demo
swift run ZegoAIAgentActionDemo
```

## 参考文档

- [SendAgentInstanceTTS](https://doc-zh.zego.im/aiagent-server/api-reference/agent-instance-control/send-agent-instance-tts)
- [SendAgentInstanceLLM](https://doc-zh.zego.im/aiagent-server/api-reference/agent-instance-control/send-agent-instance-llm)
- [InterruptAgentInstance](https://doc-zh.zego.im/aiagent-server/api-reference/agent-instance-control/interrupt-agent-instance)
- [StartListening](https://doc-zh.zego.im/aiagent-server/api-reference/agent-instance-control/start-listening)
- [StopListening](https://doc-zh.zego.im/aiagent-server/api-reference/agent-instance-control/stop-listening)
