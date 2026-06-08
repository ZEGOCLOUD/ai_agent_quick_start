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

Demo 的业务链路与 Android/iOS 保持一致，但 Web 实验性 API 的方法名和回调载荷形态与原生端不同：

- 初始化 `ZegoExpressEngine` 并登录房间；
- 在 `sender` 中把套件提供的 `formatedJson` 对象直接传给 `zg.callExperimentalAPI(...)`；
- 在 `recvExperimentalAPI` 中把收到的原始 `payload` 对象交给 `client.handleRoomChannelMessage(payload)`；
- 页面按钮分别演示 TTS、LLM、Interrupt、StartListening、StopListening 与 CancelAll。

补充说明：

- Web Express 的实验性 API 方法名是 `sendRoomChannelMessage / onRecvRoomChannelMessage`
- 不同于原生端，Web 侧发送没有回调
- 因此 Web 侧的“发送成功”主要看 `callExperimentalAPI` 有没有抛错，业务结果则继续等智能体回包或超时

## Demo 和套件入口的关系

可以这样看：

- Demo：为了最少依赖，直接引 `src/defines.js`、`src/logger.js`、`src/zego_ai_agent_action.js`
- 套件对外入口：`agentaction/index.js`
- TS 类型入口：`agentaction/index.d.ts`

也就是说：

- Demo 主要解决“浏览器直接验证”
- `index.js / index.d.ts` 主要解决“工程化项目接入”

详细协议字段、错误码、默认值见 [套件 README](../README.md)。
