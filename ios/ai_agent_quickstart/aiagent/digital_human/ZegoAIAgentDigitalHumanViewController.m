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
#import <ZegoDigitalMobile/ZegoDigitalMobile.h>
#import <ZegoExpressEngine/ZegoExpressEngine.h>

#import "ZegoAIAgentServiceAPI.h"
#import "ZegoAIAgentDigitalHumanEventHandler.h"
#import "ZegoKey.h"

@interface ZegoAIAgentDigitalHumanViewController ()<ZegoAIAgentDigitalHumanEventHandler, ZegoDigitalMobileDelegate>

// UI组件
@property (nonatomic, strong) UIButton *backButton;
/// 页面标题，用于区分当前是对话数字人还是播报数字人
@property (nonatomic, strong) UILabel *titleLabel;

// loading
@property (nonatomic, strong) UIView *loadingView;
@property (nonatomic, strong) UIActivityIndicatorView *loadingIndicator;
@property (nonatomic, strong) UILabel *loadingLabel;

// digital human
@property (nonatomic, strong) id<IZegoDigitalMobile> digitalMobile;
@property (nonatomic, strong) ZegoDigitalView *digitalView;

// 静态图片视图
@property (nonatomic, strong) UIImageView *staticImageView;
/// 播报数字人的底部控制面板
@property (nonatomic, strong) UIView *broadcastControlView;
/// 用于展示当前 agent_instance_id，方便调试接口
@property (nonatomic, strong) UILabel *agentInstanceLabel;
/// 播报内容输入框
@property (nonatomic, strong) UITextField *broadcastTextField;
/// 发送播报按钮
@property (nonatomic, strong) UIButton *broadcastButton;
/// 播报发送中的加载指示器
@property (nonatomic, strong) UIActivityIndicatorView *broadcastLoadingIndicator;

@end

@implementation ZegoAIAgentDigitalHumanViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];

    [self setupUI];

    // 页面启动时自动开始数字人聊天
    [self startDigitalHumanChat];
}

- (void)dealloc {
    // 界面销毁时自动停止数字人聊天
    [self stopDigitalHumanChat];

    self.digitalView = nil;
    self.staticImageView = nil;
}

- (void)setupUI {
    [self setupPreviewView];
    [self setupStaticImageView];
    [self setupLoadingView];

    // 返回按钮
    self.backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.backButton setTitle:@"← 返回" forState:UIControlStateNormal];
    [self.backButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    self.backButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [self.backButton addTarget:self action:@selector(backButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.backButton];
    [self.backButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(10);
        make.left.equalTo(self.view.mas_left).offset(16);
    }];

    // 页面标题
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = [self pageTitleText];
    self.titleLabel.textColor = [UIColor blackColor];
    self.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    [self.view addSubview:self.titleLabel];
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.backButton);
        make.centerX.equalTo(self.view);
    }];

    // 播报数字人模式下展示额外控制区，用于发送自定义TTS
    if (self.mode == ZegoAIAgentDigitalHumanModeLiveBroadcast) {
        [self setupBroadcastControlView];
    }
}

