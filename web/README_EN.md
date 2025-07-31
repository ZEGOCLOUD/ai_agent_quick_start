# Running the Sample Code

[![English](https://img.shields.io/badge/language-English-blue.svg)](./README_EN.md) [![中文](https://img.shields.io/badge/language-中文-red.svg)](./README.md)

## Overview

ZEGOCLOUD Real-time Interactive AI Agent (hereinafter referred to as "Interactive AI" or "AI Agent"), by integrating SDK and server-side APIs, can quickly implement interactive capabilities such as ultra-low-latency IM text/image chat, voice calls, and digital human voice calls between users and AI (intelligent agents), thereby meeting scenarios such as AI companionship, AI customer service, and AI digital human live streaming. ZEGOCLOUD AI Agent supports custom settings for personality, voice, appearance, etc., supports multiple large language models (LLM), text-to-speech services (TTS), and also supports long-term memory, external knowledge bases, and model fine-tuning, thus achieving more perfect intelligent agents.

This article introduces how to run the sample code on the iOS platform, connect to the AI Agent test business service, and implement voice conversations with digital humans.

## Prerequisites

- You have already created a project in the [ZEGOCLOUD Console](https://console.zegocloud.com/) and applied for valid `AppID` and `Server URL`.
- You have contacted ZEGOCLOUD technical support to enable Digital human AI service and related interface permissions.
- You have contacted ZEGOCLOUD technical support to create a digital human.

## Environment Requirements

- Modern browser (supports WebRTC)
- Microphone permissions
- ZEGOCLOUD account and AppID (obtained from ZEGOCLOUD Console)

## Running Steps
1. Clone or download [ai_agent_quick_start](https://github.com/ZEGOCLOUD/ai_agent_quick_start) to your local machine
2. Switch to the `/web` directory in terminal and execute `pnpm install` to install dependencies
3. Copy `.env.example` to `.env` and modify the configuration items
    > - `VITE_ZEGO_APP_ID`(`AppID` of Basic Information) and `VITE_ZEGO_SERVER`(`Server URL` of Basic Configurations) can be viewed in the **Project Configuration** of the [ZEGOCLOUD Console](https://console.zegocloud.com/). ⚠️Note: Must be consistent with the AppID used by the business backend deployment.
    >
    > <img width="3840" height="1916" alt="Image" src="https://github.com/user-attachments/assets/ed06dd61-983e-433a-8984-5c87b1139bb5" />
    >
    > - `VITE_APP_BASE_URL` is your business backend address. Please refer to the [Business Backend Sample Code](https://github.com/ZEGOCLOUD/ai_agent_quick_start_server) to deploy the business backend, then you can obtain it

4. Execute `pnpm dev` to start the project
5. Visit `http://localhost:5173` in your browser to start the experience

## Detailed Explanation of Sample Code

<details>
<summary>Click to view detailed explanation</summary>

### Optional Environment Variable Configuration Items

```bash
# Digital human configuration (if not using digital human functionality, you can keep default values)
VITE_DIGITAL_HUMAN_ID=20be9bfb-ef6b-4d63-8c3b-1f20077599c5
VITE_CONFIG_ID=web

# Development configuration
VITE_DEBUG=true                           # Whether to enable debug mode
VITE_LOG_LEVEL=debug                      # Log level
VITE_API_TIMEOUT=30000                    # API request timeout
```


### Directory Structure
```
├── lib                 # Third-party libraries
└── src
    ├── api
    │   └── agent       # AI Agent API
    ├── components
    │   ├── VoiceChat  # Voice chat component
    │   ├── ChatMessage # Chat message component
    │   └── RemoteSteamView # Remote stream container component
    ├── hooks
    │   └── useChat     # Chat-related hooks
    │   └── useRoom     # Room-related hooks
    ├── solution
    │   └── ExpressManager # Express SDK management class
    ├── utils
    │   └── http        # HTTP request utilities
    └── config          # Configuration files
```
</details>