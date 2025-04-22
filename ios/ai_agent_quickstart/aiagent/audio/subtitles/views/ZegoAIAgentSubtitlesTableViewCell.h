//
//  ZegoAudioChatTableViewCell.h
//
//  Created by zego on 2024/5/13.
//  Copyright © 2024 Zego. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ZegoAIAgentSubtitlesColors.h"

#define CELL_TOP_MARGIN 16

@class ZegoAIAgentSubtitlesMessageModel;

NS_ASSUME_NONNULL_BEGIN

@interface ZegoAIAgentSubtitlesTableViewCell : UITableViewCell
@property (nonatomic, strong) ZegoAIAgentSubtitlesMessageModel *msgModel;
@property (nonatomic, assign) BOOL isSelected;
@property (nonatomic, strong) ZegoAIAgentSubtitlesColors *colors;
@end

NS_ASSUME_NONNULL_END
