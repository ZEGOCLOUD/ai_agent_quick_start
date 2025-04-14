//
//  ZegoAIAudioChatForeground.h
//
//  Created by Zego 2024/4/11.
//  Copyright © 2024 Zego. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZegoAIAgentSubtitlesEventHandler.h"

@class ZegoAIAgentSubtitlesTableView;

NS_ASSUME_NONNULL_BEGIN

/**
 * @class ZegoAIAgentAudioSubtitlesForegroundView
 * @brief AI音频对话界面的前景视图
 *
 * 该类负责显示音频对话的前景UI元素，包括字幕、状态指示和交互控件。
 * 实现了ZegoAIAgentSubtitlesEventHandler协议，用于处理字幕相关的事件和更新。
 * 作为音频对话界面的主要可视部分，它包含了会话状态显示、字幕表格等UI组件。
 */
@interface ZegoAIAgentAudioSubtitlesForegroundView : UIView <ZegoAIAgentSubtitlesEventHandler>

/**
 * 更新状态文本
 * @param statusText 状态文本，如"已连接"、"正在处理"等
 * 
 * 此方法用于更新界面上显示的当前会话状态信息，反映AI智能体连接和处理状态
 */
- (void)updateStatusText:(NSString *)statusText;

@end

NS_ASSUME_NONNULL_END 
