//
//  ZegoCallVCNameUIComponent.m
//
//  Created by zego on 2024/5/13.
//  Copyright © 2024 Zego. All rights reserved.
//

#import "ZegoAIAgentStatusView.h"

#import <Masonry/Masonry.h>

@interface ZegoAIAgentStatusView ()
@property (nonatomic, strong)UIFont* chatStatusFont;
@property (nonatomic, assign)CGFloat minWidth;
@property (nonatomic, strong)UILabel *statusLabel;
@property (nonatomic, strong) NSString* statusText;

@end

@implementation ZegoAIAgentStatusView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.minWidth = 104;
        [self setupUI];
    }
    return self;
}

-(void)layoutSubviews{
    [super layoutSubviews];
}

-(CGRect)calculateStringLenght:(NSString *)content withFont:(UIFont*)font{
    NSDictionary *attributes = @{
        NSFontAttributeName: font,
        NSForegroundColorAttributeName: [UIColor blackColor]
    };
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:content attributes:attributes];
    
    // 计算文本的大小
    CGSize maxSize = CGSizeMake(239, CGFLOAT_MAX);
    CGRect boundingBox = [attributedString boundingRectWithSize:maxSize
                                                        options:NSStringDrawingUsesLineFragmentOrigin
                                                        context:nil];
    return boundingBox;
}

-(void)updateStatusText:(NSString *)chatStatusText{
    _statusText = chatStatusText;
    self.statusLabel.text = _statusText;
    CGRect newRect = [self calculateStringLenght:_statusText withFont:self.chatStatusFont];
    CGFloat newWidth = newRect.size.width + 20;
    if (newWidth > self.minWidth) {
        [self mas_updateConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(newWidth);
        }];
    }else{
        [self mas_updateConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(self.minWidth);
        }];
    }
    
    [self layoutIfNeeded];
}

- (void)setupUI {
    self.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.3];
    self.layer.cornerRadius = 8;
    self.layer.masksToBounds = YES;
    
    self.statusLabel = [[UILabel alloc]init];
    self.chatStatusFont = [UIFont fontWithName:@"PingFangSC-Regular" size:14];
    self.statusLabel.font = self.chatStatusFont;
    self.statusLabel.textColor = [UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1/1.0];
    self.statusLabel.backgroundColor = [UIColor clearColor];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:self.statusLabel];
    
    [self.statusLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(10);
        make.right.equalTo(self).offset(-10);
        make.height.mas_equalTo(22);
        make.centerX.equalTo(self);
        make.centerY.equalTo(self);
    }];
}

- (void)updateTextByState:(ZegoAIAgentSessionState)state {
    if (SubtitlesSessionState_AI_LISTEN == state) {
        [self updateStatusText:@"正在听..."];
    } else if (SubtitlesSessionState_AI_THINKING == state) {
        [self updateStatusText:@"正在想..."];
    } else if (SubtitlesSessionState_AI_SPEAKING == state) {
        [self updateStatusText:@"可以随时说话打断我"];
    } else if (SubtitlesSessionState_UNINIT == state) {
        [self updateStatusText:@"等待连接..."];
    }
}

@end
