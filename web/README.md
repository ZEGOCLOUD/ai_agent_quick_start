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

### 2. 快速配置

**第一次使用请按以下步骤配置：**

1. **创建配置文件**
   ```bash
   # 创建 .env 文件
   touch .env
   ```

2. **填写基本配置**
   
   将以下内容复制到 `.env` 文件中，并替换为您的实际配置：
   ```bash
   # 必需配置
   VITE_ZEGO_APP_ID=your_app_id
   VITE_ZEGO_SERVER=your_server_url
   VITE_APP_BASE_URL=your_server_url
   # 数字人体验形象ID
   VITE_DIGITAL_HUMAN_ID=20be9bfb-ef6b-4d63-8c3b-1f20077599c5
   
   # 开发配置
   VITE_DEBUG=true
   ```

3. **获取 ZEGO 配置**
   - 访问 [ZEGO 控制台](https://console.zego.im/)
   - 创建项目并获取 AppID 和服务器地址
   - 更新 `.env` 文件中的对应配置

4. **验证配置**
   ```bash
   # 启动项目，配置检查工具会自动验证配置
   pnpm dev
   ```

### 3. 详细环境配置

本项目使用环境变量进行配置管理，支持多环境部署。

#### 3.1 创建环境变量文件

**方法一：复制示例文件**
```bash
cp .env.example .env
```

**方法二：手动创建**

如果没有 `.env.example` 文件，请手动创建 `.env` 文件并参考下面的配置模板。

#### 3.2 配置必需的环境变量

在 `.env` 文件中配置以下必需参数：

```bash
# ZEGO Express SDK 配置
VITE_ZEGO_APP_ID=your_app_id              # 从 ZEGO 控制台获取
VITE_ZEGO_SERVER=your_server_url          # ZEGO 服务器地址

# 业务后台服务地址
VITE_APP_BASE_URL=http://localhost:3000   # 需要先启动对应的后台服务
```

#### 3.3 可选配置项

```bash
# 数字人配置（如果不使用数字人功能可以保持默认值）
VITE_DIGITAL_HUMAN_ID=20be9bfb-ef6b-4d63-8c3b-1f20077599c5
VITE_CONFIG_ID=web

# 开发配置
VITE_DEBUG=true                           # 是否开启调试模式
VITE_LOG_LEVEL=debug                      # 日志级别
VITE_API_TIMEOUT=30000                    # API 请求超时时间
```

#### 3.4 获取 ZEGO 配置

1. 登录 [ZEGO 控制台](https://console.zego.im/)
2. 创建项目并获取 AppID
3. 获取对应的服务器地址

### 4. 启动项目

```bash
pnpm dev
```

### 5. 目录结构
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

## 配置管理

### 环境变量说明

本项目采用环境变量进行配置管理，提供更好的安全性和部署灵活性：

- ✅ **安全性**：敏感信息不会被提交到代码仓库
- ✅ **多环境支持**：开发、测试、生产环境配置分离
- ✅ **CI/CD 友好**：可通过环境变量注入配置
- ✅ **团队协作**：团队成员可使用不同配置而不影响代码

### 配置验证

项目启动时会自动验证配置的有效性：

- AppID 必须是有效的正整数
- 服务器地址必须是有效的 WebSocket URL
- API 地址必须是有效的 HTTP URL
- 超时时间必须是正数

## 故障排除

### 常见配置问题

1. **缺少环境变量**
   ```
   错误：缺少必需的环境变量: VITE_ZEGO_APP_ID
   解决：检查 .env 文件是否存在且包含必需的环境变量
   ```

2. **AppID 格式错误**
   ```
   错误：ZEGO AppID 必须是一个正整数
   解决：确保 VITE_ZEGO_APP_ID 是有效的数字
   ```

3. **服务器地址格式错误**
   ```
   错误：ZEGO 服务器地址必须是有效的 WebSocket URL
   解决：确保地址以 wss:// 或 ws:// 开头
   ```

4. **API 地址无法访问**
   ```
   错误：API 基础地址必须是有效的 URL
   解决：确保后台服务已启动且地址正确
   ```

### 配置检查工具

项目内置了配置检查工具，在开发模式下启动时会自动检查配置：

- ✅ **自动验证**：启动时自动检查配置完整性
- ⚠️ **警告提示**：显示配置警告和建议
- 🚨 **错误阻止**：配置错误时阻止应用启动
- 💡 **智能建议**：根据环境提供配置建议

配置检查结果示例：
```
📋 配置检查结果
══════════════════════════════════════════════════
✅ 配置验证通过

💡 建议:
  1. 开发环境建议开启调试模式 (VITE_DEBUG=true)
  2. 如果需要使用数字人功能，请设置 VITE_DIGITAL_HUMAN_ID
══════════════════════════════════════════════════
```

### 环境变量模板

完整的 `.env` 文件模板：

```bash
# ================================
# AI Agent Web 快速启动配置
# ================================

# ----- 必需配置 -----
# ZEGO Express SDK AppID (从 ZEGO 控制台获取)
VITE_ZEGO_APP_ID=your_app_id

# ZEGO 服务器地址
VITE_ZEGO_SERVER=your_server_url

# 业务后台服务地址 (需要先启动对应的后台服务)
VITE_APP_BASE_URL=http://localhost:3000

# ----- 可选配置 -----
# 数字人ID (如果不使用数字人功能可以保持默认值)
VITE_DIGITAL_HUMAN_ID=20be9bfb-ef6b-4d63-8c3b-1f20077599c5

# 配置ID
VITE_CONFIG_ID=web

# ----- 开发配置 -----
# 是否开启调试模式
VITE_DEBUG=true

# 日志级别 (debug, info, warn, error)
VITE_LOG_LEVEL=debug

# API 请求超时时间 (毫秒)
VITE_API_TIMEOUT=30000
```
