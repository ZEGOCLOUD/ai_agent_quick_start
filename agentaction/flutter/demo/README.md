# Flutter Demo

最小可运行的 Flutter Demo 工程，演示如何用 [agentaction 套件](../README.md) 通过 ZEGO Express `callExperimentalAPI` 调用 AI Agent Action 接口。

## 工程结构

```text
flutter/demo/
├── pubspec.yaml              # 依赖 ../agentaction 与 zego_express_engine
└── lib/main.dart             # 初始化 Express、登录房间、演示 5 个 Action 调用
```

Demo 的 `pubspec.yaml` 通过 path 方式直接依赖 `../agentaction`，不需要复制套件源码就能跑通。

## 运行

先在 `lib/main.dart` 中替换你的 `appID` 与 `appSign`，并按业务需要替换 `roomId / userId / agentUserId`。

```bash
cd agentaction/flutter/demo
flutter pub get
flutter run
```

> 英文版本请见 [README.en.md](./README.en.md)。

## 接入方式

Demo 的关键链路与 Android/iOS 保持一致：

- 初始化 `ZegoExpressEngine` 并登录房间；
- 在 `sender` 中把套件生成的 `formatedJson` 原样传给 `ZegoExpressEngine.instance.callExperimentalAPI(formatedJson)`；
- 在 `ZegoExpressEngine.onRecvExperimentalAPI` 中把收到的 `content` 原文交给 `client.handleRoomChannelMessage(content)`；
- 页面按钮分别演示 TTS、LLM、Interrupt、StartListening、StopListening 与 CancelAll。

详细协议字段、错误码、默认值见 [套件 README](../README.md)。
