# Web Demo

最小可运行的浏览器 Demo，演示如何用 [agentaction 套件](../README.md) 通过 ZEGO Express `callExperimentalAPI` 调用 AI Agent Action 接口。

## 工程结构

```text
web/demo/
└── index.html    # 初始化 Express、登录房间、演示 5 个 Action 调用
```

Demo 直接引入 `../agentaction/src/*.js`，不需要额外再复制一份套件源码就能跑通。

这份 Demo 故意使用“浏览器直引”方式，是为了让你打开 `index.html` 就能验证链路；如果接入的是 TS / Vite / Webpack 项目，建议按套件 README 里的“包入口方式”使用 `agentaction/index.js + index.d.ts`。

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

## Demo 和套件入口的关系

可以这样看：

- Demo：为了最少依赖，直接引 `src/defines.js`、`src/logger.js`、`src/zego_ai_agent_action.js`
- 套件对外入口：`agentaction/index.js`
- TS 类型入口：`agentaction/index.d.ts`

也就是说：

- Demo 主要解决“浏览器直接验证”
- `index.js / index.d.ts` 主要解决“工程化项目接入”

详细协议字段、错误码、默认值见 [套件 README](../README.md)。
