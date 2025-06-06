#import "ZegoAIAgentAudioViewController.h"

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <Masonry/Masonry.h>

#import "ZegoAIAgentServiceAPI.h"
#import "ZegoAIAgentSubtitlesTableView.h"
#import "ZegoAIAgentSubtitlesMessageDispatcher.h"

@interface ZegoAIAgentAudioViewController ()<ZegoAIAgentSubtitlesEventHandler>

// 前景UI组件
@property (nonatomic, strong) UILabel *roomIdLabel;
@property (nonatomic, strong) UILabel *userIdLabel;
@property (nonatomic, strong) UILabel *agentUserIdLabel;
@property (nonatomic, assign) BOOL isLoggedIn;
@property (nonatomic, strong) UIButton *logoutButton;
@property (nonatomic, strong) UIView *subtitlesTab;
@property (nonatomic, strong) UILabel *subtitlesTabLabel;
@property (nonatomic, strong) ZegoAIAgentSubtitlesTableView *subtitlesTableView;
@property (nonatomic, assign) BOOL subtitlesExpanded;
@property (nonatomic, strong) UILabel *tipLabel;
@property (nonatomic, strong) UIActivityIndicatorView *loadingIndicator;

@end

@implementation ZegoAIAgentAudioViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.isLoggedIn = NO;

    self.subtitlesExpanded = YES; // 默认展开字幕

    [self setupUI];

    // 默认展开字幕视图
    [self expandSubtitlesView];

    // 界面加载完成后自动登录
    [self startAudioChat];
}

- (void)setupUI {
    // VoiceChat标题栏
    UIView *titleBar = [[UIView alloc] init];
    titleBar.backgroundColor = [UIColor colorWithWhite:0.85 alpha:1];
    [self.view addSubview:titleBar];
    [titleBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        make.left.right.equalTo(self.view);
        make.height.mas_equalTo(48);
    }];
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"VoiceChat";
    titleLabel.font = [UIFont boldSystemFontOfSize:20];
    titleLabel.textColor = [UIColor blackColor];
    [titleBar addSubview:titleLabel];
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(titleBar.mas_left).offset(16);
        make.centerY.equalTo(titleBar);
    }];

    // RoomId
    self.roomIdLabel = [[UILabel alloc] init];
    self.roomIdLabel.text = [NSString stringWithFormat:@"RoomID = %@", [[ZegoAIAgentServiceAPI sharedInstance] getRoomId]];
    self.roomIdLabel.font = [UIFont systemFontOfSize:16];
    self.roomIdLabel.textColor = [UIColor darkGrayColor];
    [self.view addSubview:self.roomIdLabel];
    [self.roomIdLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(titleBar.mas_bottom).offset(10);
        make.centerX.equalTo(self.view);
    }];

    // UserId
    self.userIdLabel = [[UILabel alloc] init];
    self.userIdLabel.text = [NSString stringWithFormat:@"%@", [[ZegoAIAgentServiceAPI sharedInstance] getUserId]];
    self.userIdLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    self.userIdLabel.textAlignment = NSTextAlignmentCenter;
    self.userIdLabel.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
    self.userIdLabel.layer.cornerRadius = 80;
    self.userIdLabel.layer.masksToBounds = YES;
    [self.view addSubview:self.userIdLabel];
    [self.userIdLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.roomIdLabel.mas_bottom).offset(10);
        make.left.equalTo(self.view.mas_left).offset(10);
        make.width.height.mas_equalTo(160);
    }];

    // AgentId
    self.agentUserIdLabel = [[UILabel alloc] init];
    self.agentUserIdLabel.text = [NSString stringWithFormat:@"%@", [[ZegoAIAgentServiceAPI sharedInstance] getAgentUserId]];
    self.agentUserIdLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    self.agentUserIdLabel.textAlignment = NSTextAlignmentCenter;
    self.agentUserIdLabel.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
    self.agentUserIdLabel.layer.cornerRadius = 80;
    self.agentUserIdLabel.layer.masksToBounds = YES;
    self.agentUserIdLabel.adjustsFontSizeToFitWidth = YES;
    [self.view addSubview:self.agentUserIdLabel];
    [self.agentUserIdLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.roomIdLabel.mas_bottom).offset(10);
        make.right.equalTo(self.view.mas_right).offset(-10);
        make.width.height.mas_equalTo(160);
    }];

    // Logout 按钮
    self.logoutButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.logoutButton setTitle:@"LogoutRoom" forState:UIControlStateNormal];
    self.logoutButton.backgroundColor = [UIColor colorWithRed:0.9 green:0.4 blue:0.4 alpha:1];
    [self.logoutButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.logoutButton.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightMedium];
    self.logoutButton.layer.cornerRadius = 8;
    [self.logoutButton addTarget:self action:@selector(logoutButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.logoutButton];
    [self.logoutButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.userIdLabel.mas_bottom).offset(40);
        make.centerX.equalTo(self.view);
        make.width.mas_equalTo(240);
        make.height.mas_equalTo(44);
    }];

    // Loading 指示器
    self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    self.loadingIndicator.hidesWhenStopped = YES;
    self.loadingIndicator.color = [UIColor colorWithRed:0.7 green:0.5 blue:0.9 alpha:1]; // 淡紫色
    [self.view addSubview:self.loadingIndicator];
    [self.loadingIndicator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
    }];

    // 提示
    self.tipLabel = [[UILabel alloc] init];
    self.tipLabel.text = @"Note:\n1.Within the same AppID, ensure "userID" is globally unique, otherwise users will be kicked out.\n2.Please create the corresponding agent on the server first, and create the agent instance synchronously during Call.";
    self.tipLabel.font = [UIFont systemFontOfSize:14];
    self.tipLabel.textColor = [UIColor darkGrayColor];
    self.tipLabel.numberOfLines = 0;
    [self.view addSubview:self.tipLabel];
    [self.tipLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.logoutButton.mas_bottom).offset(30);
        make.left.equalTo(self.view.mas_left).offset(20);
        make.right.equalTo(self.view.mas_right).offset(-20);
    }];

    // subtitles tab
    self.subtitlesTab = [[UIView alloc] init];
    self.subtitlesTab.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1];
    self.subtitlesTab.userInteractionEnabled = YES;
    self.subtitlesTab.layer.cornerRadius = 4;
    [self.view addSubview:self.subtitlesTab];
    [self.subtitlesTab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tipLabel.mas_bottom).offset(30);
        make.left.right.equalTo(self.view);
        make.height.mas_equalTo(44);
    }];
    self.subtitlesTabLabel = [[UILabel alloc] init];
    self.subtitlesTabLabel.text = @"subtitles (Click to collapse)"; // 默认显示折叠文本
    self.subtitlesTabLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    self.subtitlesTabLabel.textColor = [UIColor blackColor];
    self.subtitlesTabLabel.textAlignment = NSTextAlignmentLeft;
    [self.subtitlesTab addSubview:self.subtitlesTabLabel];
    [self.subtitlesTabLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.subtitlesTab.mas_left).offset(16);
        make.centerY.equalTo(self.subtitlesTab);
        make.right.lessThanOrEqualTo(self.subtitlesTab.mas_right).offset(-8);
    }];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(subtitlesTabTapped)];
    [self.subtitlesTab addGestureRecognizer:tap];
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

