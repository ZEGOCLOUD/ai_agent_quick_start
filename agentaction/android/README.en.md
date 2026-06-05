# Android Usage

## Directory Layout

- `android/agentaction`: copyable Android Java suite.
- `android/demo`: runnable Android demo project.

> Chinese version: [README.md](./README.md)

## Copy Into Your Project

Copy `android/agentaction` into your Android project. The SDK source is under:

```text
android/agentaction/src/main/java/com/zego/agentaction
```

Add the protobuf Java runtime to the app/module that compiles the suite:

```gradle
dependencies {
    implementation "com.google.protobuf:protobuf-java:3.25.3"
}
```

Wire the copied source folder into your module or move the package into your normal source tree, then use generated protobuf params objects:

```java
ZegoAIAgentActionClient client = new ZegoAIAgentActionClient(
    "room_1",
    "agent_1",
    "client_A",
    (params, callback) -> {
        // Replace with ZEGO Express room channel message API.
        callback.onResult(new ZegoAIAgentActionClient.ZegoAIAgentActionSendResult(0, params.seq));
    },
    response -> Log.i("AgentAction", response.message)
);

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

Forward Express room channel callbacks to:

```java
client.handleRoomChannelMessage(msgType, msgContent);
```

## Run Demo

```bash
gradle -p agentaction/android/demo :app:assembleDebug
```
