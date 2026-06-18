# iOS Swift Usage

The iOS Swift AI Agent Action client suite wraps AI Agent instance control over ZEGO Express room channel messages.

## Directory Layout

- `agentaction/`: copyable Swift Package suite source.
- `demo/`: runnable Swift demo package.

> Chinese version: [README.md](./README.md)

## Suite Source

```text
agentaction/Sources/ZegoAIAgentAction/
├── Defines.swift                  # Error codes, Action names, Express field constants
├── Logger.swift                   # Pluggable logger
├── ZegoAIAgentActionClient.swift  # Core client (send / receive / timeout)
└── Generated/ai_agent_action.pb.swift  # Protobuf Swift runtime generated classes
```

Dependency: [`apple/swift-protobuf`](https://github.com/apple/swift-protobuf) `1.38.0+`, pulled in by `Package.swift`.

## Integration Steps

### 1. Add the Suite

**Option A — Local Swift Package (recommended)**

Copy `ios_swift/agentaction/` into your project workspace, then in Xcode choose File → Add Package Dependencies → Add Local… and pick that directory. Or, in another `Package.swift`:

```swift
.package(path: "./agentaction")
```

and depend on:

```swift
.product(name: "ZegoAIAgentAction", package: "agentaction")
```

**Option B — Copy sources directly**

Drag `Sources/ZegoAIAgentAction/` (including `Generated/`) and the `SwiftProtobuf` dependency from `Package.swift` into your app target. Minimum deployment: iOS 13+ / macOS 12+.

> For CocoaPods + Objective-C iOS projects, prefer the OC suite under [`../ios_oc`](../ios_oc/README.md) — that is what the reference client adopts.

### 2. Implement the Sender and Bridge to ZEGO Express

`ZegoAIAgentActionClient.Sender` is a `(params, formatedJson, callback)` closure; your code forwards it directly to ZEGO Express via `callExperimentalAPI`.

`formatedJson` looks like:

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

### 3. Construct the Client

```swift
import ZegoAIAgentAction

let client = ZegoAIAgentActionClient(
    roomId: "room_1",
    agentUserId: "agent_1",
    userId: "client_A",
    deviceId: nil,                    // auto-generated "ios_<uuid8>" if nil
    timeoutMs: 5000,                  // default 5 s
    sender: { params, formatedJson, callback in
        do {
            let result = try ZegoExpressEngine.shared()?.callExperimentalAPI(formatedJson)
            print("callExperimentalAPI returned: \(result ?? "")")
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

### 4. Send an Action

```swift
var params = ZegoSendAgentInstanceTTSParams()
params.text = "hello"
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

The other four methods follow the same shape:

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

> `text` is capped at 300 chars. Override the timeout with the `sendAgentInstanceTTS(params, timeoutMs: 8000)` overload.

### 5. Forward Room-Channel Callbacks

Forward every Express room-channel payload (from `onRecvExperimentalAPI`) to `client.handleRoomChannelMessage(content:)`. The suite decides whether the payload is an AI Agent Action message:

- AI Agent Action response: parses `Action/Seq/Code/Message/RequestId/Data` and triggers `onResponse` / `onError`; returns `true`.
- AI Agent Action send receipt: marks the corresponding `seq` as failed only when `errorCode != 0`; returns `true`.
- Any other message returns `false`, so you can keep your own custom-message parsing untouched.

```swift
@discardableResult
func onRecvExperimentalAPI(_ content: String) -> Bool {
    let consumed = client.handleRoomChannelMessage(content: content)
    if consumed { print("consumed by agentaction suite") }
    return consumed
}
```

### 5.1 Hook Express's `onRecvExperimentalAPI`

`onRecvExperimentalAPI(_:)` is the entry point exposed by the ZEGO Express SDK for all experimental-API callbacks. Anything pushed down the room channel lands here as a raw JSON string — including AI Agent Action responses.

Integration steps:

1. Adopt the `ZegoExpressEventHandler` protocol (only implement the events you care about);
2. Implement `onRecvExperimentalAPI(_ content: String)` on that handler;
3. Forward the raw `content` to `client.handleRoomChannelMessage(content:)`; the suite decides whether the payload is an AI Agent Action message and fires `onResponse` / `onError`.

Example (pairs with section 5):

```swift
final class AgentActionExpressHandler: NSObject, ZegoExpressEventHandler {
    let actionClient: ZegoAIAgentActionClient

    init(actionClient: ZegoAIAgentActionClient) {
        self.actionClient = actionClient
    }

    func onRecvExperimentalAPI(_ content: String) {
        // Hand off to the suite. Consumed -> true; otherwise fall through to your own parsing.
        _ = actionClient.handleRoomChannelMessage(content: content)
    }
}

// Inject the handler when creating the Express engine
let profile = ZegoEngineProfile()
profile.appID = YOUR_APP_ID
profile.scenario = .default

let handler = AgentActionExpressHandler(actionClient: client)
ZegoExpressEngine.createEngine(profile, withEventHandler: handler)
```

> `onRecvExperimentalAPI(_:)` is optional on the `ZegoExpressEventHandler` protocol; you only receive the event if you implement it. Room-channel responses arrive as raw JSON strings in `content`.

### 6. Cancel and Tear Down

```swift
// When leaving the room / closing the agent session
client.cancelAll(message: "logout")
```

### 7. Pluggable Logging (Optional)

```swift
ZegoAIAgentActionLogger.setLevel(.debug)
ZegoAIAgentActionLogger.installSink { line in
    print("[AgentAction] \(line)")
}
```

## Error Codes

`ZegoAIAgentActionErrorCodes`:

| Constant | Value | When |
|---|---:|---|
| `success` | `0` | Any success path detected by the suite |
| `timeout` | `-1` | No AI Agent Action response within the default 5 s |
| `sendFailed` | `-2` | `Sender` threw or Express rejected the send |
| `canceled` | `-3` | `client.cancelAll(message:)` invoked explicitly |

## Defaults

- `priority`: `Medium`
- `samePriorityOption`: `ClearAndInterrupt`
- TTS `addHistory`: `true`
- LLM `addQuestionToHistory`: `false`, `addAnswerToHistory`: `true`
- Default timeout: `5000ms`

## Run the Demo

```bash
cd agentaction/ios_swift/demo
swift run ZegoAIAgentActionDemo
```

## References

- [SendAgentInstanceTTS](https://doc-zh.zego.im/aiagent-server/api-reference/agent-instance-control/send-agent-instance-tts)
- [SendAgentInstanceLLM](https://doc-zh.zego.im/aiagent-server/api-reference/agent-instance-control/send-agent-instance-llm)
- [InterruptAgentInstance](https://doc-zh.zego.im/aiagent-server/api-reference/agent-instance-control/interrupt-agent-instance)
- [StartListening](https://doc-zh.zego.im/aiagent-server/api-reference/agent-instance-control/start-listening)
- [StopListening](https://doc-zh.zego.im/aiagent-server/api-reference/agent-instance-control/stop-listening)