- (void)setupPreviewView {
    // 创建并添加previewView
    self.digitalView = [[ZegoDigitalView alloc] init];

    // 设置透明背景，让底层的静态图片可以显示
    self.digitalView.backgroundColor = [UIColor clearColor];

    [self.view addSubview:self.digitalView];

    // previewView全屏显示
    [self.digitalView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
}

- (void)setupStaticImageView {
    // 创建静态图片视图，放在previewView下方
    self.staticImageView = [[UIImageView alloc] init];
    self.staticImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.staticImageView.clipsToBounds = YES;

    // 设置背景色（可选，用于加载时显示）
    self.staticImageView.backgroundColor = [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.0]; // 很浅的灰色背景

    // 使用kDigitalHumanImageURL加载图片
    if (kDigitalHumanImageURL && kDigitalHumanImageURL.length > 0) {
        NSLog(@"开始加载静态图片: %@", kDigitalHumanImageURL);
        NSURL *imageURL = [NSURL URLWithString:kDigitalHumanImageURL];
        if (imageURL) {
            NSURLSession *session = [NSURLSession sharedSession];
            NSURLSessionDataTask *dataTask = [session dataTaskWithURL:imageURL completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (data && !error) {
                        UIImage *image = [UIImage imageWithData:data];
                        if (image) {
                            NSLog(@"静态图片加载成功，尺寸: %.0fx%.0f", image.size.width, image.size.height);
                            self.staticImageView.image = image;
                            NSLog(@"staticImageView frame: %@", NSStringFromCGRect(self.staticImageView.frame));
                            NSLog(@"staticImageView bounds: %@", NSStringFromCGRect(self.staticImageView.bounds));
                            NSLog(@"staticImageView hidden: %@", self.staticImageView.hidden ? @"YES" : @"NO");
                            NSLog(@"staticImageView alpha: %.2f", self.staticImageView.alpha);
                        } else {
                            NSLog(@"静态图片数据无效");
                        }
                    } else {
                        NSLog(@"加载静态图片失败: %@", error.localizedDescription);
                        // 设置一个默认的占位图片或者创建一个简单的占位视图
                    }
                });
            }];
            [dataTask resume];
        } else {
            NSLog(@"静态图片URL无效: %@", kDigitalHumanImageURL);
        }
    } else {
        NSLog(@"静态图片URL为空，跳过加载");
    }

    // 添加到previewView下方
    [self.view insertSubview:self.staticImageView belowSubview:self.digitalView];

    // 设置约束，让staticImageView覆盖整个屏幕（作为加载时的占位图）
    [self.staticImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
}

- (void)setupLoadingView {
    // 创建 loading 容器视图
    self.loadingView = [[UIView alloc] init];
    self.loadingView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.7];
    self.loadingView.layer.cornerRadius = 10;
    [self.view addSubview:self.loadingView];

    // 创建加载指示器（浅紫色）
    if (@available(iOS 13.0, *)) {
        self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    } else {
        self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    }
    self.loadingIndicator.color = [UIColor colorWithRed:0.7 green:0.6 blue:1.0 alpha:1.0]; // 浅紫色
    [self.loadingView addSubview:self.loadingIndicator];

    // 创建加载文本
    self.loadingLabel = [[UILabel alloc] init];
    self.loadingLabel.text = @"数字人加载中...";
    self.loadingLabel.textColor = [UIColor whiteColor];
    self.loadingLabel.font = [UIFont systemFontOfSize:16];
    self.loadingLabel.textAlignment = NSTextAlignmentCenter;
    [self.loadingView addSubview:self.loadingLabel];

    // 设置约束
    [self.loadingView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
        make.width.mas_equalTo(200);
        make.height.mas_equalTo(120);
    }];

    [self.loadingIndicator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.loadingView);
        make.top.equalTo(self.loadingView).offset(20);
    }];

    [self.loadingLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.loadingView);
        make.top.equalTo(self.loadingIndicator.mas_bottom).offset(15);
        make.left.equalTo(self.loadingView).offset(10);
        make.right.equalTo(self.loadingView).offset(-10);
    }];

    // 初始状态隐藏
    self.loadingView.hidden = YES;
}

- (void)showLoading {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.loadingView.hidden = NO;
        self.loadingLabel.text = self.mode == ZegoAIAgentDigitalHumanModeLiveBroadcast ? @"播报数字人加载中..." : @"数字人加载中...";
        [self.loadingIndicator startAnimating];
        NSLog(@"显示 loading 界面");
    });
}

- (void)hideLoading {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.loadingView.hidden = YES;
        [self.loadingIndicator stopAnimating];
        NSLog(@"隐藏 loading 界面");
    });
}

