//
//  ZegoAIAgentStatusView.h
//
//  Created by Zego 2024/4/11.
//  Copyright © 2024 Zego. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ZegoAIAgentSubtitlesDefines.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * @class ZegoAIAgentStatusView
 * @brief AI智能体状态显示视图
 *
 * 该类负责显示AI智能体当前的状态信息，包括连接状态、处理状态等。
 * 它提供视觉反馈，让用户了解当前智能体的工作状态，增强用户体验。
 * 包含状态文本和可能的状态指示图标，以直观方式展示状态变化。
 */
@interface ZegoAIAgentStatusView : UIView

/**
 * 更新状态文本
 * @param statusText 要显示的状态文本，如"已连接"、"正在处理"、"等待回应"等
 *
 * 此方法用于更新视图显示的状态文本，反映AI智能体的当前状态
 */
- (void)updateStatusText:(NSString *)statusText;

/**
 * 根据聊天状态更新显示文本
 * @param state 聊天状态枚举值，定义在ZegoAIAgentSubtitlesDefines.h中
 *
 * 此方法根据预定义的会话状态枚举自动设置相应的状态文本，
 * 使状态显示更加标准化，并能根据不同的会话阶段显示适当的状态信息
 */
- (void)updateTextByState:(ZegoAIAgentSessionState)state;

@end

NS_ASSUME_NONNULL_END
