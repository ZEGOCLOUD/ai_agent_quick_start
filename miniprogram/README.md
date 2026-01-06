# 跑通示例代码

[![English](https://img.shields.io/badge/language-English-blue.svg)](./README_EN.md) [![中文](https://img.shields.io/badge/language-中文-red.svg)](./README.md)

## 概述

ZEGO 实时互动 AI Agent（下文简称"互动AI"或"AI Agent"），通过接入SDK及服务端 API，即可快速实现用户与 AI（智能体）进行超低延迟的 IM 图文聊天、语音通话、数字人语音通话等互动能力，从而满足 AI 陪伴、AI 客服、AI 数字人直播等场景。 ZEGO AI Agent 支持自定义设置人设、音色、形象等，支持多家大语言模型（LLM）、文本转换语音服务（TTS），且并支持长期记忆、外挂知识库、模型精调，从而实现更完美的智能体。

本文介绍如何跑通小程序平台的示例代码，连接到 AI Agent 测试业务服务，实现与数字人进行语音对话。

## 前提条件

- 已在 [ZEGO 控制台](https://console.zego.im/) 创建项目，并申请有效的 `AppID` 和 `Server URL`，详情请参考 [控制台 - 项目信息](https://doc-zh.zego.im/article/12107)。
- 已联系 ZEGO 技术支持开通数字人 API 服务和相关接口的权限。
- 已联系 ZEGO 技术支持创建数字人。

## 环境要求

- 小程序版本支持 WebRTC
- 麦克风权限
- ZEGO 账号和 AppID（从 ZEGO 控制台获取）

## 跑通步骤
1. 将 [ai_agent_quick_start](https://github.com/ZEGOCLOUD/ai_agent_quick_start)克隆或下载到本地
2. 终端切换到 `/miniprogram` 目录，执行`npm install`安装依赖
3. 将 `/miniprogram/env.example.ts` 复制为 `env.ts`，并修改其中的配置项
    > - `VITE_ZEGO_APP_ID`(基本信息的`AppID`) 和 `VITE_ZEGO_SERVER`(配置信息的`Server 地址`) 可在 [ZEGO 控制台](https://console.zego.im) 的**项目概览**中查看。⚠️注意：必须与业务后台部署使用的AppID保持一致。
    >
    > <img width="3840" height="1916" alt="Image" src="https://github.com/user-attachments/assets/8c7d021f-57fb-43a0-9389-77109f444bb8" />
    >
    > - `VITE_APP_BASE_URL` 为您的业务后台地址，请参考 [业务后台示例代码](https://github.com/ZEGOCLOUD/ai_agent_quick_start_server)部署好业务后台后，即可获取

4. 将项目导入到微信小程序开发工具中
5. 在详情-基本信息中配置您的小程序 `AppID` ，即可开始体验
(小程序需配置域名且开启live-player和live-pusher权限，具体参考文档 [配置微信小程序后台](https://doc-zh.zego.im/real-time-video-miniprogram/quick-start/we-chat/implementing-video-call#%E9%85%8D%E7%BD%AE%E5%BE%AE%E4%BF%A1%E5%B0%8F%E7%A8%8B%E5%BA%8F%E5%90%8E%E5%8F%B0))


## 关于示例代码的详细说明

<details>
<summary>点击查看详细说明</summary>

### 环境变量可选配置项

```bash
# 数字人配置（如果不使用数字人功能可以保持默认值）
VITE_DIGITAL_HUMAN_ID=c4b56d5c-db98-4d91-86d4-5a97b507da97
VITE_CONFIG_ID=miniprogram

# 开发配置
VITE_DEBUG=true                           # 是否开启调试模式
VITE_LOG_LEVEL=debug                      # 日志级别
VITE_API_TIMEOUT=30000                    # API 请求超时时间
```


### 目录结构
```
└── miniprogram         # 小程序代码目录
    ├── api
    │   └── agent       # AI Agent API
    ├── components
    │   ├── zego-player # ZEGO 语音播放组件
    │   └── zego-pusher # ZEGO 语音推流组件
    ├── config          # 配置文件
    ├── hooks
    │   ├── useChat     # 聊天相关的 hooks
    │   └── useRoom     # 房间相关的 hooks
    ├── solution
    │   └── ExpressManager # Express SDK 管理类
    └── utils
        ├── error-handler  # 错误处理工具类
        ├── http        # http 请求工具
        ├── logger      # 日志工具类
        └── util        # 工具类
```
</details>