- (void)startDigitalHumanChat {
    // 显示 loading
    [self showLoading];

    // 设置自己为数字人事件处理器
    [[ZegoAIAgentServiceAPI sharedInstance] registerDigitalHumanEventHandler:self];

    if (self.mode == ZegoAIAgentDigitalHumanModeLiveBroadcast) {
        [self startLiveBroadcastDigitalHuman];
        return;
    }

    [self startInteractiveDigitalHuman];
}

- (void)stopDigitalHumanChat {
    // 清除数字人事件处理器
    [[ZegoAIAgentServiceAPI sharedInstance] registerDigitalHumanEventHandler:nil];

    if (self.mode == ZegoAIAgentDigitalHumanModeLiveBroadcast) {
        [[ZegoAIAgentServiceAPI sharedInstance] stopLiveDigitalHumanWithCompletion:nil];
    } else {
        [[ZegoAIAgentServiceAPI sharedInstance] stopDigitalHumanWithCompletion:nil];
    }
    
    // 清理digitalMobile
    if (self.digitalMobile) {
        // 停止数字人
        [self.digitalMobile stop];
        
        self.digitalMobile = nil;
    }
}

// 对话数字人模式需要请求麦克风权限并建立双向语音链路
- (void)startInteractiveDigitalHuman {
    [self requestAudioPermission:^(BOOL granted) {
        if (!granted) {
            [self hideLoading];
            [self showToast:@"No audio permission granted"];
            return;
        }

        __weak typeof(self) weakSelf = self;
        [[ZegoAIAgentServiceAPI sharedInstance] startDigitalHumanWithCompletion:^(BOOL success, NSInteger errorCode, NSString * _Nullable errorMessage, NSString * _Nullable digitalHumanEncodeConfig) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return;

            NSLog(@"%@", errorMessage);

            if (success) {
                [strongSelf startDigitalHumanRenderWithConfig:digitalHumanEncodeConfig];
            } else {
                [strongSelf hideLoading];
                [strongSelf showToast:[NSString stringWithFormat:@"Failed to start digital human chat: %@", errorMessage]];
            }
        }];
    }];
}

// 播报数字人模式只需要创建实例并进入房间拉取数字人流，不需要本地录音权限
- (void)startLiveBroadcastDigitalHuman {
    __weak typeof(self) weakSelf = self;
    [[ZegoAIAgentServiceAPI sharedInstance] startLiveDigitalHumanWithCompletion:^(BOOL success, NSInteger errorCode, NSString * _Nullable errorMessage, NSString * _Nullable digitalHumanEncodeConfig) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;

        NSLog(@"%@", errorMessage);

        if (success) {
            [strongSelf updateBroadcastDebugInfo];
            [strongSelf startDigitalHumanRenderWithConfig:digitalHumanEncodeConfig];
        } else {
            [strongSelf hideLoading];
            [strongSelf showToast:[NSString stringWithFormat:@"Failed to start live digital human: %@", errorMessage]];
        }
    }];
}

// 数字人渲染启动逻辑在两种模式下完全一致，因此抽到统一方法中复用
- (void)startDigitalHumanRenderWithConfig:(NSString *)digitalHumanEncodeConfig {
    self.digitalMobile = [ZegoDigitalHuman create];
    if (!self.digitalMobile) {
        [self hideLoading];
        [self showToast:@"创建数字人实例失败"];
        return;
    }

    if (!self.view.window) {
        self.digitalMobile = nil;
        NSLog(@"Page dismissed, cleaning up digital mobile instance");
        return;
    }

    NSString *configToUse = digitalHumanEncodeConfig ?: @"";
    NSLog(@"使用数字人配置: %@", configToUse);
    [self.digitalMobile start:configToUse delegate:self];

    if (self.digitalView) {
        NSLog(@"开始绑定数字人到 previewView，frame: %@", NSStringFromCGRect(self.digitalView.frame));
        [self.digitalMobile attach:self.digitalView];
        NSLog(@"数字人已绑定到 previewView");
    } else {
        NSLog(@"previewView is nil, cannot attach");
    }
}

