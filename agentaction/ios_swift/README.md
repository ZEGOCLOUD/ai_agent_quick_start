# iOS Swift 使用说明

## 目录结构

- `ios_swift/agentaction`：可拷贝的 Swift Package 套件。
- `ios_swift/demo`：可运行的 Swift Demo Package。

> 英文版本请见 [README.en.md](./README.en.md)。

## 拷贝到你的项目

将 `ios_swift/agentaction` 拷贝到你的项目工作区，在 Xcode 中将其添加为本地 Swift Package 依赖；或者在另一个 `Package.swift` 中通过如下方式引用：

```swift
.package(path: "./agentaction")
```

然后依赖对应的库产品：

```swift
.product(name: "ZegoAIAgentAction", package: "agentaction")
```

导入包并使用生成的 Swift Protobuf 参数结构体：

```swift
import ZegoAIAgentAction

let client = ZegoAIAgentActionClient(
    roomId: "room_1",
    agentUserId: "agent_1",
    userId: "client_A",
    sender: { params, callback in
        // 替换为 ZEGO Express 房间通道消息 API
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

将 Express 房间通道回调转发至：

```swift
client.handleRoomChannelMessage(msgType: msgType, msgContent: msgContent)
```

运行 Demo：

```bash
cd agentaction/ios_swift/demo
swift run ZegoAIAgentActionDemo
```
