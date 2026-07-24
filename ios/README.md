# 跑通示例代码

[![English](https://img.shields.io/badge/language-English-blue.svg)](./README_EN.md) [![中文](https://img.shields.io/badge/language-中文-red.svg)](./README.md)

## 概述

ZEGO 实时互动 AI Agent（下文简称"互动 AI"或"AI Agent"），通过接入 SDK 及服务端 API，即可快速实现用户与 AI（智能体）进行超低延迟的语音通话、数字人语音通话、播报数字人等互动能力。

本示例演示 iOS 端如何接入 AI Agent，包含三个场景入口：

| 入口 | 类 | 说明 |
| --- | --- | --- |
| 语音通话 | `ZegoAIAgentAudioViewController` | 与 AI Agent 进行实时语音对话（双向语音） |
| 数字人通话 | `ZegoAIAgentDigitalHumanViewController`（mode = Interactive） | 与数字人视频对话（双向音视频 + 数字人形象渲染） |
| 播报数字人 | `ZegoAIAgentDigitalHumanViewController`（mode = LiveBroadcast） | 单向观看数字人播报，支持主动发送 TTS 文本 |

> ⚠️ 运行客户端前，请先部署并启动 [业务后台示例](https://github.com/ZEGOCLOUD/ai_agent_quick_start_server)，且**后台所用的 AppID 必须与客户端一致**。

## 前提条件

- 已在 [ZEGO 控制台](https://console.zego.im/) 创建项目，并获取有效的 `AppID`，详情请参考 [控制台 - 项目信息](https://doc-zh.zego.im/article/12107)。
- 已联系 ZEGO 技术支持开通 AI Agent / 数字人相关服务权限。
- 数字人场景需要已创建数字人形象，可获取到 `digital_human_id`。

## 环境要求

- Xcode 15 及以上
- iOS 13.0 及以上
- CocoaPods（用于安装依赖库）
- 真机或模拟器，麦克风权限（语音通话 / 数字人通话场景需要）

## 跑通步骤

1. 将 [ai_agent_quick_start](https://github.com/ZEGOCLOUD/ai_agent_quick_start) 克隆或下载到本地。
2. 在文件管理器或 Finder 中将 `ios/ai_agent_quickstart/aiagent/server/ZegoKey.template.m` 重命名为 `ZegoKey.m`。
3. 终端切换到 `ios/` 目录，执行 `pod install` 安装依赖库。完成后会生成 `ai_agent_quickstart.xcworkspace` 文件。
4. 用 Xcode 打开 `ai_agent_quickstart.xcworkspace`。
5. 打开 `ios/ai_agent_quickstart/aiagent/server/ZegoKey.m`，**填入你自己的配置**：
   - `kZegoAppId`：ZEGO 控制台获取的 AppID
   - `kBaseURL`：你部署的业务后台地址，例如 `https://your-server.example.com`
   - `kDigitalHumanId`：数字人形象 ID（数字人 / 播报数字人场景需要）

   > ⚠️ `kZegoAppId` 必须与业务后台部署使用的 AppID 保持一致。

6. 连接设备或选择模拟器，点击 Run 运行。
7. 在首页选择对应入口体验：
   - **StartAIAudioCall**：语音通话
   - **StartDigitalHumanCall**：数字人通话（需授权麦克风权限）
   - **StartLiveDigitalHuman**：播报数字人（单向观看，输入文本可让数字人播报）

## 目录结构

```
ios/ai_agent_quickstart/
├── AppDelegate.h/m                     # 应用程序代理
├── SceneDelegate.h/m                   # 场景代理（加载首页控制器）
├── ZegoAIAgentHomeViewController.h/m   # 首页：三个场景入口按钮
├── main.m                              # 程序入口
└── aiagent/                            # AI Agent 核心模块
    ├── audio/                          # 音频模块
    │   ├── ZegoAIAgentAudioViewController.h/m     # 语音通话场景
    │   ├── ZegoAIAgentAudioEventHandler.h          # 音频事件处理协议
    │   └── subtitles/                             # 字幕组件
    │       ├── ZegoAIAgentSubtitlesTableView.h/m  # 字幕列表视图
    │       ├── core/                              # 字幕核心（颜色、定义）
    │       ├── views/                             # 字幕 UI（Cell、Label、Model）
    │       └── protocol/                          # 字幕协议（事件、消息分发）
    ├── digital_human/                 # 数字人模块
    │   ├── ZegoAIAgentDigitalHumanViewController.h/m  # 数字人场景（Interactive / LiveBroadcast 两种模式）
    │   └── ZegoAIAgentDigitalHumanEventHandler.h      # 数字人事件处理协议
    └── server/                        # 后台服务接口
        ├── ZegoAIAgentServiceAPI.h/m               # 服务 API 封装（音频 / 数字人 / 播报 / TTS）
        ├── ZegoKey.h/m                             # 密钥配置（需改这里）
        └── protocol/                               # 请求/响应模型
            ├── ZegoAIGetTokenRequest.h/m
            ├── ZegoAIGetTokenResponse.h/m
            └── ZegoAIServiceCommonResponse.h/m
```

## 核心流程

以语音通话为例，接入流程如下（数字人 / 播报数字人同理）：

```
[ZegoAIAgentServiceAPI getTokenWithCompletion:]    GET  /api/zego-token
        │
        ▼
初始化引擎 / 登录 Express 房间
        │
        ▼
[startAudioWithCompletion:]                         POST /api/start
        │                                            （数字人用 startDigitalHuman，播报用 startLiveDigitalHuman）
        ▼
推流 / 拉流，开始互动
        │
        ▼
结束：[stopAudioWithCompletion:]                    POST /api/stop + 登出房间
```

三个场景的差异：

- **语音通话 / 数字人通话**：需要推本地流（`user_stream_id`），请求启动接口时传 `user_id`、`user_stream_id`。
- **播报数字人**：单向观看，不推流、不传 `user_id` / `user_stream_id`，额外支持 `[sendAgentInstanceTTSWithText:completion:]` 主动播报。

## 依赖说明

服务接口与引擎操作已分层封装：

- `ZegoAIAgentServiceAPI`：业务后台接口封装（单例），集中提供 `startAudio` / `stopAudio` / `startDigitalHuman` / `stopDigitalHuman` / `startLiveDigitalHuman` / `stopLiveDigitalHuman` / `sendAgentInstanceTTS` / `getToken` / `ensureLogoutRoom` 等方法。
- `ZegoAIAgentAudioViewController`：语音通话场景控制器，处理用户交互、权限请求和音频流程管理。
- `ZegoAIAgentDigitalHumanViewController`：数字人场景控制器，通过 `mode` 属性区分 `Interactive`（双向通话）和 `LiveBroadcast`（单向播报）两种模式。
- `ZegoAIAgentSubtitlesTableView`：字幕显示组件，实时展示对话内容（用户输入和 AI 回复）。
- `ZegoKey`：配置类，通过 `kZegoAppId`、`kBaseURL`、`kDigitalHumanId` 等常量集中管理接入参数。

## 注意事项

- `ZegoKey.m` 中的 `kZegoAppId` 必须与业务后台使用的 AppID 一致，否则登录房间会失败。
- `kBaseURL` 不要带末尾斜杠，代码内部会拼接路径。
- `kDigitalHumanId` 需使用你账号下有效的数字人 ID，示例中的默认值仅供格式参考。
- 语音通话 / 数字人通话需要麦克风权限；播报数字人为单向观看，无需麦克风。
- 首次运行前必须先执行 `pod install`，用 `xcworkspace` 打开而非 `xcodeproj`。

## 联系与支持

如有任何问题，请联系 ZEGO 技术支持或访问 [开发者中心](https://docs.zegocloud.com/) 获取更多信息。
