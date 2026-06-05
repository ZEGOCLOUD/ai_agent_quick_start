# iOS Swift Usage

## Directory Layout

- `ios_swift/agentaction`: copyable Swift Package suite.
- `ios_swift/demo`: runnable Swift demo package.

> Chinese version: [README.md](./README.md)

## Copy Into Your Project

Copy `ios_swift/agentaction` into your project workspace and add it as a local Swift Package dependency in Xcode, or from another `Package.swift`:

```swift
.package(path: "./agentaction")
```

Then depend on the library product:

```swift
.product(name: "ZegoAIAgentAction", package: "agentaction")
```

Import the package and use generated Swift protobuf params structs:

```swift
import ZegoAIAgentAction

let client = ZegoAIAgentActionClient(
    roomId: "room_1",
    agentUserId: "agent_1",
    userId: "client_A",
    sender: { params, callback in
        // Replace with ZEGO Express room channel message API.
        callback(ZegoAIAgentActionSendResult(errorCode: 0, seq: params.seq))
    },
    onResponse: { response in
        print(response.message)
    }
)

var params = ZegoSendAgentInstanceTTSParams()
params.text = "你好"
params.addHistory = true
params.priority = "Medium"
params.samePriorityOption = "ClearAndInterrupt"
client.sendAgentInstanceTTS(params) { result in
    print(result)
}
```

Forward Express room channel callbacks to:

```swift
client.handleRoomChannelMessage(msgType: msgType, msgContent: msgContent)
```

Run the demo:

```bash
cd agentaction/ios_swift/demo
swift run ZegoAIAgentActionDemo
```
