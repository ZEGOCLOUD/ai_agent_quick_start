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

    // 页面启动时自动开始数字人聊天
    [self startDigitalHumanChat];
}

- (void)dealloc {
    // 界面销毁时自动停止数字人聊天
    [self stopDigitalHumanChat];
}

- (void)setupUI {
    // 返回按钮
    self.backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.backButton setTitle:@"← 返回" forState:UIControlStateNormal];
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

- (void)startDigitalHumanChat {
    [self requestAudioPermission:^(BOOL granted) {
        if (!granted) {
            [self showToast:@"No audio permission granted"];
            return;
        }
        
        __weak typeof(self) weakSelf = self;
        [[ZegoAIAgentServiceAPI sharedInstance] startDigitalHumanWithCompletion:^(BOOL success, NSString * _Nullable errorMessage) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return;
            
            if (success) {
            } else {
                [strongSelf showToast:[NSString stringWithFormat:@"Failed to start digital human chat: %@", errorMessage]];
            }
        }];
    }];
}

- (void)stopDigitalHumanChat {
    __weak typeof(self) weakSelf = self;
    [[ZegoAIAgentServiceAPI sharedInstance] stopDigitalHumanWithCompletion:^(BOOL success, NSString * _Nullable errorMessage) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        if (!success) {
            [strongSelf showToast:[NSString stringWithFormat:@"Failed to stop digital human chat: %@", errorMessage]];
        }
    }];
}

- (void)requestAudioPermission:(void(^)(BOOL granted))completion {
    /// 需要在项目的 Info.plist 文件中添加麦克风权限的使用说明
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession requestRecordPermission:^(BOOL granted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(granted);
        });
    }];
}

- (void)showToast:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                     message:message
                                                              preferredStyle:UIAlertControllerStyleAlert];
        
        [self presentViewController:alert animated:YES completion:^{
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [alert dismissViewControllerAnimated:YES completion:nil];
            });
        }];
    });
}

#pragma mark - Button Actions

- (void)backButtonTapped {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
