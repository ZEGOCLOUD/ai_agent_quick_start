# Android Usage

The Android AI Agent Action client suite wraps AI Agent instance control over ZEGO Express room channel messages.

## Directory Layout

- `agentaction/`: copyable Android Java suite source.
- `demo/`: runnable demo with a mock room-channel sender; see [demo/README.md](./demo/README.md).

> Chinese version: [README.md](./README.md)

## Suite Source

```text
agentaction/src/main/java/com/zego/agentaction/
├── AIAgentActionProto.java            # Generated Protobuf Java runtime classes
├── ZegoAIAgentActionClient.java       # Core client (send / receive / timeout)
├── ZegoAIAgentActionDefines.java      # Error codes, Express field names, protocol keys
└── ZegoAIAgentActionLogger.java       # Pluggable logger
```

## Integration Steps

### 1. Copy the Source

Copy the whole `agentaction/` directory into your Android project. The Java source lives at:

```text
agentaction/src/main/java/com/zego/agentaction
```

Wire the copied source folder into your module or move the package into your normal source tree.

### 2. Add the Protobuf Java Runtime

```gradle
dependencies {
    implementation "com.google.protobuf:protobuf-java:3.25.3"
}
```

### 3. Implement the Sender and Bridge to ZEGO Express

`ZegoAIAgentActionClient.Sender` receives a JSON envelope and meta (`roomId / msgType / userList / seq`) that the suite has already assembled. Your code forwards it directly to ZEGO Express via `callExperimentalAPI`.

Example:

```java
ZegoAIAgentActionClient client = new ZegoAIAgentActionClient(
    "room_1",                                            // 1  roomId
    "agent_1",                                           // 2  agentUserId
    "client_A",                                          // 3  userId
    null,                                                // 4  agentInstanceId (null in non-digital-human mode)
    false,                                               // 5  isDigitalHuman
    null,                                                // 6  deviceId (null → suite auto-generates "android_<uuid8>")
    5000,                                                // 7  timeoutMs (default 5s)
    (params, formatedJson, callback) -> {
        // params carries roomId / msgType(=20) / userList(=[agentUserId]) / seq
        // formatedJson is already shaped for Express room-channel messages:
        // {
        //   "method": "liveroom.room.send_room_channel_message",
        //   "params": {
        //     "room_id":     "room_1",
        //     "msg_content": "{\"Action\":\"...\",\"Seq\":\"...\",\"Params\":{...}}",
        //     "user_list":   ["agent_1"],
        //     "seq":         1
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

### 4. Send an Action

```java
AIAgentActionProto.SendAgentInstanceTTSParams params =
    AIAgentActionProto.SendAgentInstanceTTSParams.newBuilder()
        .setText("hello")
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

The other four methods follow the same shape:

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

> `text` is capped at 300 chars. The default timeout is 5 s; use the `sendAgentInstanceTTS(params, timeoutMs, completion)` overload to override.

### 4.1 Completion Factory (Recommended)

If your business layer already has its own callback type (e.g. an `AgentActionCallback` that takes `int errorCode / String message / String requestId`), a small factory method lets you share one wrapper across all five actions:

```java
public interface AgentActionCallback {
    void onResult(int errorCode, String message, String requestId);
}

private ZegoAIAgentActionClient.Completion completion(String action, AgentActionCallback callback) {
    return new ZegoAIAgentActionClient.Completion() {
        @Override
        public void onSuccess(ZegoAIAgentActionClient.ZegoAIAgentActionResponse response) {
            Log.i("AgentAction", action + " success seq=" + response.seq
                  + " code=" + response.code + " requestId=" + response.requestId);
            if (callback != null) callback.onResult(response.code, response.message, response.requestId);
        }

        @Override
        public void onError(ZegoAIAgentActionClient.ZegoAIAgentActionError error) {
            Log.e("AgentAction", action + " failed seq=" + error.seq
                  + " code=" + error.code + " message=" + error.message);
            // error.code is Object; coerce non-zero integer codes to int
            int code = error.code instanceof Number ? ((Number) error.code).intValue() : -1;
            if (callback != null) callback.onResult(code, error.message, null);
        }
    };
}
```

Usage:

```java
AgentActionCallback cb = (code, message, requestId) -> { /* ... */ };
ZegoAIAgentActionClient.Completion completion = completion("SendAgentInstanceTTS", cb);

AIAgentActionProto.SendAgentInstanceTTSParams params =
    AIAgentActionProto.SendAgentInstanceTTSParams.newBuilder()
        .setText("hello").setAddHistory(true)
        .setPriority("Medium").setSamePriorityOption("ClearAndInterrupt")
        .build();
client.sendAgentInstanceTTS(params, completion);

client.interruptAgentInstance(completion);
client.sendAgentInstanceLLM(llmParams, completion);
client.startListening(startParams, completion);
client.stopListening(stopParams, completion);
```

