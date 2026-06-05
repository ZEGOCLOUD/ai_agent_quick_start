# ZEGO AI Agent Action 客户端套件

本套件通过 ZEGO Express 房间通道消息对 AI Agent 实例进行控制，覆盖 Web、Android、iOS Swift、iOS Objective-C、Flutter 五大平台。

每个平台都拆分为可拷贝的 SDK 目录与可运行的 Demo：

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

客户接入时只需将目标平台下的 `agentaction/` 目录拷贝到自己的项目即可，对应的 `demo/` 目录提供了带 Mock 房间通道发送器的最小可运行示例。

> 英文版本请见 [README.en.md](./README.en.md)。

## 协议

- 客户端请求消息类型：`20`
- Agent 最终响应消息类型：`22`
- `Seq` 由客户端生成字符串，最终响应中原样回传。
- Action `Params` 中不携带 `AgentInstanceId`，目标 Agent 由 Express 的 `user_list=[agentUserId]` 表示。
- Action 参数定义见 [proto/ai_agent_action.proto](./proto/ai_agent_action.proto)。各平台生成的协议类在发布前需基于该文件重新生成。

## 统一 API

五个平台的 SDK 统一对外暴露以下五个方法：

- `sendAgentInstanceTTS`
- `sendAgentInstanceLLM`
- `interruptAgentInstance`
- `startListening`
- `stopListening`

默认值：

- `priority`：`Medium`
- `samePriorityOption`：`ClearAndInterrupt`
- TTS `addHistory`：`true`
- LLM `addQuestionToHistory`：`false`
- LLM `addAnswerToHistory`：`true`
- 默认超时时间：`5000ms`

## 消息格式

套件向 `user_list=[agentUserId]` 发送 `msg_type=20` 消息。

`msg_content` 采用 JSON 传输信封，便于在当前 Demo 中运行而无需引入 Protobuf 运行时：

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

`.proto` 文件仍是各平台生成协议类的源头，但传输的 `msg_content` 遵循集成指南要求的 JSON 信封格式。

## Demo

- Web：[web/demo/index.html](./web/demo/index.html)，直接用浏览器打开即可。
- Android：[android/demo/README.md](./android/demo/README.md)
- iOS Swift：[ios_swift/README.md](./ios_swift/README.md)
- iOS Objective-C：[ios_oc/README.md](./ios_oc/README.md)
- Flutter：[flutter/demo/README.md](./flutter/demo/README.md)

原生 Demo 目录是带 Mock 房间通道发送器的可运行项目骨架。实际接入时将 Mock 发送器替换为对应 ZEGO Express SDK 桥接即可，具体拷贝与使用步骤见各平台 README。

## 参考文档

- [SendAgentInstanceTTS](https://doc-zh.zego.im/aiagent-server/api-reference/agent-instance-control/send-agent-instance-tts)
- [SendAgentInstanceLLM](https://doc-zh.zego.im/aiagent-server/api-reference/agent-instance-control/send-agent-instance-llm)
- [InterruptAgentInstance](https://doc-zh.zego.im/aiagent-server/api-reference/agent-instance-control/interrupt-agent-instance)
- [StartListening](https://doc-zh.zego.im/aiagent-server/api-reference/agent-instance-control/start-listening)
- [StopListening](https://doc-zh.zego.im/aiagent-server/api-reference/agent-instance-control/stop-listening)
