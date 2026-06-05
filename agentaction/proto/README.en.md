# Protocol Generation

`ai_agent_action.proto` is the source of truth for the transport protocol.

Install the required protoc plugins for the target platforms, then run:

```bash
cd agentaction
./scripts/generate_protocol.sh
```

Plugin setup used by this workspace:

```bash
dart pub global activate protoc_plugin
brew install swift-protobuf
npm install --prefix /tmp/agentaction-protoc-tools protoc-gen-js
```

The generation script adds the common plugin paths to `PATH` automatically:

- `$HOME/.pub-cache/bin`
- `$HOME/.cache/dart/pub/bin`
- `/opt/homebrew/bin`
- `/tmp/agentaction-protoc-tools/node_modules/.bin`

Expected generated outputs:

- Web: `web/agentaction/src/generated/ai_agent_action_pb.js`
- Flutter: `flutter/agentaction/lib/src/generated/ai_agent_action.pb.dart`
- Android: `android/agentaction/src/main/java/com/zego/agentaction/AIAgentActionProto.java`
- iOS Swift: `ios_swift/agentaction/Sources/ZegoAIAgentAction/Generated/ai_agent_action.pb.swift`
- iOS Objective-C: `ios_oc/agentaction/Sources/ZegoAIAgentActionObjC/Generated/AiAgentAction.pbobjc.{h,m}`

The public client APIs stay stable when regenerating protocol classes.

> Chinese version: [README.md](./README.md)
