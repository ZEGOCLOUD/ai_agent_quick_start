# Android Demo

Minimal runnable Android demo that shows how to drive AI Agent Action APIs with the [agentaction suite](../README.md). The demo ships with a **mock room-channel sender** so you can exercise the full send/receive loop without depending on live ZEGO Express traffic.

## Project Layout

```text
android/demo/
├── build.gradle                 # Root build (AGP 8.5.2)
├── settings.gradle              # Includes :app
└── app/
    ├── build.gradle             # compileSdk 35 / minSdk 23 / protobuf 4.35.0
    └── src/main/java/com/zego/agentaction/demo/
        └── MainActivity.java    # Mock sender; exercises all 5 actions
```

`app/build.gradle` adds the suite source directly:

```gradle
sourceSets {
    main.java.srcDirs += "../../agentaction/src/main/java"
}
```

So you don't need to copy the suite into the demo — it just compiles in.

## Run

Pick either path:

```bash
# CLI
cd agentaction/android/demo
./gradlew :app:assembleDebug
adb install -r app/build/outputs/apk/debug/app-debug.apk
```

```bash
# Android Studio
# Open the project root: agentaction/android/demo
# Select the app configuration → Run
```

> Chinese version: [README.md](./README.md)

## Swap the Mock Sender for Real ZEGO Express

The mock sender only replays responses in memory. To wire to production traffic, replace the `Sender` lambda inside `MainActivity` with a call to `ZegoExpressManager.callExperimentalAPI(formatedJson)`, and forward every `onRecvExperimentalAPI` payload to `client.handleRoomChannelMessage(content)`.

Reference production wiring:

```java
// Send: forward formatedJson straight into Express
client = new ZegoAIAgentActionClient(roomId, agentUserId, userId,
    (params, formatedJson, cb) -> {
        String result = ZegoExpressManager.getInstance().callExperimentalAPI(formatedJson);
        cb.onResult(new ZegoAIAgentActionClient.ZegoAIAgentActionSendResult(
            ZegoAIAgentActionDefines.ErrorCodes.SUCCESS, params.seq));
    },
    response -> Log.i("AgentAction", "recv " + response.action + " code=" + response.code),
    error     -> Log.e("AgentAction", "err "  + error.action     + " code=" + error.code));

// Receive: hand Express room-channel callbacks to the suite
ZegoAIAgentActionClient finalClient = client;
findViewById(R.id.btn_dispatch).setOnClickListener(v -> {
    finalClient.handleRoomChannelMessage(etMessage.getText().toString());
});
```

For protocol field details, error codes, and defaults see the [suite README](../README.md).

## References

- [Suite overview](../README.md)
