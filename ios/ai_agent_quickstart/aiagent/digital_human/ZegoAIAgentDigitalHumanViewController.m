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

// loading
@property (nonatomic, strong) UIView *loadingView;
@property (nonatomic, strong) UIActivityIndicatorView *loadingIndicator;
@property (nonatomic, strong) UILabel *loadingLabel;

// digital human
@property (nonatomic, strong) id<IZegoDigitalMobile> digitalMobile;
@property (nonatomic, strong) ZegoPreviewView *previewView;

// 静态图片视图
@property (nonatomic, strong) UIImageView *staticImageView;

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

    self.previewView = nil;
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
}

- (void)setupPreviewView {
    // 创建并添加previewView
    self.previewView = [[ZegoPreviewView alloc] init];

    // 设置透明背景，让底层的静态图片可以显示
    self.previewView.backgroundColor = [UIColor clearColor];

    [self.view addSubview:self.previewView];

    // previewView全屏显示
    [self.previewView mas_makeConstraints:^(MASConstraintMaker *make) {
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
    [self.view insertSubview:self.staticImageView belowSubview:self.previewView];

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
                // 创建数字人实例
                strongSelf.digitalMobile = [ZegoDigitalMobileFactory create];
                if (!strongSelf.digitalMobile) {
                    [strongSelf showToast:@"创建数字人实例失败"];
                } else {
                    // 启动数字人（设置委托时再次检查页面状态）
                    if (!strongSelf.view.window) {
                        // 页面已经不在显示，清理资源
                        strongSelf.digitalMobile = nil;
                        NSLog(@"Page dismissed, cleaning up digital mobile instance");
                        return;
                    }

                    // 启动数字人，使用返回的配置（可能包含服务器返回的 digital_human_config）
                    NSString *configToUse = digitalHumanEncodeConfig ?: @"";
                    NSLog(@"使用数字人配置: %@", configToUse);
                    [strongSelf.digitalMobile start:configToUse delegate:strongSelf];

                    // 绑定渲染视图
                    if (strongSelf.previewView) {
                        NSLog(@"开始绑定数字人到 previewView，frame: %@", NSStringFromCGRect(strongSelf.previewView.frame));
                        [strongSelf.digitalMobile attach:strongSelf.previewView];
                        NSLog(@"数字人已绑定到 previewView");
                    } else {
                        NSLog(@"previewView is nil, cannot attach");
                    }
                }
            } else {
                [strongSelf hideLoading];
                [strongSelf showToast:[NSString stringWithFormat:@"Failed to start digital human chat: %@", errorMessage]];
            }
        }];
    }];
}

- (void)stopDigitalHumanChat {
    // 清除数字人事件处理器
    [[ZegoAIAgentServiceAPI sharedInstance] registerDigitalHumanEventHandler:nil];

    [[ZegoAIAgentServiceAPI sharedInstance] stopDigitalHumanWithCompletion:nil];
    
    // 清理digitalMobile
    if (self.digitalMobile) {
        // 停止数字人
        [self.digitalMobile stop];
        
        self.digitalMobile = nil;
    }
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
        self.previewView.backgroundColor = [UIColor whiteColor];

        self.staticImageView.hidden = YES;
        NSLog(@"静态图片已隐藏");
    });
}

- (void)onDigitalMobileStartSuccess {
    NSLog(@"数字人启动成功");
}

- (void)onError:(int)errorCode errorMsg:(NSString *)errorMsg {
    NSLog(@"数字人错误: code=%d, msg=%@", errorCode, errorMsg);
    [self hideLoading];
    [self showToast:[NSString stringWithFormat:@"数字人错误: %@", errorMsg]];
}

#pragma mark - Button Actions

- (void)backButtonTapped {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