- (void)startAudioChat {
    [self registerEventHandler];

    // 显示加载指示器
    [self.loadingIndicator startAnimating];
    self.logoutButton.enabled = NO;

    [self requestAudioPermission:^(BOOL granted) {
        if (!granted) {
            [self showToast:@"未获得音频权限"];
            [self.loadingIndicator stopAnimating];
            self.logoutButton.enabled = YES;
            return;
        }
        __weak typeof(self) weakSelf = self;
        [[ZegoAIAgentServiceAPI sharedInstance] startCallWithCompletion:^(BOOL success, NSString * _Nullable errorMessage) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return;
            [strongSelf.loadingIndicator stopAnimating];
            strongSelf.logoutButton.enabled = YES;

            if (success) {
                strongSelf.isLoggedIn = YES;
                // 登录成功后更新按钮状态
                [strongSelf.logoutButton setTitle:@"LogoutRoom" forState:UIControlStateNormal];
                strongSelf.logoutButton.backgroundColor = [UIColor colorWithRed:0.9 green:0.4 blue:0.4 alpha:1];
            } else {
                [strongSelf showToast:[NSString stringWithFormat:@"音频聊天开始失败：%@", errorMessage]];
            }
        }];
    }];
}

- (void)logoutButtonTapped {
    if (!self.isLoggedIn) return;

    self.logoutButton.enabled = NO;
    [self.loadingIndicator startAnimating];

    // 调用stopChat并在完成后返回上一个界面
    [self stopChatWithCompletion:^(BOOL success) {
        if (success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.presentingViewController) {
                    [self dismissViewControllerAnimated:YES completion:nil];
                } else {
                    [self.navigationController popViewControllerAnimated:YES];
                }
            });
        }
    }];
}

- (void)stopChatWithCompletion:(void(^)(BOOL success))completion {
    [self unregisterEventHandler];

    __weak typeof(self) weakSelf = self;
    [[ZegoAIAgentServiceAPI sharedInstance] stopCallWithCompletion:^(BOOL success, NSString * _Nullable errorMessage) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        [strongSelf.loadingIndicator stopAnimating];
        strongSelf.logoutButton.enabled = YES;
        strongSelf.isLoggedIn = NO;

        if (!success) {
            [strongSelf showToast:[NSString stringWithFormat:@"音频聊天停止失败：%@", errorMessage]];
        }

        if (completion) {
            completion(success);
        }
    }];
}

- (void)expandSubtitlesView {
    if (!self.subtitlesTableView) {
        self.subtitlesTableView = [[ZegoAIAgentSubtitlesTableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    }
    [self.view addSubview:self.subtitlesTableView];
    [self.subtitlesTableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.subtitlesTab.mas_bottom);
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_bottom).offset(-2);
    }];
}

- (void)subtitlesTabTapped {
    if (!self.subtitlesExpanded) {
        [self expandSubtitlesView];
        self.subtitlesExpanded = YES;
        self.subtitlesTabLabel.text = @"subtitles (Click to collapse)";
    } else {
        [self.subtitlesTableView removeFromSuperview];
        self.subtitlesExpanded = NO;
        self.subtitlesTabLabel.text = @"subtitles (Click to expand)";
    }
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

#pragma mark - ZegoAIAgentSubtitlesEventHandler

- (void)registerEventHandler {
    [[ZegoAIAgentSubtitlesMessageDispatcher sharedInstance] registerEventHandler:self];
}

- (void)unregisterEventHandler {
    [[ZegoAIAgentSubtitlesMessageDispatcher sharedInstance] unregisterEventHandler:self];
}

- (void)onRecvAsrChatMsg:(ZegoAIAgentAudioSubtitlesMessage *)message {
    [self.subtitlesTableView handleRecvAsrMessage:message];
}

- (void)onRecvLLMChatMsg:(ZegoAIAgentAudioSubtitlesMessage *)message {
    [self.subtitlesTableView handleRecvLLMMessage:message];
}

@end
