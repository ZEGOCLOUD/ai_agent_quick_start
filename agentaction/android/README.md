# Android 使用说明

## 目录结构

- `android/agentaction`：可拷贝的 Android Java 套件。
- `android/demo`：可运行的 Android Demo 工程。

> 英文版本请见 [README.en.md](./README.en.md)。

## 拷贝到你的项目

将 `android/agentaction` 拷贝到你的 Android 项目。SDK 源码位于：

```text
android/agentaction/src/main/java/com/zego/agentaction
```

在编译该套件的 App/Module 中加入 Protobuf Java 运行时：

```gradle
dependencies {
    implementation "com.google.protobuf:protobuf-java:3.25.3"
}
```

将拷贝后的源码目录接入你的 Module，或直接移动到你的源码目录中，然后使用生成的 Protobuf 参数对象：

```java
ZegoAIAgentActionClient client = new ZegoAIAgentActionClient(
    "room_1",
    "agent_1",
    "client_A",
    (params, callback) -> {
        // 替换为 ZEGO Express 房间通道消息 API
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

将 Express 房间通道回调转发至：

```java
client.handleRoomChannelMessage(msgType, msgContent);
```

## 运行 Demo

```bash
gradle -p agentaction/android/demo :app:assembleDebug
```
