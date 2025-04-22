//
//  ZegoAIAgentSubtitlesEventHandler.h
//  ai_agent_uikit
//
//  Created on 2024/7/15.
//  Copyright © 2024 Zego. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ZegoAIAgentSubtitlesDefines.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * @protocol ZegoAIAgentSubtitlesEventHandler
 * @brief 字幕事件处理协议
 *
 * 该协议定义了处理字幕相关事件的方法集合，实现此协议的类可以接收和响应
 * 字幕组件产生的各类事件，包括状态变化、消息更新等。作为字幕组件与外部
 * 系统通信的桥梁，确保字幕界面与业务逻辑的解耦和灵活交互。
 */
@protocol ZegoAIAgentSubtitlesEventHandler <NSObject>

/**
 * 接收到聊天状态变更
 * @param state 聊天状态
 */
- (void)onRecvChatStateChange:(ZegoAIAgentSessionState)state;

/**
 * 接收到ASR聊天消息
 * @param message 聊天消息
 */
- (void)onRecvAsrChatMsg:(ZegoAIAgentAudioSubtitlesMessage*)message;

/**
 * 接收到LLM聊天消息
 * @param message 聊天消息
 */
- (void)onRecvLLMChatMsg:(ZegoAIAgentAudioSubtitlesMessage*)message;

/**
 * 接收到Express实验性API内容
 * @param content API内容
 */
- (void)onExpressExperimentalAPIContent:(NSString *)content;

@end

NS_ASSUME_NONNULL_END 