// 播报数字人模式提供文本输入和主动播报按钮，便于直接联调 send-agent-instance-tts
- (void)setupBroadcastControlView {
    self.broadcastControlView = [[UIView alloc] init];
    self.broadcastControlView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.65];
    self.broadcastControlView.layer.cornerRadius = 16;
    [self.view addSubview:self.broadcastControlView];
    [self.broadcastControlView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(16);
        make.right.equalTo(self.view).offset(-16);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-16);
    }];

    self.agentInstanceLabel = [[UILabel alloc] init];
    self.agentInstanceLabel.textColor = [UIColor whiteColor];
    self.agentInstanceLabel.font = [UIFont systemFontOfSize:12];
    self.agentInstanceLabel.numberOfLines = 2;
    self.agentInstanceLabel.text = @"AgentInstanceID: waiting...";
    [self.broadcastControlView addSubview:self.agentInstanceLabel];

    self.broadcastTextField = [[UITextField alloc] init];
    self.broadcastTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.broadcastTextField.backgroundColor = [UIColor whiteColor];
    self.broadcastTextField.textColor = [UIColor blackColor];
    self.broadcastTextField.placeholder = @"输入播报内容";
    self.broadcastTextField.text = @"尊敬的开发者你好，欢迎使用 ZEGO RTC 共建实时互动世界。";
    [self.broadcastControlView addSubview:self.broadcastTextField];

    self.broadcastButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.broadcastButton setTitle:@"发送播报" forState:UIControlStateNormal];
    [self.broadcastButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.broadcastButton.backgroundColor = [UIColor colorWithRed:0.35 green:0.55 blue:1 alpha:1];
    self.broadcastButton.layer.cornerRadius = 10;
    [self.broadcastButton addTarget:self action:@selector(broadcastButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.broadcastControlView addSubview:self.broadcastButton];

    self.broadcastLoadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    self.broadcastLoadingIndicator.hidesWhenStopped = YES;
    [self.broadcastButton addSubview:self.broadcastLoadingIndicator];

    [self.agentInstanceLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.broadcastControlView).offset(12);
        make.left.equalTo(self.broadcastControlView).offset(12);
        make.right.equalTo(self.broadcastControlView).offset(-12);
    }];

    [self.broadcastTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.agentInstanceLabel.mas_bottom).offset(10);
        make.left.equalTo(self.broadcastControlView).offset(12);
        make.right.equalTo(self.broadcastControlView).offset(-12);
        make.height.mas_equalTo(40);
    }];

    [self.broadcastButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.broadcastTextField.mas_bottom).offset(10);
        make.left.equalTo(self.broadcastControlView).offset(12);
        make.right.equalTo(self.broadcastControlView).offset(-12);
        make.height.mas_equalTo(44);
        make.bottom.equalTo(self.broadcastControlView).offset(-12);
    }];

    [self.broadcastLoadingIndicator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.broadcastButton);
        make.right.equalTo(self.broadcastButton).offset(-12);
    }];
}

// 根据页面模式返回对应标题，便于用户区分当前体验场景
- (NSString *)pageTitleText {
    return self.mode == ZegoAIAgentDigitalHumanModeLiveBroadcast ? @"播报数字人" : @"数字人对话";
}

