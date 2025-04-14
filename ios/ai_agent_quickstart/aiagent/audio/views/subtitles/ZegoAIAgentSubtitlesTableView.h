//
//  ZegoAIAgentSubtitlesTableView.h
//
//  Created by Zego 2024/4/11.
//  Copyright © 2024 Zego. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ZegoAIAgentSubtitlesMessageModel.h"
#import "ZegoAIAgentSubtitlesColors.h"
#import "ZegoAIAgentSubtitlesDefines.h"

@protocol ZegoAIAgentSubtitlesEventHandler;

NS_ASSUME_NONNULL_BEGIN

/**
 * @class ZegoAIAgentSubtitlesTableView
 * @brief 智能体对话字幕表格视图
 *
 * 该类负责显示用户与AI智能体之间的对话内容，以表格形式呈现对话历史。
 * 它支持实时更新，能够在用户说话和AI回复时即时显示对应的字幕内容。
 * 提供清晰的视觉区分以区分用户输入和AI回复，并支持自动滚动到最新消息。
 * 
 * 字幕表格是AI语音对话体验的关键组件，它为用户提供视觉反馈，
 * 特别是在嘈杂环境或需要回顾对话内容时非常有用。
 */
@interface ZegoAIAgentSubtitlesTableView : UITableView

@property (nonatomic, strong) ZegoAIAgentSubtitlesColors *colors;

-(void)handleRecvAsrMessage:(ZegoAIAgentAudioSubtitlesMessage*)msgDict;
-(void)handleRecvLLMMessage:(ZegoAIAgentAudioSubtitlesMessage*)msgDict;
@end

NS_ASSUME_NONNULL_END
