//
//  ZegoAIAgentDigitalHumanViewController.m
//  ai_agent_quickstart
//
//  Created by Zego 2024/12/26.
//

#import "ZegoAIAgentDigitalHumanViewController.h"
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <Masonry/Masonry.h>
#import "ZegoAIAgentServiceAPI.h"
#import "ZegoAIAgentSubtitlesTableView.h"
#import "ZegoAIAgentSubtitlesMessageDispatcher.h"

@interface ZegoAIAgentDigitalHumanViewController ()<ZegoAIAgentSubtitlesEventHandler>

// UI组件
@property (nonatomic, strong) UIView *videoContainer;
@property (nonatomic, strong) UIButton *backButton;

@end

@implementation ZegoAIAgentDigitalHumanViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    
    [self setupUI];
}

- (void)setupUI {
    // 返回按钮
    self.backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.backButton setTitle:@"← Back" forState:UIControlStateNormal];
    [self.backButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.backButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [self.backButton addTarget:self action:@selector(backButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.backButton];
    [self.backButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(10);
        make.left.equalTo(self.view.mas_left).offset(16);
    }];
    
    // 数字人视频容器
    self.videoContainer = [[UIView alloc] init];
    self.videoContainer.backgroundColor = [UIColor colorWithWhite:0.1 alpha:1];
    self.videoContainer.layer.cornerRadius = 12;
    self.videoContainer.layer.masksToBounds = YES;
    [self.view addSubview:self.videoContainer];
    [self.videoContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.backButton.mas_bottom).offset(20);
        make.left.equalTo(self.view.mas_left).offset(20);
        make.right.equalTo(self.view.mas_right).offset(-20);
        make.height.mas_equalTo(300);
    }];
    
}


#pragma mark - Button Actions

- (void)backButtonTapped {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
