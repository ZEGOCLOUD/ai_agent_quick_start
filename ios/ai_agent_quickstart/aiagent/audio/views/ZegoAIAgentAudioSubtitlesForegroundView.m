//
//  ZegoAIAudioChatForeground.m
//
//  Created on 2024/7/15.
//  Copyright © 2024 Zego. All rights reserved.
//

#import "ZegoAIAgentAudioSubtitlesForegroundView.h"
#import "ZegoAIAgentStatusView.h"
#import "ZegoAIAgentSubtitlesTableView.h"
#import "ZegoAIAgentSubtitlesMessageDispatcher.h"

#import <Masonry/Masonry.h>

@interface ZegoAIAgentAudioSubtitlesForegroundView()

// 智能体状态
@property (nonatomic, strong, readwrite) ZegoAIAgentStatusView *agentStatus;
// 智能体字幕
@property (nonatomic, strong, readwrite) ZegoAIAgentSubtitlesTableView *chatView;

@end

@implementation ZegoAIAgentAudioSubtitlesForegroundView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
        [self registerEventHandler];
    }
    return self;
}

- (void)setupUI {
    [self setupStatus];
    [self setupSubtitles];
}

- (void)setupStatus {
    // 智能体状态
    self.agentStatus = [[ZegoAIAgentStatusView alloc] initWithFrame:CGRectZero];
    [self addSubview:self.agentStatus];
    
    [self.agentStatus updateStatusText:@"等待连接..."];
    [self.agentStatus mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(104);
        make.height.mas_equalTo(30);
        make.top.equalTo(self).offset(50);
        make.centerX.equalTo(self);
    }];
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

- (void)registerEventHandler {
    [[ZegoAIAgentSubtitlesMessageDispatcher sharedInstance] registerEventHandler:self];
}

- (void)unregisterEventHandler {
    [[ZegoAIAgentSubtitlesMessageDispatcher sharedInstance] unregisterEventHandler:self];
}

#pragma mark - ZegoAIAgentChatEventHandler

- (void)onRecvChatStateChange:(ZegoAIAgentSessionState)state {
    [self.agentStatus updateTextByState:state];
}

- (void)onRecvAsrChatMsg:(ZegoAIAgentAudioSubtitlesMessage *)message {
    [self.chatView handleRecvAsrMessage:message];
}

- (void)onRecvLLMChatMsg:(ZegoAIAgentAudioSubtitlesMessage *)message {
    [self.chatView handleRecvLLMMessage:message];
}

#pragma mark - Public Methods

/**
 * 更新状态文本
 * @param statusText 状态文本
 */
- (void)updateStatusText:(NSString *)statusText {
    [self.agentStatus updateStatusText:statusText];
}

- (void)dealloc {
    [self unregisterEventHandler];
}

@end 
