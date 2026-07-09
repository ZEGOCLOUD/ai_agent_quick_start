# 跑通示例代码

## 概述

ZEGO 实时互动 AI Agent（下文简称"互动 AI"或"AI Agent"），通过接入 SDK 及服务端 API，即可快速实现用户与 AI（智能体）进行超低延迟的语音通话、数字人语音通话、播报数字人等互动能力。

本示例演示 Android 端如何接入 AI Agent，包含三个场景入口：

| 入口 | 类 | 说明 |
| --- | --- | --- |
| 语音通话 | `voice.VoiceChatActivity` | 与 AI Agent 进行实时语音对话（双向语音） |
| 数字人通话 | `video.DigitalHumanActivity` | 与数字人视频对话（双向音视频 + 数字人形象渲染） |
| 播报数字人 | `video.LiveDigitalHumanActivity` | 单向观看数字人播报，支持主动发送 TTS 文本 |

> ⚠️ 运行客户端前，请先部署并启动 [业务后台示例](https://github.com/ZEGOCLOUD/ai_agent_quick_start_server)，且**后台所用的 AppID 必须与客户端一致**。

## 前提条件

- 已在 [ZEGO 控制台](https://console.zego.im/) 创建项目，并获取有效的 `AppID`，详情请参考 [控制台 - 项目信息](https://doc-zh.zego.im/article/12107)。
- 已联系 ZEGO 技术支持开通 AI Agent / 数字人相关服务权限。
- 数字人场景需要已创建数字人形象，可获取到 `digital_human_id`。

## 环境要求

- Android Studio
- minSdkVersion 26（Android 8.0）及以上
- 真机或模拟器，麦克风权限（语音/数字人通话场景需要）

## 跑通步骤

1. 将 [ai_agent_quick_start](https://github.com/ZEGOCLOUD/ai_agent_quick_start) 克隆或下载到本地。
2. Android Studio 打开 `android/QuickStart` 目录。
3. 打开 `Constant.java`，**填入你自己的配置**（文件内已用 `TODO` 标注）：
   - `appId`：ZEGO 控制台获取的 AppID
   - `BASE_URL`：你部署的业务后台地址，例如 `https://your-server.example.com`
   - `digital_human_id`：数字人形象 ID（数字人 / 播报数字人场景需要）
4. 连接设备，点击 Run 运行。
5. 选择对应入口体验：
   - **StartAudioAgentCall**：语音通话
   - **StartDigitalHumanCall**：数字人通话（需授录音权限）
   - **StartLiveDigitalHumanCall**：播报数字人（单向观看，输入文本可让数字人播报）

## 目录结构

```
QuickStart/app/src/main/java/im/zego/aiagent/express/quickstart/
├── MainActivity.java                    # 首页：三个场景入口按钮
├── Constant.java                        # 配置中心：AppID / 业务后台地址 / 数字人 ID（需改这里）
├── voice/
│   ├── VoiceChatActivity.java           # 语音通话场景
│   ├── AIChatListView.java              # 聊天消息列表控件
│   └── AudioChatMessageParser.java      # 语音消息解析
├── video/
│   ├── DigitalHumanActivity.java        # 数字人通话场景
│   └── LiveDigitalHumanActivity.java    # 播报数字人场景
└── util/
    ├── QuickStartApi.java               # 业务后台接口封装（路径常量 + 各接口方法）
    ├── HttpHelper.java                  # HTTP 底层封装（GET / POST / URL 校验）
    ├── ExpressHelper.java               # ZegoExpressEngine 初始化/销毁/登录/音频配置
    └── StringUtil.java                  # 工具方法
```

## 核心流程

以语音通话为例，接入流程如下（数字人 / 播报数字人同理）：

```
QuickStartApi.getZegoToken()       GET  /api/zego-token
        │
        ▼
ExpressHelper.loginRoom()          登录 Express 房间
        │
        ▼
QuickStartApi.start()              POST /api/start（数字人用 startDigitalHuman，播报用 startLiveDigitalHuman）
        │
        ▼
推流 / 拉流，开始互动
        │
        ▼
结束：QuickStartApi.stop()         POST /api/stop + 登出房间
```

三个场景的差异：

- **语音通话 / 数字人通话**：需要推本地流（`user_stream_id`），请求启动接口时传 `user_id`、`user_stream_id`。
- **播报数字人**：单向观看，不推流、不传 `user_id` / `user_stream_id`，额外支持 `QuickStartApi.sendAgentInstanceTTS()` 主动播报。

## 依赖说明

网络请求与引擎操作已分层封装在 `util` 下，自底向上：

- `HttpHelper`：HTTP 底层封装，提供 GET / POST，回调只回原始响应体，由调用方自行解析。
- `QuickStartApi`：业务后台接口封装，集中定义所有接口路径常量（`PATH_*`），并提供语义化方法（`getZegoToken` / `start` / `stop` 等）。
- `ExpressHelper`：`ZegoExpressEngine` 封装，提供引擎创建、销毁、登录房间、音频配置。

## 注意事项

- `Constant.java` 中的 `appId` 必须与业务后台使用的 AppID 一致，否则登录房间会失败。
- `BASE_URL` 不要带末尾斜杠，代码内部会拼接路径。
- `digital_human_id` 需使用你账号下有效的数字人 ID，示例中的默认值仅供格式参考。
- 语音通话 / 数字人通话需要麦克风权限；播报数字人为单向观看，无需麦克风。

## 联系与支持

如有任何问题，请联系 ZEGO 技术支持或访问 [开发者中心](https://docs.zegocloud.com/) 获取更多信息。
