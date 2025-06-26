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
@property (nonatomic, strong) UILabel *roomIdLabel;
@property (nonatomic, strong) UILabel *userIdLabel;
@property (nonatomic, strong) UILabel *agentIdLabel;
@property (nonatomic, strong) UIButton *loginLogoutButton;
@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, assign) BOOL isLoggedIn;
@property (nonatomic, strong) UIView *subtitlesTab;
@property (nonatomic, strong) UILabel *subtitlesTabLabel;
@property (nonatomic, strong) ZegoAIAgentSubtitlesTableView *subtitlesTableView;
@property (nonatomic, assign) BOOL subtitlesExpanded;
@property (nonatomic, strong) UILabel *tipLabel;
@property (nonatomic, strong) UIActivityIndicatorView *loginLogoutLoading;

@end

@implementation ZegoAIAgentDigitalHumanViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    self.isLoggedIn = NO;
    self.subtitlesExpanded = YES; // 默认展开字幕
    
    [self setupUI];
    
    // 默认展开字幕视图
    [self expandSubtitlesView];
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
    
    // 视频占位符
    UILabel *videoPlaceholder = [[UILabel alloc] init];
    videoPlaceholder.text = @"数字人视频区域\n(Digital Human Video)";
    videoPlaceholder.font = [UIFont systemFontOfSize:18];
    videoPlaceholder.textColor = [UIColor whiteColor];
    videoPlaceholder.textAlignment = NSTextAlignmentCenter;
    videoPlaceholder.numberOfLines = 0;
    [self.videoContainer addSubview:videoPlaceholder];
    [videoPlaceholder mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.videoContainer);
    }];
    
    // RoomId
    self.roomIdLabel = [[UILabel alloc] init];
    self.roomIdLabel.text = [NSString stringWithFormat:@"RoomID = %@", [[ZegoAIAgentServiceAPI sharedInstance] getRoomId]];
    self.roomIdLabel.font = [UIFont systemFontOfSize:14];
    self.roomIdLabel.textColor = [UIColor whiteColor];
    self.roomIdLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.roomIdLabel];
    [self.roomIdLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.videoContainer.mas_bottom).offset(20);
        make.centerX.equalTo(self.view);
    }];
    
    // 用户和智能体信息容器
    UIView *infoContainer = [[UIView alloc] init];
    [self.view addSubview:infoContainer];
    [infoContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.roomIdLabel.mas_bottom).offset(15);
        make.left.right.equalTo(self.view);
        make.height.mas_equalTo(60);
    }];
    
    // UserId
    self.userIdLabel = [[UILabel alloc] init];
    self.userIdLabel.text = [NSString stringWithFormat:@"User: %@", [[ZegoAIAgentServiceAPI sharedInstance] getUserId]];
    self.userIdLabel.font = [UIFont systemFontOfSize:14];
    self.userIdLabel.textColor = [UIColor whiteColor];
    self.userIdLabel.textAlignment = NSTextAlignmentCenter;
    self.userIdLabel.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1];
    self.userIdLabel.layer.cornerRadius = 20;
    self.userIdLabel.layer.masksToBounds = YES;
    [infoContainer addSubview:self.userIdLabel];
    [self.userIdLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(infoContainer);
        make.left.equalTo(infoContainer.mas_left).offset(20);
        make.width.mas_equalTo(120);
        make.height.mas_equalTo(40);
    }];
    
    // AgentId
    self.agentIdLabel = [[UILabel alloc] init];
    self.agentIdLabel.text = [NSString stringWithFormat:@"Agent: %@", [[ZegoAIAgentServiceAPI sharedInstance] getAgentId]];
    self.agentIdLabel.font = [UIFont systemFontOfSize:14];
    self.agentIdLabel.textColor = [UIColor whiteColor];
    self.agentIdLabel.textAlignment = NSTextAlignmentCenter;
    self.agentIdLabel.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1];
    self.agentIdLabel.layer.cornerRadius = 20;
    self.agentIdLabel.layer.masksToBounds = YES;
    self.agentIdLabel.adjustsFontSizeToFitWidth = YES;
    [infoContainer addSubview:self.agentIdLabel];
    [self.agentIdLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(infoContainer);
        make.right.equalTo(infoContainer.mas_right).offset(-20);
        make.width.mas_equalTo(120);
        make.height.mas_equalTo(40);
    }];
    
    // Login/Logout 按钮
    self.loginLogoutButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.loginLogoutButton setTitle:@"LoginRoom" forState:UIControlStateNormal];
    self.loginLogoutButton.backgroundColor = [UIColor colorWithRed:0.8 green:0.3 blue:0.9 alpha:1.0];
    [self.loginLogoutButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.loginLogoutButton.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightMedium];
    self.loginLogoutButton.layer.cornerRadius = 8;
    [self.loginLogoutButton addTarget:self action:@selector(loginLogoutButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.loginLogoutButton];
    [self.loginLogoutButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(infoContainer.mas_bottom).offset(20);
        make.centerX.equalTo(self.view);
        make.width.mas_equalTo(200);
        make.height.mas_equalTo(44);
    }];
    
    // loading
    self.loginLogoutLoading = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    self.loginLogoutLoading.color = [UIColor colorWithRed:0.8 green:0.6 blue:1.0 alpha:1.0];
    self.loginLogoutLoading.hidesWhenStopped = YES;
    [self.view addSubview:self.loginLogoutLoading];
    [self.loginLogoutLoading mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
    }];
    
    [self setupSubtitlesUI];
}

