# Android 使用说明

本目录提供 Android 端 AI Agent Action 客户端套件，封装通过 ZEGO Express 房间通道消息控制 AI Agent 实例的全部交互。

## 目录结构

- `agentaction/`：可拷贝的 Android Java 套件源码。
- `demo/`：带 Mock 房间通道发送器的最小可运行 Demo，详见 [demo/README.md](./demo/README.md)。

> 英文版本请见 [README.en.md](./README.en.md)。

## 套件源码

```text
agentaction/src/main/java/com/zego/agentaction/
├── AIAgentActionProto.java            # Protobuf Java 运行时生成的协议类
├── ZegoAIAgentActionClient.java       # 套件核心 Client（发送/接收/超时管理）
├── ZegoAIAgentActionDefines.java      # 错误码、Express 字段名、协议字段名常量
└── ZegoAIAgentActionLogger.java       # 可接管日志
```

## 集成步骤

### 1. 拷贝源码

将 `agentaction/` 整个目录拷贝到你的 Android 项目，对应 Java 源码路径为：

```text
agentaction/src/main/java/com/zego/agentaction
```

将拷贝后的源码目录接入你的 Module，或直接移动到你的源码目录中。

### 2. 添加 Protobuf Java 运行时

```gradle
dependencies {
    implementation "com.google.protobuf:protobuf-java:3.25.3"
}
```

### 3. 实现 Sender，桥接到 ZEGO Express

`ZegoAIAgentActionClient.Sender` 接收套件组装好的 JSON 信封与 `roomId / msgType / userList / seq` 等元数据，由你直接透传给 ZEGO Express 的 `callExperimentalAPI`。

示例代码：

```java
ZegoAIAgentActionClient client = new ZegoAIAgentActionClient(
    "room_1",                                            // 1  roomId
    "agent_1",                                           // 2  agentUserId
    "client_A",                                          // 3  userId
    null,                                                // 4  agentInstanceId（非数字人场景传 null）
    false,                                               // 5  isDigitalHuman
    null,                                                // 6  deviceId（null 时套件自动生成 "android_<uuid8>"）
    5000,                                                // 7  timeoutMs（默认 5s）
    (params, formatedJson, callback) -> {
        // params 携带 roomId / msgType(=20) / userList(=[agentUserId]) / seq
        // formatedJson 已经按 Express 房间通道消息协议组装好：
        // {
        //   "method": "liveroom.room.send_room_channel_message",
        //   "params": {
        //     "room_id":    "room_1",
        //     "msg_content": "{\"Action\":\"...\",\"Seq\":\"...\",\"Params\":{...}}",
        //     "user_list":  ["agent_1"],
        //     "seq":        1
        //   }
        // }
        try {
            String result = ZegoExpressManager.getInstance().callExperimentalAPI(formatedJson);
            callback.onResult(new ZegoAIAgentActionClient.ZegoAIAgentActionSendResult(
                ZegoAIAgentActionDefines.ErrorCodes.SUCCESS, params.seq));
        } catch (Exception e) {
            callback.onResult(new ZegoAIAgentActionClient.ZegoAIAgentActionSendResult(
                ZegoAIAgentActionDefines.ErrorCodes.SEND_FAILED, params.seq));
        }
    },
    response -> Log.i("AgentAction", "recv seq=" + response.seq + " code=" + response.code),
    error     -> Log.e("AgentAction", "err  seq=" + error.seq   + " code=" + error.code)
);
```

### 4. 发送 Action

```java
AIAgentActionProto.SendAgentInstanceTTSParams params =
    AIAgentActionProto.SendAgentInstanceTTSParams.newBuilder()
        .setText("你好")
        .setAddHistory(true)
        .setPriority("Medium")
        .setSamePriorityOption("ClearAndInterrupt")
        .build();
client.sendAgentInstanceTTS(params, new ZegoAIAgentActionClient.Completion() {
    @Override
    public void onSuccess(ZegoAIAgentActionClient.ZegoAIAgentActionResponse response) {}

    @Override
    public void onError(ZegoAIAgentActionClient.ZegoAIAgentActionError error) {}
});
```

其他四个方法完全对称：

```java
// LLM
AIAgentActionProto.SendAgentInstanceLLMParams llm =
    AIAgentActionProto.SendAgentInstanceLLMParams.newBuilder().setText("hi").build();
client.sendAgentInstanceLLM(llm, completion);

// Interrupt
client.interruptAgentInstance(completion);

// StartListening / StopListening
client.startListening(AIAgentActionProto.StartListeningParams.newBuilder().build(), completion);
client.stopListening(AIAgentActionProto.StopListeningParams.newBuilder().build(), completion);
```

> `text` 长度限制 300 字符；超时默认 5 秒，可通过 `sendAgentInstanceTTS(params, timeoutMs, completion)` 重载覆盖。

### 4.1 Completion 工厂方法（推荐）

如果你的业务层已有自己的回调类型（例如 `SendTextToAgentInstanceCallback` 接收 `int errorCode / String message / String requestId`），可以用一个工厂方法把套件的 `Completion` 统一转换为业务回调，便于在五个 Action 之间复用：

```java
public interface AgentActionCallback {
    void onResult(int errorCode, String message, String requestId);
}

private ZegoAIAgentActionClient.Completion completion(String action, AgentActionCallback callback) {
    return new ZegoAIAgentActionClient.Completion() {
        @Override
        public void onSuccess(ZegoAIAgentActionClient.ZegoAIAgentActionResponse response) {
            Log.i("AgentAction", action + " 成功 seq=" + response.seq
                  + " code=" + response.code + " requestId=" + response.requestId);
            if (callback != null) callback.onResult(response.code, response.message, response.requestId);
        }

        @Override
        public void onError(ZegoAIAgentActionClient.ZegoAIAgentActionError error) {
            Log.e("AgentAction", action + " 失败 seq=" + error.seq
                  + " code=" + error.code + " message=" + error.message);
            // error.code 是 Object；非 0 整数错误码时把它转成 int 透传给业务层
            int code = error.code instanceof Number ? ((Number) error.code).intValue() : -1;
            if (callback != null) callback.onResult(code, error.message, null);
        }
    };
}
```

