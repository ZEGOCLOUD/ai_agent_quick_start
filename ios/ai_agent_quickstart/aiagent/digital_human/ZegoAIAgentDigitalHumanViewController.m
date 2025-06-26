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

@interface ZegoAIAgentDigitalHumanViewController ()<ZegoAIAgentDigitalHumanEventHandler>

// UI组件
@property (nonatomic, strong) UIView *videoContainer;
@property (nonatomic, strong) UIButton *backButton;

@property (nonatomic, strong) id<IZegoDigitalMobile> digitalMobile;
@property (nonatomic, strong) ZegoPreviewView *previewView;

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
    
    self.previewView = nil;
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
    
    [self setupPreviewView];
}

- (void)setupPreviewView {
    // 创建并添加previewView
    self.previewView = [[ZegoPreviewView alloc] init];
    [self.view addSubview:self.previewView];
    
    [self.previewView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
}

- (void)startDigitalHumanChat {
    // 设置自己为数字人事件处理器
    [[ZegoAIAgentServiceAPI sharedInstance] registerDigitalHumanEventHandler:self];

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
                    
                    // 启动数字人
                    [strongSelf.digitalMobile start:@"TODO_digitalHumanEncodeConfig" delegate:strongSelf];
                    
                    // 绑定渲染视图
                    if (strongSelf.previewView) {
                        [strongSelf.digitalMobile attach:strongSelf.previewView];
                    } else {
                        NSLog(@"previewView is nil, cannot attach");
                    }
                }
            } else {
                [strongSelf showToast:[NSString stringWithFormat:@"Failed to start digital human chat: %@", errorMessage]];
            }
        }];
    }];
}

- (void)stopDigitalHumanChat {
    // 清除数字人事件处理器
    [[ZegoAIAgentServiceAPI sharedInstance] registerDigitalHumanEventHandler:nil];

    __weak typeof(self) weakSelf = self;
    [[ZegoAIAgentServiceAPI sharedInstance] stopDigitalHumanWithCompletion:^(BOOL success, NSString * _Nullable errorMessage) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        if (!success) {
            [strongSelf showToast:[NSString stringWithFormat:@"Failed to stop digital human chat: %@", errorMessage]];
        }
    }];
    
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
    NSLog(@"收到远程视频帧数据: streamID=%@, 尺寸=%dx%d", streamID, (int)param.size.width, (int)param.size.height);

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
    NSLog(@"收到SEI数据: streamID=%@, 数据长度=%lu", streamID, (unsigned long)data.length);

    // 如果有数字人实例，传递SEI数据
    if (self.digitalMobile) {
        [self.digitalMobile onPlayerSyncRecvSEI:streamID data:data];
    }
}

#pragma mark - Button Actions

- (void)backButtonTapped {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
