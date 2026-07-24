# 跑通示例代码

[![English](https://img.shields.io/badge/language-English-blue.svg)](./README_EN.md) [![中文](https://img.shields.io/badge/language-中文-red.svg)](./README.md)

## 概述

ZEGO 实时互动 AI Agent（下文简称"互动 AI"或"AI Agent"），通过接入 SDK 及服务端 API，即可快速实现用户与 AI（智能体）进行超低延迟的语音通话、数字人语音通话、播报数字人等互动能力。

本示例演示 Web 端如何接入 AI Agent，包含三个场景入口：

| 入口 | 组件 / 函数 | 说明 |
| --- | --- | --- |
| 语音通话 | `Chat.vue` → `handleLogin('normal')` | 与 AI Agent 进行实时语音对话（双向语音） |
| 数字人通话 | `Chat.vue` → `handleLogin('digitalHuman')` | 与数字人视频对话（双向音视频 + 数字人形象渲染） |
| 播报数字人 | `Chat.vue` → `handleLogin('liveDigitalHuman')` | 单向观看数字人播报，支持主动发送 TTS 文本 |

> ⚠️ 运行客户端前，请先部署并启动 [业务后台示例](https://github.com/ZEGOCLOUD/ai_agent_quick_start_server)，且**后台所用的 AppID 必须与客户端一致**。

## 前提条件

- 已在 [ZEGO 控制台](https://console.zego.im/) 创建项目，并获取有效的 `AppID` 和 `Server URL`，详情请参考 [控制台 - 项目信息](https://doc-zh.zego.im/article/12107)。
- 已联系 ZEGO 技术支持开通 AI Agent / 数字人相关服务权限。
- 数字人场景需要已创建数字人形象，可获取到 `digital_human_id`。

## 环境要求

- Node.js >= 16.14.0
- pnpm（推荐）或 npm
- 现代浏览器（支持 WebRTC，推荐 Chrome）
- 麦克风权限（语音通话 / 数字人通话场景需要）

## 跑通步骤

1. 将 [ai_agent_quick_start](https://github.com/ZEGOCLOUD/ai_agent_quick_start) 克隆或下载到本地。
2. 终端切换到 `web/` 目录，执行 `pnpm install` 安装依赖。
3. 将 `.env.example` 复制为 `.env`，**填入你自己的配置**：
   - `VITE_ZEGO_APP_ID`：ZEGO 控制台获取的 AppID
   - `VITE_ZEGO_SERVER`：ZEGO 控制台配置信息中的 Server 地址
   - `VITE_APP_BASE_URL`：你部署的业务后台地址，例如 `https://your-server.example.com`
   - `VITE_DIGITAL_HUMAN_ID`：数字人形象 ID（数字人 / 播报数字人场景需要）

   > ⚠️ `VITE_ZEGO_APP_ID` 必须与业务后台部署使用的 AppID 保持一致。

4. 执行 `pnpm dev` 启动项目。
5. 浏览器访问 `http://localhost:5173`，选择对应入口体验：
   - **Start AI Audio Call**：语音通话
   - **Start Digital Human Call**：数字人通话（需授权麦克风权限）
   - **Start Live Digital Human**：播报数字人（单向观看，输入文本可让数字人播报）

## 目录结构

```
web/
├── .env.example                        # 环境变量模板（需复制为 .env 并填写配置）
├── index.html                          # HTML 入口
├── package.json                        # 依赖管理
├── vite.config.ts                      # Vite 构建配置
├── tsconfig.json                       # TypeScript 配置
└── src/
    ├── main.ts                         # 应用入口
    ├── App.vue                         # 根组件（包裹 ErrorBoundary + Chat）
    ├── config.ts                       # 配置管理（读取环境变量并校验）
    ├── api/
    │   └── agent.ts                    # 业务后台接口封装（Token / Start / Stop / TTS）
    ├── components/
    │   ├── Chat.vue                    # 主界面：三个场景入口按钮 + 房间信息 + TTS 面板
    │   ├── ChatMessage.vue             # 聊天消息列表组件
    │   ├── RemoteSteamView.vue         # 远程流容器组件（数字人形象展示）
    │   └── ErrorBoundary.vue           # 错误边界组件
    ├── hooks/
    │   ├── useRoom.ts                  # 房间逻辑（SDK 初始化 / 登录 / 推拉流 / 退出）
    │   └── useChat.ts                  # 聊天逻辑（消息收发 / 字幕）
    ├── solution/
    │   └── ExpressManager.ts           # ZegoExpressEngine 封装（单例）
    ├── types/
    │   ├── enum.ts                     # 枚举定义
    │   └── http.ts                     # HTTP 类型定义
    ├── utils/
    │   ├── http.ts                     # HTTP 请求封装（GET / POST）
    │   ├── config-checker.ts           # 配置检查工具
    │   ├── error-handler.ts            # 统一错误处理
    │   └── logger.ts                   # 日志工具
    └── assets/
        └── vue.svg                     # 静态资源
```

## 核心流程

以语音通话为例，接入流程如下（数字人 / 播报数字人同理）：

```
GetZegoToken()                GET  /api/zego-token
        │
        ▼
ExpressManager.loginRoom()    登录 Express 房间
        │
        ▼
Start()                       POST /api/start（数字人用 StartDigitalHuman，播报用 StartLiveDigitalHuman）
        │
        ▼
推流 / 拉流，开始互动
        │
        ▼
结束：Stop()                  POST /api/stop + 登出房间
```

三个场景的差异：

- **语音通话 / 数字人通话**：需要推本地流（`user_stream_id`），请求启动接口时传 `user_id`、`user_stream_id`。
- **播报数字人**：单向观看，不推流、不传 `user_id` / `user_stream_id`，额外支持 `SendAgentInstanceTTS()` 主动播报。

## 依赖说明

网络请求与引擎操作已分层封装，自底向上：

- `utils/http.ts`：HTTP 底层封装，提供 GET / POST，统一处理响应。
- `api/agent.ts`：业务后台接口封装，集中定义所有接口路径，并提供语义化方法（`GetZegoToken` / `Start` / `StartDigitalHuman` / `StartLiveDigitalHuman` / `SendAgentInstanceTTS` / `Stop`）。
- `solution/ExpressManager.ts`：ZegoExpressEngine 单例封装，提供引擎初始化、登录房间、推拉流、音频流创建等能力。
- `hooks/useRoom.ts`：房间逻辑 Hook，编排 SDK 初始化 → 获取 Token → 登录房间 → 推流 → 启动 Agent 的完整流程。
- `hooks/useChat.ts`：聊天逻辑 Hook，处理消息收发和字幕展示。

## 注意事项

- `.env` 中的 `VITE_ZEGO_APP_ID` 必须与业务后台使用的 AppID 一致，否则登录房间会失败。
- `VITE_APP_BASE_URL` 不要带末尾斜杠，代码内部会拼接路径。
- `VITE_DIGITAL_HUMAN_ID` 需使用你账号下有效的数字人 ID，示例中的默认值仅供格式参考。
- 语音通话 / 数字人通话需要麦克风权限；播报数字人为单向观看，无需麦克风。
- 浏览器需支持 WebRTC，推荐使用最新版 Chrome。

## 联系与支持

如有任何问题，请联系 ZEGO 技术支持或访问 [开发者中心](https://docs.zegocloud.com/) 获取更多信息。
