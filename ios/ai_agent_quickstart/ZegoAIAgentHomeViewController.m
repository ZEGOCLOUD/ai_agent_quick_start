//
//  ZegoAIAgentHomeViewController.m
//  ai_agent_quickstart
//
//  Created by Zego 2024/12/26.
//

#import "ZegoAIAgentHomeViewController.h"
#import "ZegoAIAgentAudioViewController.h"
#import "ZegoAIAgentDigitalHumanViewController.h"
#import <Masonry/Masonry.h>

@interface ZegoAIAgentHomeViewController ()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UIButton *audioCallButton;
@property (nonatomic, strong) UIButton *digitalHumanButton;
/// 数字人播报模式（单向 TTS）入口按钮
@property (nonatomic, strong) UIButton *liveDigitalHumanButton;

@end

@implementation ZegoAIAgentHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self setupUI];
}

- (void)setupUI {
    // 主标题
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = @"AI Agent Quick Start";
    self.titleLabel.font = [UIFont boldSystemFontOfSize:28];
    self.titleLabel.textColor = [UIColor blackColor];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.titleLabel];
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(80);
        make.centerX.equalTo(self.view);
    }];
    
    // 副标题
    self.subtitleLabel = [[UILabel alloc] init];
    self.subtitleLabel.text = @"选择您想要体验的AI功能";
    self.subtitleLabel.font = [UIFont systemFontOfSize:16];
    self.subtitleLabel.textColor = [UIColor darkGrayColor];
    self.subtitleLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.subtitleLabel];
    [self.subtitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(16);
        make.centerX.equalTo(self.view);
    }];
    
    // 语音通话按钮
    self.audioCallButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.audioCallButton setTitle:@"StartAIAudioCall" forState:UIControlStateNormal];
    self.audioCallButton.backgroundColor = [UIColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:1.0];
    [self.audioCallButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.audioCallButton.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightMedium];
    self.audioCallButton.layer.cornerRadius = 12;
    self.audioCallButton.layer.shadowColor = [UIColor blackColor].CGColor;
    self.audioCallButton.layer.shadowOffset = CGSizeMake(0, 2);
    self.audioCallButton.layer.shadowOpacity = 0.1;
    self.audioCallButton.layer.shadowRadius = 4;
    [self.audioCallButton addTarget:self action:@selector(audioCallButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.audioCallButton];
    [self.audioCallButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.subtitleLabel.mas_bottom).offset(100);
        make.centerX.equalTo(self.view);
        make.width.mas_equalTo(280);
        make.height.mas_equalTo(56);
    }];
    
    // 数字人通话按钮
    self.digitalHumanButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.digitalHumanButton setTitle:@"StartDigitalHumanCall" forState:UIControlStateNormal];
    self.digitalHumanButton.backgroundColor = [UIColor colorWithRed:0.8 green:0.3 blue:0.9 alpha:1.0];
    [self.digitalHumanButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.digitalHumanButton.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightMedium];
    self.digitalHumanButton.layer.cornerRadius = 12;
    self.digitalHumanButton.layer.shadowColor = [UIColor blackColor].CGColor;
    self.digitalHumanButton.layer.shadowOffset = CGSizeMake(0, 2);
    self.digitalHumanButton.layer.shadowOpacity = 0.1;
    self.digitalHumanButton.layer.shadowRadius = 4;
    [self.digitalHumanButton addTarget:self action:@selector(digitalHumanButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.digitalHumanButton];
    [self.digitalHumanButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.audioCallButton.mas_bottom).offset(30);
        make.centerX.equalTo(self.view);
        make.width.mas_equalTo(280);
        make.height.mas_equalTo(56);
    }];

    // 播报数字人按钮
    self.liveDigitalHumanButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.liveDigitalHumanButton setTitle:@"StartLiveDigitalHuman" forState:UIControlStateNormal];
    self.liveDigitalHumanButton.backgroundColor = [UIColor colorWithRed:0.23 green:0.71 blue:0.55 alpha:1.0];
    [self.liveDigitalHumanButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.liveDigitalHumanButton.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightMedium];
    self.liveDigitalHumanButton.layer.cornerRadius = 12;
    self.liveDigitalHumanButton.layer.shadowColor = [UIColor blackColor].CGColor;
    self.liveDigitalHumanButton.layer.shadowOffset = CGSizeMake(0, 2);
    self.liveDigitalHumanButton.layer.shadowOpacity = 0.1;
    self.liveDigitalHumanButton.layer.shadowRadius = 4;
    [self.liveDigitalHumanButton addTarget:self action:@selector(liveDigitalHumanButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.liveDigitalHumanButton];
    [self.liveDigitalHumanButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.digitalHumanButton.mas_bottom).offset(30);
        make.centerX.equalTo(self.view);
        make.width.mas_equalTo(280);
        make.height.mas_equalTo(56);
    }];
    
    // 底部说明文字
    UILabel *noteLabel = [[UILabel alloc] init];
    noteLabel.text = @"请确保已启动对应的后台服务";
    noteLabel.font = [UIFont systemFontOfSize:14];
    noteLabel.textColor = [UIColor lightGrayColor];
    noteLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:noteLabel];
    [noteLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-40);
        make.centerX.equalTo(self.view);
    }];
}

#pragma mark - Button Actions

- (void)audioCallButtonTapped {
    ZegoAIAgentAudioViewController *audioVC = [[ZegoAIAgentAudioViewController alloc] init];
    audioVC.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:audioVC animated:YES completion:nil];
}

- (void)digitalHumanButtonTapped {
    ZegoAIAgentDigitalHumanViewController *digitalHumanVC = [[ZegoAIAgentDigitalHumanViewController alloc] init];
    digitalHumanVC.mode = ZegoAIAgentDigitalHumanModeInteractive;
    digitalHumanVC.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:digitalHumanVC animated:YES completion:nil];
}

// 新入口显式进入播报数字人模式，保留旧对话数字人链路不变
- (void)liveDigitalHumanButtonTapped {
    ZegoAIAgentDigitalHumanViewController *liveDigitalHumanVC = [[ZegoAIAgentDigitalHumanViewController alloc] init];
    liveDigitalHumanVC.mode = ZegoAIAgentDigitalHumanModeLiveBroadcast;
    liveDigitalHumanVC.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:liveDigitalHumanVC animated:YES completion:nil];
}

@end
