# AI Agent Web Quickstart

## 项目介绍

本项目是一个基于 ZEGO Express SDK 的 AI Agent Web 快速启动示例，展示了如何在 Web 应用中集成和使用 AI Agent 功能。通过本示例，您可以快速了解和实现智能体语音通话功能。

⚠️ 在运行客户端前，请先启动[您的业务后台](https://github.com/ZEGOCLOUD/ai_agent_quick_start_server/tree/main)，分支需和客户端匹配
## 环境要求

- 现代浏览器（支持 WebRTC）
- 麦克风权限
- ZEGO 账号和 AppID（从 ZEGO 控制台获取）

## 快速开始

### 1. 安装依赖

```bash
pnpm install
```

### 2. 环境配置

修改 `src/config.ts` 文件，配置 appId 和 server。
修改 .env 文件，配置 VITE_APP_BASE_URL 业务后台地址。

### 3. 启动项目

```bash
pnpm dev
```

### 4. 目录结构
```
├── lib                 # 第三方库
└── src
    ├── api
    │   └── agent       # AI Agent API
    ├── components
    │   ├── VoiceChat  # 语音聊天组件
    │   ├── ChatMessage # 聊天消息组件
    │   └── RemoteSteamView # 远程流容器组件
    ├── hooks
    │   └── useChat     # 聊天相关的 hooks
    │   └── useRoom     # 房间相关的 hooks
    ├── solution
    │   └── ExpressManager # Express SDK 管理类
    ├── utils
    │   └── http        # http 请求工具
    └── config          # 配置文件
```
