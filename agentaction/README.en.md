# ZEGO AI Agent Action Client Suite

This suite wraps AI Agent instance control over ZEGO Express room channel messages for Web, Android, iOS Swift, iOS Objective-C, and Flutter.

Each platform is split into a copyable SDK folder and a runnable demo:

```text
web/
  agentaction/
  demo/
flutter/
  agentaction/
  demo/
android/
  agentaction/
  demo/
ios_swift/
  agentaction/
  demo/
ios_oc/
  agentaction/
  demo/
```

Customer integrations should copy only the target platform's `agentaction/` folder into their project. The matching `demo/` folder shows a minimal runnable integration with a mock room channel sender.

> Chinese version: [README.md](./README.md)

## Protocol

- Client request message type: `20`
- Agent final response message type: `22`
- `Seq` is generated on the client as a string and echoed by the final response.
- `AgentInstanceId` is not sent in action `Params`; the target agent is represented by Express `user_list=[agentUserId]`.
- Action params are defined in [proto/ai_agent_action.proto](./proto/ai_agent_action.proto). Generated platform classes should be refreshed from this file before release.

## Unified APIs

All five platform packages expose the same five methods:

- `sendAgentInstanceTTS`
- `sendAgentInstanceLLM`
- `interruptAgentInstance`
- `startListening`
- `stopListening`

Defaults:

- `priority`: `Medium`
- `samePriorityOption`: `ClearAndInterrupt`
- TTS `addHistory`: `true`
- LLM `addQuestionToHistory`: `false`
- LLM `addAnswerToHistory`: `true`
- Default timeout: `5000ms`

## Message Format

The suite sends `msg_type=20` to `user_list=[agentUserId]`.

`msg_content` is a JSON transport envelope so it can run in current demos without adding protobuf runtimes:

```json
{
  "Action": "SendAgentInstanceTTS",
  "Seq": "client_A:web_01:1",
  "Params": {
    "Text": "hello",
    "AddHistory": true,
    "Priority": "Medium",
    "SamePriorityOption": "ClearAndInterrupt"
  }
}
```

The protobuf file remains the source of truth for platform generated protocol classes, while the transport `msg_content` follows the JSON envelope required by the integration guide.

## Demos

- Web: [web/demo/index.html](./web/demo/index.html), directly open in a browser.
- Android: [android/demo/README.md](./android/demo/README.md)
- iOS Swift: [ios_swift/README.md](./ios_swift/README.md)
- iOS Objective-C: [ios_oc/README.md](./ios_oc/README.md)
- Flutter: [flutter/demo/README.md](./flutter/demo/README.md)

The native demo folders are runnable project skeletons with a mock room channel sender. Replace the mock sender with the matching ZEGO Express SDK bridge in product integration. See each platform README for the copy-and-use steps.

## References

- [SendAgentInstanceTTS](https://doc-zh.zego.im/aiagent-server/api-reference/agent-instance-control/send-agent-instance-tts)
- [SendAgentInstanceLLM](https://doc-zh.zego.im/aiagent-server/api-reference/agent-instance-control/send-agent-instance-llm)
- [InterruptAgentInstance](https://doc-zh.zego.im/aiagent-server/api-reference/agent-instance-control/interrupt-agent-instance)
- [StartListening](https://doc-zh.zego.im/aiagent-server/api-reference/agent-instance-control/start-listening)
- [StopListening](https://doc-zh.zego.im/aiagent-server/api-reference/agent-instance-control/stop-listening)
