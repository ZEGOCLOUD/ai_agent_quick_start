# Web Demo

最小可运行的浏览器 Demo，演示如何用 [agentaction 套件](../README.md) 通过 ZEGO Express `callExperimentalAPI` 调用 AI Agent Action 接口。

## 工程结构

```text
web/demo/
└── index.html    # 初始化 Express、登录房间、演示 5 个 Action 调用
```

Demo 直接引入 `../agentaction/src/*.js`，不需要复制套件源码就能跑通。

## 运行

先在 `index.html` 中替换你的 `appID / server / token`，并按业务需要替换 `roomId / userId / agentUserId`，然后用浏览器打开：

```bash
open agentaction/web/demo/index.html
```

> 英文版本请见 [README.en.md](./README.en.md)。

## 接入方式

Demo 的关键链路与 Android/iOS 保持一致：

- 初始化 `ZegoExpressEngine` 并登录房间；
- 在 `sender` 中把套件生成的 `formatedJson` 原样传给 `zg.callExperimentalAPI(formatedJson)`；
- 在 `recvExperimentalAPI` 中把收到的 `content` 原文交给 `client.handleRoomChannelMessage(content)`；
- 页面按钮分别演示 TTS、LLM、Interrupt、StartListening、StopListening 与 CancelAll。

详细协议字段、错误码、默认值见 [套件 README](../README.md)。
