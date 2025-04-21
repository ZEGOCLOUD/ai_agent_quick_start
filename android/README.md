
# ZEGO AI Agent QuickStart

## 项目概述

ZEGO AI Agent QuickStart 是一个 Android 示例项目，旨在帮助开发者快速集成和使用 ZEGO AI Agent 相关功能。该项目展示了如何注册 AI Agent、创建 AI Agent 实例、进行语音交互等基本流程，为开发者提供了清晰的实现参考。

## 文件目录

```
QuickStart/
├── app/                                # 应用主模块
│   ├── src/
│   │   ├── main/
│   │   │   ├── java/
│   │   │   │   └── im/zego/aiagent/express/quickstart/  # 代码包路径
│   │   │   │       ├── MainActivity.java                # 主活动，处理初始化和权限
│   │   │   │       ├── VoiceChatActivity.java           # 语音聊天活动
│   │   │   │       └── ZegoQuickStartApi.java           # API 封装类
│   │   │   ├── res/                                     # 资源文件
│   │   │   │   ├── layout/                              # 布局文件
│   │   │   │   │   ├── activity_main.xml                # 主界面布局
│   │   │   │   │   └── activity_voice_chat.xml          # 语音聊天界面布局
│   │   │   │   ├── drawable/                            # 图像资源
│   │   │   │   └── values/                              # 值资源
│   │   │   │       ├── colors.xml                       # 颜色定义
│   │   │   │       └── strings.xml                      # 字符串资源
│   │   │   └── AndroidManifest.xml                      # 应用清单
│   ├── build.gradle                                     # 应用模块构建脚本
├── gradle/                                              # Gradle 包装器
├── build.gradle                                         # 项目构建脚本
├── settings.gradle                                      # 项目设置
└── README.md                                            # 项目说明文档
```

## 流程图

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│             │     │             │     │             │
│  应用启动   │────▶│ 申请录音权限 │────▶│ 注册AI Agent │
│             │     │             │     │             │
└─────────────┘     └─────────────┘     └──────┬──────┘
                                                │
                                                ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│             │     │             │     │             │
│ 语音交互    │◀────│ 创建AI实例   │◀────│ 登录语音房间 │
│             │     │             │     │             │
└─────────────┘     └─────────────┘     └─────────────┘
```

## 组件介绍

### 核心组件

#### MainActivity
- **功能**: 应用入口点，负责申请录音权限和注册 AI Agent
- **关键方法**:
  - `onCreate()`: 初始化界面并设置点击事件监听
  - `requestPermissionLauncher`: 处理录音权限申请结果
  - `registerAIAgent()`: 调用 ZegoQuickStartApi 注册 AI Agent，成功后跳转到语音聊天界面

#### ZegoQuickStartApi
- **功能**: 封装与 ZEGO 服务端的 HTTP 请求
- **关键方法**:
  - `registerAgent()`: 注册 AI Agent
  - `createAgentInstance()`: 创建 AI Agent 实例
  - `deleteAgentInstance()`: 删除 AI Agent 实例
  - `getZegoToken()`: 获取 ZEGO Token

#### VoiceChatActivity
- **功能**: 提供与 AI Agent 的语音聊天功能
- **关键方法**:
  - `onCreate()`: 初始化语音聊天界面
  - `initExpressSDK()`: 初始化 ZEGO Express SDK
  - `loginRoom()`: 登录语音聊天房间
  - `createAgentInstance()`: 创建 AI Agent 实例
  - `deleteAgentInstance()`: 删除 AI Agent 实例
  - `requestZegoToken()`: 请求 ZEGO Token
  - `onVoiceChatReady()`: 语音聊天准备就绪的回调

### 辅助工具

#### 字符串生成工具
- `generateRoomID()`: 根据 agentId 生成房间 ID
- `generateUserStreamID()`: 生成用户流 ID
- `generateAgentStreamID()`: 生成 AI Agent 流 ID

## 快速开始

1. 克隆项目到本地
2. 在 Android Studio 中打开项目
3. 在 VoiceChatActivity.java 中配置您的 appId、userId 和 userName
4. 构建并运行项目
5. 点击主界面上的"开始语音聊天"按钮，授予录音权限后即可进入语音聊天界面

## 注意事项

- 使用前请确保已注册 ZEGO 开发者账号并创建应用
- 运行时需要麦克风权限，请确保授予
- 确保设备有稳定的网络连接
- 本示例使用了 ZEGO Express SDK，请确保了解其基本用法

## 技术支持

如有任何问题，请联系 ZEGO 技术支持或访问[开发者中心](https://docs.zegocloud.com/)获取更多信息。