- (void)setupSubtitlesUI {
    // subtitles tab
    self.subtitlesTab = [[UIView alloc] init];
    self.subtitlesTab.backgroundColor = [UIColor colorWithWhite:0.3 alpha:1];
    self.subtitlesTab.userInteractionEnabled = YES;
    self.subtitlesTab.layer.cornerRadius = 4;
    [self.view addSubview:self.subtitlesTab];
    [self.subtitlesTab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-200);
        make.left.right.equalTo(self.view);
        make.height.mas_equalTo(44);
    }];
    
    self.subtitlesTabLabel = [[UILabel alloc] init];
    self.subtitlesTabLabel.text = @"字幕 ▼";
    self.subtitlesTabLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    self.subtitlesTabLabel.textColor = [UIColor whiteColor];
    [self.subtitlesTab addSubview:self.subtitlesTabLabel];
    [self.subtitlesTabLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.subtitlesTab);
    }];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(subtitlesTabTapped)];
    [self.subtitlesTab addGestureRecognizer:tapGesture];
    
    // subtitles table view
    self.subtitlesTableView = [[ZegoAIAgentSubtitlesTableView alloc] init];
    [self.view addSubview:self.subtitlesTableView];
    [self.subtitlesTableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.subtitlesTab.mas_bottom);
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
    }];
    
    [[ZegoAIAgentSubtitlesMessageDispatcher sharedInstance] addEventHandler:self];
}

#pragma mark - Button Actions

- (void)backButtonTapped {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)loginLogoutButtonTapped {
    // TODO: 实现数字人登录/登出逻辑
    NSLog(@"数字人登录/登出按钮被点击");
}

- (void)subtitlesTabTapped {
    if (self.subtitlesExpanded) {
        [self collapseSubtitlesView];
    } else {
        [self expandSubtitlesView];
    }
}

- (void)expandSubtitlesView {
    self.subtitlesExpanded = YES;
    self.subtitlesTabLabel.text = @"字幕 ▼";
    self.subtitlesTableView.hidden = NO;
}

- (void)collapseSubtitlesView {
    self.subtitlesExpanded = NO;
    self.subtitlesTabLabel.text = @"字幕 ▲";
    self.subtitlesTableView.hidden = YES;
}

#pragma mark - ZegoAIAgentSubtitlesEventHandler

- (void)onSubtitlesMessageReceived:(ZegoAIAgentSubtitlesMessageModel *)message {
    // 处理字幕消息
}

- (void)dealloc {
    [[ZegoAIAgentSubtitlesMessageDispatcher sharedInstance] removeEventHandler:self];
}

@end
