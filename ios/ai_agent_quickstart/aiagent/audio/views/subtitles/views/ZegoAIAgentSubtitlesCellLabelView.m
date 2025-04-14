//
//  ZegoAudioChatCellLabelView.m
//
//  Created by zego on 2024/5/13.
//  Copyright © 2024 Zego. All rights reserved.
//

#import "ZegoAIAgentSubtitlesCellLabelView.h"
#import <Masonry/Masonry.h>
#include "ZegoAIAgentSubtitlesMessageModel.h"

@interface ZegoAIAgentSubtitlesCellLabelView ()
@property (nonatomic) UIEdgeInsets insets;
@end

@implementation ZegoAIAgentSubtitlesCellLabelView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.insets = UIEdgeInsetsMake(10, 12, 10, 12);
    }
    return self;
}

-(void)layoutSubviews{
    [super layoutSubviews];
}

- (void)drawTextInRect:(CGRect)rect {
    [super drawTextInRect:UIEdgeInsetsInsetRect(rect, self.insets)];
}

-(void)setMsgModel:(ZegoAIAgentSubtitlesMessageModel*)msgModel{
    self.text = msgModel.content;
    self.numberOfLines =0;
    self.lineBreakMode = NSLineBreakByWordWrapping;
    self.font = [UIFont fontWithName:@"PingFang SC" size:15];
    self.layer.cornerRadius = 12;
    self.layer.masksToBounds = YES;
    
    if(msgModel.isMine){
        self.backgroundColor = self.colors.myBackgroundColor;
        self.textColor = self.colors.myTextColor;
    }else{
        self.backgroundColor = self.colors.otherBackgroundColor;
        self.textColor = self.colors.otherTextColor;
    }
}
@end
