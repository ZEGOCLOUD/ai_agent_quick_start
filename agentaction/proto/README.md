# 协议生成

`ai_agent_action.proto` 是传输协议的源头定义。

为目标平台安装相应的 protoc 插件，然后执行：

```bash
cd agentaction
./scripts/generate_protocol.sh
```

本工作区使用的插件安装命令：

```bash
dart pub global activate protoc_plugin
brew install swift-protobuf
npm install --prefix /tmp/agentaction-protoc-tools protoc-gen-js
```

生成脚本会自动将以下公共插件路径加入 `PATH`：

- `$HOME/.pub-cache/bin`
- `$HOME/.cache/dart/pub/bin`
- `/opt/homebrew/bin`
- `/tmp/agentaction-protoc-tools/node_modules/.bin`

预期的生成产物：

- Web：`web/agentaction/src/generated/ai_agent_action_pb.js`
- Flutter：`flutter/agentaction/lib/src/generated/ai_agent_action.pb.dart`
- Android：`android/agentaction/src/main/java/com/zego/agentaction/AIAgentActionProto.java`
- iOS Swift：`ios_swift/agentaction/Sources/ZegoAIAgentAction/Generated/ai_agent_action.pb.swift`
- iOS Objective-C：`ios_oc/agentaction/Sources/ZegoAIAgentActionObjC/Generated/AiAgentAction.pbobjc.{h,m}`

重新生成协议类不会破坏对外公开的客户端 API。

> 英文版本请见 [README.en.md](./README.en.md)。
