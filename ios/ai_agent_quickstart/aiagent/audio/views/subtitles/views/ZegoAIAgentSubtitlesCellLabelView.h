//
//  ZegoAudioChatCellLabelView.h
//
//  Created by zego on 2024/5/13.
//  Copyright © 2024 Zego. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZegoAIAgentSubtitlesColors.h"

@class ZegoAIAgentSubtitlesMessageModel;

NS_ASSUME_NONNULL_BEGIN

@interface ZegoAIAgentSubtitlesCellLabelView : UILabel

@property(nonatomic, strong) ZegoAIAgentSubtitlesColors *colors;

-(void)setMsgModel:(ZegoAIAgentSubtitlesMessageModel*)msgModel;

@end

NS_ASSUME_NONNULL_END
