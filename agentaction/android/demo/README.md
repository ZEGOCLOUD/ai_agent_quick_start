# Android Demo

最小可运行的 Android Demo 工程，演示如何用 [agentaction 套件](../README.md) 调用 AI Agent Action 接口。Demo 内置一个 **Mock 房间通道发送器**，不依赖真实 ZEGO Express 业务流量，方便先在本地跑通闭环。

## 工程结构

```text
android/demo/
├── build.gradle                 # 根 build（AGP 8.5.2）
├── settings.gradle              # 引入 :app
└── app/
    ├── build.gradle             # compileSdk 35 / minSdk 23 / protobuf 4.35.0
    └── src/main/java/com/zego/agentaction/demo/
        └── MainActivity.java    # 含 Mock Sender，演示 5 个 Action 调用
```

Demo 的 `app/build.gradle` 通过 `sourceSets.main.java.srcDirs += "../../agentaction/src/main/java"` 把 `../agentaction/src/main/java` 直接纳入编译源，**不需要复制套件源码**就能跑通。

## 运行

任选其一：

```bash
# 方式 1：命令行
cd agentaction/android/demo
./gradlew :app:assembleDebug
# 产物：app/build/outputs/apk/debug/app-debug.apk
adb install -r app/build/outputs/apk/debug/app-debug.apk
```

```bash
# 方式 2：Android Studio
# Open 工程根目录：agentaction/android/demo
# 选择 app 配置 → Run
```

> 英文版本请见 [README.en.md](./README.en.md)。

## 替换为真实 ZEGO Express 通道

Mock Sender 仅在内存中回放响应。要接到生产流量，把 `MainActivity` 中创建 `ZegoAIAgentActionClient` 时的 `Sender` Lambda 替换为 `ZegoExpressManager.callExperimentalAPI(formatedJson)`，并把接收侧的 `onRecvExperimentalAPI` 回调内容转交给 `client.handleRoomChannelMessage(content)`。

参考生产实现：

```java
// 发送：直接透传 formatedJson 给 Express
client = new ZegoAIAgentActionClient(roomId, agentUserId, userId,
    (params, formatedJson, cb) -> {
        String result = ZegoExpressManager.getInstance().callExperimentalAPI(formatedJson);
        cb.onResult(new ZegoAIAgentActionClient.ZegoAIAgentActionSendResult(
            ZegoAIAgentActionDefines.ErrorCodes.SUCCESS, params.seq));
    },
    response -> Log.i("AgentAction", "recv " + response.action + " code=" + response.code),
    error     -> Log.e("AgentAction", "err "  + error.action     + " code=" + error.code));

// 接收：把 Express 房间通道回调丢给套件
ZegoAIAgentActionClient finalClient = client;
findViewById(R.id.btn_dispatch).setOnClickListener(v -> {
    // 示例：把回调原文喂给套件
    finalClient.handleRoomChannelMessage(etMessage.getText().toString());
});
```

详细协议字段、错误码、默认值见 [套件 README](../README.md)。

## 参考

- [套件总览](../README.md)