// 在播报模式下展示服务端返回的实例ID，方便调用 stop 和 TTS 接口排查问题
- (void)updateBroadcastDebugInfo {
    if (self.mode != ZegoAIAgentDigitalHumanModeLiveBroadcast || self.agentInstanceLabel == nil) {
        return;
    }

    NSString *agentInstanceId = [[ZegoAIAgentServiceAPI sharedInstance] getAgentInstanceId];
    self.agentInstanceLabel.text = [NSString stringWithFormat:@"AgentInstanceID: %@", agentInstanceId.length > 0 ? agentInstanceId : @"waiting..."];
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

#pragma mark - ZegoAIAgentDigitalHumanEventHandler

- (void)onRemoteVideoFrameRawData:(unsigned char **)data
                       dataLength:(unsigned int *)dataLength
                            param:(ZegoVideoFrameParam *)param
                         streamID:(NSString *)streamID {
    // 处理远程视频帧原始数据
//    NSLog(@"收到远程视频帧数据: streamID=%@, 尺寸=%dx%d", streamID, (int)param.size.width, (int)param.size.height);

    // 转换参数格式并传递给数字人API
    ZDMVideoFrameParam *digitalParam = [[ZDMVideoFrameParam alloc] init];
    digitalParam.format = (ZDMVideoFrameFormat)param.format;
    digitalParam.width = param.size.width;
    digitalParam.height = param.size.height;
    digitalParam.rotation = param.rotation;

    for (int i = 0; i < 4; i++) {
        [digitalParam setStride: param.strides[i] atIndex:i];
    }

    // 如果有数字人实例，传递数据
    if (self.digitalMobile) {
        [self.digitalMobile onRemoteVideoFrameRawData:data dataLength:dataLength param:digitalParam streamID:streamID];
    }
}

- (void)onPlayerSyncRecvSEI:(NSData *)data streamID:(NSString *)streamID {
    // 处理播放器同步接收SEI数据
//    NSLog(@"收到SEI数据: streamID=%@, 数据长度=%lu", streamID, (unsigned long)data.length);

    // 如果有数字人实例，传递SEI数据
    if (self.digitalMobile) {
        [self.digitalMobile onPlayerSyncRecvSEI:streamID data:data];
    }
}

#pragma mark - ZegoDigitalMobileDelegate

- (void)onSurfaceFirstFrameDraw {
    NSLog(@"数字人首帧渲染完成，隐藏 loading 和静态图片");
    [self hideLoading];

    // 隐藏静态图片，显示真实的数字人视频
    dispatch_async(dispatch_get_main_queue(), ^{
        // 设置背景色
        self.digitalView.backgroundColor = [UIColor whiteColor];

        self.staticImageView.hidden = YES;
        NSLog(@"静态图片已隐藏");
    });
}

- (void)onDigitalMobileStartSuccess {
    NSLog(@"数字人启动成功");
    [self updateBroadcastDebugInfo];
}

- (void)onError:(int)errorCode errorMsg:(NSString *)errorMsg {
    NSLog(@"数字人错误: code=%d, msg=%@", errorCode, errorMsg);
    [self hideLoading];
    [self showToast:[NSString stringWithFormat:@"数字人错误: %@", errorMsg]];
}

#pragma mark - Button Actions

- (void)broadcastButtonTapped {
    // 主动收起键盘，避免发送时遮挡渲染区域
    [self.view endEditing:YES];

    NSString *broadcastText = self.broadcastTextField.text ?: @"";
    if (broadcastText.length == 0) {
        [self showToast:@"请输入播报内容"];
        return;
    }

    self.broadcastButton.enabled = NO;
    [self.broadcastLoadingIndicator startAnimating];

    __weak typeof(self) weakSelf = self;
    [[ZegoAIAgentServiceAPI sharedInstance] sendAgentInstanceTTSWithText:broadcastText completion:^(BOOL success, NSInteger errorCode, NSString * _Nullable errorMessage) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;

        strongSelf.broadcastButton.enabled = YES;
        [strongSelf.broadcastLoadingIndicator stopAnimating];

        if (success) {
            [strongSelf showToast:@"播报发送成功"];
        } else {
            [strongSelf showToast:[NSString stringWithFormat:@"播报发送失败: %@", errorMessage ?: @(errorCode)]];
        }
    }];
}

- (void)backButtonTapped {
    [self.view endEditing:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
