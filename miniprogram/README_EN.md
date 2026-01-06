# Running the Sample Code

[![English](https://img.shields.io/badge/language-English-blue.svg)](./README_EN.md) [![中文](https://img.shields.io/badge/language-中文-red.svg)](./README.md)

## Overview

ZEGOCLOUD Real-time Interactive AI Agent (hereinafter referred to as "Interactive AI" or "AI Agent"), by integrating SDK and server-side APIs, can quickly implement interactive capabilities such as ultra-low-latency IM text/image chat, voice calls, and digital human voice calls between users and AI (intelligent agents), thereby meeting scenarios such as AI companionship, AI customer service, and AI digital human live streaming. ZEGOCLOUD AI Agent supports custom settings for personality, voice, appearance, etc., supports multiple large language models (LLM), text-to-speech services (TTS), and also supports long-term memory, external knowledge bases, and model fine-tuning, thus achieving more perfect intelligent agents.

This article introduces how to run the sample code on the miniprogram platform, connect to the AI Agent test business service, and implement voice conversations with digital humans.

## Prerequisites

- You have already created a project in the [ZEGOCLOUD Console](https://console.zegocloud.com/) and applied for valid `AppID` and `Server URL`.
- You have contacted ZEGOCLOUD technical support to enable Digital human AI service and related interface permissions.
- You have contacted ZEGOCLOUD technical support to create a digital human.

## Environment Requirements

- MiniProgram version supports WebRTC
- Microphone permissions
- ZEGOCLOUD account and AppID (obtained from ZEGOCLOUD Console)

## Running Steps
1. Clone or download [ai_agent_quick_start](https://github.com/ZEGOCLOUD/ai_agent_quick_start) to your local machine
2. Switch to the `/miniprogram` directory in terminal and execute `npm install` to install dependencies
3. Copy `/miniprogram/env.example.ts` to `env.ts` and modify the configuration items
    > - `VITE_ZEGO_APP_ID`(`AppID` of Basic Information) and `VITE_ZEGO_SERVER`(`Server URL` of Basic Configurations) can be viewed in the **Project Configuration** of the [ZEGOCLOUD Console](https://console.zegocloud.com/). ⚠️Note: Must be consistent with the AppID used by the business backend deployment.
    >
    > <img width="3840" height="1916" alt="Image" src="https://github.com/user-attachments/assets/ed06dd61-983e-433a-8984-5c87b1139bb5" />
    >
    > - `VITE_APP_BASE_URL` is your business backend address. Please refer to the [Business Backend Sample Code](https://github.com/ZEGOCLOUD/ai_agent_quick_start_server) to deploy the business backend, then you can obtain it

4. Import the project into the WeChat MiniProgram Development Tool
5. Configure your MiniProgram `AppID` in the **Details - Basic Information** section to start the experience
(MiniProgram needs to configure domain names and enable live-player and live-pusher permissions, please refer to the documentation [Configure WeChat MiniProgram Background](https://doc-zh.zego.im/real-time-video-miniprogram/quick-start/we-chat/implementing-video-call#%E9%85%8D%E7%BD%AE%E5%BE%AE%E4%BF%A1%E5%B0%8F%E7%A8%8B%E5%BA%8F%E5%90%8E%E5%8F%B0))

## Detailed Explanation of Sample Code

<details>
<summary>Click to view detailed explanation</summary>

### Optional Environment Variable Configuration Items

```bash
# Digital human configuration (if not using digital human functionality, you can keep default values)
VITE_DIGITAL_HUMAN_ID=c4b56d5c-db98-4d91-86d4-5a97b507da97
VITE_CONFIG_ID=miniprogram

# Development configuration
VITE_DEBUG=true                           # Whether to enable debug mode
VITE_LOG_LEVEL=debug                      # Log level
VITE_API_TIMEOUT=30000                    # API request timeout
```


### Directory Structure
```
└── miniprogram         # MiniProgram code directory
    ├── api
    │   └── agent       # AI Agent API
    ├── components
    │   ├── zego-player # ZEGO voice playback component
    │   └── zego-pusher # ZEGO voice push component
    ├── config          # Configuration files
    ├── hooks
    │   ├── useChat     # Chat related hooks
    │   └── useRoom     # Room related hooks
    ├── solution
    │   └── ExpressManager # Express SDK management class
    └── utils
        ├── error-handler  # Error handling utility
        ├── http        # HTTP request utility
        ├── logger      # Logging utility
        └── util        # Utility functions
```
</details>