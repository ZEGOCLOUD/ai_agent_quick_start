//
//  ZegoAIAgentAudioViewForegroundView.m
//
//  Created on 2024/7/15.
//  Copyright © 2024 Zego. All rights reserved.
//

#import "ZegoAIAgentAudioViewForegroundView.h"

#import <Masonry/Masonry.h>

#import "ZegoAIAgentSubtitlesTableView.h"
#import "ZegoAIAgentSubtitlesMessageDispatcher.h"

@interface ZegoAIAgentAudioViewForegroundView()<ZegoAIAgentSubtitlesEventHandler>

// 智能体字幕
@property (nonatomic, strong, readwrite) ZegoAIAgentSubtitlesTableView *chatView;

@end

@implementation ZegoAIAgentAudioViewForegroundView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // 注册事件
        [self registerEventHandler];
        
        // 初始化字幕控件, 如果需要开启字幕，请注释下面这行代码
//        [self setupSubtitles];
    }
    return self;
}

- (void)dealloc {
    // 反注册事件
    [self unregisterEventHandler];
}

- (void)setupSubtitles {
    // 添加聊天视图 - 占据屏幕下半部分
    CGRect chatFrame = CGRectMake(0,
                                 self.bounds.size.height / 2,
                                 self.bounds.size.width,
                                 self.bounds.size.height / 2);
    self.chatView = [[ZegoAIAgentSubtitlesTableView alloc] initWithFrame:chatFrame style:UITableViewStylePlain];
    
    [self addSubview:self.chatView];
    
    // 使用Masonry添加约束
    [self.chatView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self);
        make.height.equalTo(self.mas_height).multipliedBy(0.5);
    }];
}

#pragma mark - ZegoAIAgentSubtitlesEventHandler

- (void)registerEventHandler {
    [[ZegoAIAgentSubtitlesMessageDispatcher sharedInstance] registerEventHandler:self];
}

- (void)unregisterEventHandler {
    [[ZegoAIAgentSubtitlesMessageDispatcher sharedInstance] unregisterEventHandler:self];
}

- (void)onRecvAsrChatMsg:(ZegoAIAgentAudioSubtitlesMessage *)message {
    [self.chatView handleRecvAsrMessage:message];
}

- (void)onRecvLLMChatMsg:(ZegoAIAgentAudioSubtitlesMessage *)message {
    [self.chatView handleRecvLLMMessage:message];
}

@end 
