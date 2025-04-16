# AI Agent Web Quickstart

## 项目介绍

本项目是一个基于 ZEGO Express SDK 的 AI Agent Web 快速启动示例，展示了如何在 Web 应用中集成和使用 AI Agent 功能。通过本示例，您可以快速了解和实现智能体的注册、创建实例、实时语音交互等核心功能。

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

修改 `src/config.ts` 文件，配置 AppID 和 AppSign等信息。

### 3. 启动项目

```bash
pnpm dev
```

## 核心功能

### 1. 初始化配置

- 初始化 ZegoExpressEngine SDK
- 配置 AppID 和服务器参数
- 检查系统要求和权限

### 2. 智能体生命周期管理

#### 2.1 注册智能体
- 调用 RegisterAgent API 创建智能体
- 配置智能体参数（名称、LLM配置、TTS配置等）

#### 2.2 创建智能体实例
- 调用 CreateAgentInstance API
- 配置 RTC 相关参数（房间ID、流ID等）
- 设置用户和智能体的音频流

#### 2.3 实时语音交互
- 进入 RTC 房间
- 创建和推送本地音频流
- 监听和处理远端流事件

#### 2.4 资源清理
- 销毁本地音频流
- 退出房间
- 删除智能体实例

## 注意事项

- Token 生成建议在服务端进行
- 不建议在客户端放置密钥，本文仅用于演示

## 技术支持

如果您在使用过程中遇到问题，请参考以下资源：

- [ZEGO Express SDK 文档](https://doc-zh.zego.im/article/5054)
- [技术支持](https://www.zego.im)