### 5. Forward Room-Channel Callbacks

Forward every `onRecvExperimentalAPI` payload to `client.handleRoomChannelMessage(contentString)`. The suite decides whether the payload is an AI Agent Action message:

- AI Agent Action response: parses `Action/Seq/Code/Message/RequestId/Data` and triggers `onResponse` / `onError`; returns `true`.
- AI Agent Action send receipt: marks the corresponding `seq` as failed only when `errorCode != 0`; returns `true`.
- Any other message returns `false`, so you can keep your own custom-message parsing untouched.

Example:

```java
public boolean handleAgentActionRoomMessage(String content) {
    return agentActionClient != null
        && agentActionClient.handleRoomChannelMessage(content);
}
```

### 5.1 Hook Express's `onRecvExperimentalAPI`

`onRecvExperimentalAPI` is the entry point exposed by the ZEGO Express SDK for all experimental-API callbacks. Anything pushed down the room channel lands here as a raw JSON string — including AI Agent Action responses.

Integration steps:

1. Pass an `IZegoEventHandler` implementation into `ZegoExpressEngine.createEngine(...)`;
2. Override `onRecvExperimentalAPI(String content)` on that handler;
3. Forward the raw `content` to `agentActionClient.handleRoomChannelMessage(content)`; the suite decides whether the payload is an AI Agent Action message and fires `onResponse` / `onError`.

Example (pairs with section 5):

```java
public class AgentActionEventHandler implements IZegoEventHandler {

    private final ZegoAIAgentActionClient agentActionClient;

    public AgentActionEventHandler(ZegoAIAgentActionClient client) {
        this.agentActionClient = client;
    }

    @Override
    public void onRecvExperimentalAPI(String content) {
        // Hand off to the suite. Consumed -> true; otherwise fall through to your own parsing.
        if (agentActionClient != null) {
            agentActionClient.handleRoomChannelMessage(content);
        }
    }
}

// Inject the handler when creating the Express engine
ZegoEngineProfile profile = new ZegoEngineProfile();
profile.appID = YOUR_APP_ID;
profile.scenario = ZegoScenario.DEFAULT;

AgentActionEventHandler eventHandler = new AgentActionEventHandler(agentActionClient);
ZegoExpressEngine engine = ZegoExpressEngine.createEngine(profile, eventHandler);
```

> `onRecvExperimentalAPI` is a no-op default in `IZegoEventHandler`; override only the events you care about. Room-channel responses arrive as raw JSON strings in `content`.

### 6. Pluggable Logging (Optional)

```java
ZegoAIAgentActionLogger.setLevel(ZegoAIAgentActionLogger.LEVEL_DEBUG);
ZegoAIAgentActionLogger.installSink((level, label, message) ->
    Log.d("AgentAction", message));
```

## Error Codes

`ZegoAIAgentActionDefines.ErrorCodes`:

| Constant | Value | When |
|---|---:|---|
| `SUCCESS` | `0` | Any success path detected by the suite |
| `TIMEOUT` | `-1` | No AI Agent Action response within the default 5 s |
| `SEND_FAILED` | `-2` | `Sender` threw or Express rejected the send |
| `CANCELED` | `-3` | `client.cancelAll(message)` invoked explicitly |

## Defaults

- `priority`: `Medium`
- `samePriorityOption`: `ClearAndInterrupt`
- TTS `addHistory`: `true`
- LLM `addQuestionToHistory`: `false`, `addAnswerToHistory`: `true`
- Default timeout: `5000ms`

## Run the Demo

See [demo/README.md](./demo/README.md).

## References

- [SendAgentInstanceTTS](https://doc-zh.zego.im/aiagent-server/api-reference/agent-instance-control/send-agent-instance-tts)
- [SendAgentInstanceLLM](https://doc-zh.zego.im/aiagent-server/api-reference/agent-instance-control/send-agent-instance-llm)
- [InterruptAgentInstance](https://doc-zh.zego.im/aiagent-server/api-reference/agent-instance-control/interrupt-agent-instance)
- [StartListening](https://doc-zh.zego.im/aiagent-server/api-reference/agent-instance-control/start-listening)
- [StopListening](https://doc-zh.zego.im/aiagent-server/api-reference/agent-instance-control/stop-listening)