使用：

```java
AgentActionCallback cb = (code, message, requestId) -> { /* ... */ };
ZegoAIAgentActionClient.Completion completion = completion("SendAgentInstanceTTS", cb);

AIAgentActionProto.SendAgentInstanceTTSParams params =
    AIAgentActionProto.SendAgentInstanceTTSParams.newBuilder()
        .setText("你好").setAddHistory(true)
        .setPriority("Medium").setSamePriorityOption("ClearAndInterrupt")
        .build();
client.sendAgentInstanceTTS(params, completion);

client.interruptAgentInstance(completion);
client.sendAgentInstanceLLM(llmParams, completion);
client.startListening(startParams, completion);
client.stopListening(stopParams, completion);
```

### 5. 转发房间通道回调

Express 的 `onRecvExperimentalAPI` 回调内容丢给 `client.handleRoomChannelMessage(contentString)`，由套件判断是否属于 AI Agent Action 消息：

- AI Agent Action 响应：解析 `Action/Seq/Code/Message/RequestId/Data` 并触发 `onResponse` 或 `onError`；返回值 `true`。
- AI Agent Action 发送回执：仅在 `errorCode != 0` 时把对应 `seq` 标为失败；返回值 `true`。
- 其他消息返回 `false`，可继续走业务自定义消息解析。

示例代码：

```java
public boolean handleAgentActionRoomMessage(String content) {
    return agentActionClient != null
        && agentActionClient.handleRoomChannelMessage(content);
}
```

### 5.1 接入 Express 接收回调

`onRecvExperimentalAPI` 是 ZEGO Express SDK 暴露的实验性 API 回调入口，凡是走房间通道下发的消息都会以原始 JSON 字符串形式送到这个回调。AI Agent Action 的响应也走这里。

接入步骤：

1. 在创建 `ZegoExpressEngine` 时传入一个实现 `IZegoEventHandler` 的事件处理器；
2. 在事件处理器里覆写 `onRecvExperimentalAPI(String content)`；
3. 把收到的 `content` 原文丢给 `agentActionClient.handleRoomChannelMessage(content)`，由套件判断是否属于 AI Agent Action 消息并触发 `onResponse` / `onError`。

示例代码（与 5. 节配合）：

```java
public class AgentActionEventHandler implements IZegoEventHandler {

    private final ZegoAIAgentActionClient agentActionClient;

    public AgentActionEventHandler(ZegoAIAgentActionClient client) {
        this.agentActionClient = client;
    }

    @Override
    public void onRecvExperimentalAPI(String content) {
        // 委托给套件：消费了返回 true，未消费可继续走业务自定义消息解析
        if (agentActionClient != null) {
            agentActionClient.handleRoomChannelMessage(content);
        }
    }
}

// 创建 Express 时把 handler 注入
ZegoEngineProfile profile = new ZegoEngineProfile();
profile.appID = YOUR_APP_ID;
profile.scenario = ZegoScenario.DEFAULT;

AgentActionEventHandler eventHandler = new AgentActionEventHandler(agentActionClient);
ZegoExpressEngine engine = ZegoExpressEngine.createEngine(profile, eventHandler);
```

> `onRecvExperimentalAPI` 在 `IZegoEventHandler` 中是默认空实现，只需覆写关心的事件即可；房间通道响应会以原始 JSON 字符串形式作为 `content` 传入。

### 6. 日志接管（可选）

```java
ZegoAIAgentActionLogger.setLevel(ZegoAIAgentActionLogger.LEVEL_DEBUG);
ZegoAIAgentActionLogger.installSink((level, label, message) ->
    Log.d("AgentAction", message));
```

## 错误码

`ZegoAIAgentActionDefines.ErrorCodes`：

| 常量 | 值 | 触发条件 |
|---|---:|---|
| `SUCCESS` | `0` | 套件内部判定的所有成功路径 |
| `TIMEOUT` | `-1` | 默认 5 秒内未收到 AI Agent Action 响应 |
| `SEND_FAILED` | `-2` | `Sender` 抛异常或 Express 发送失败 |
| `CANCELED` | `-3` | 主动调用 `client.cancelAll(message)` |

## 默认值

- `priority`：`Medium`
- `samePriorityOption`：`ClearAndInterrupt`
- TTS `addHistory`：`true`
- LLM `addQuestionToHistory`：`false`，`addAnswerToHistory`：`true`
- 默认超时：`5000ms`

## 运行 Demo

参见 [demo/README.md](./demo/README.md)。

## 参考文档

- [SendAgentInstanceTTS](https://doc-zh.zego.im/aiagent-server/api-reference/agent-instance-control/send-agent-instance-tts)
- [SendAgentInstanceLLM](https://doc-zh.zego.im/aiagent-server/api-reference/agent-instance-control/send-agent-instance-llm)
- [InterruptAgentInstance](https://doc-zh.zego.im/aiagent-server/api-reference/agent-instance-control/interrupt-agent-instance)
- [StartListening](https://doc-zh.zego.im/aiagent-server/api-reference/agent-instance-control/start-listening)
- [StopListening](https://doc-zh.zego.im/aiagent-server/api-reference/agent-instance-control/stop-listening)
