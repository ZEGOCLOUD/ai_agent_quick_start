#import "ZegoAIAgentAudioViewController.h"

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <Masonry/Masonry.h>

#import "ZegoAIAgentServiceAPI.h"
#import "ZegoAIAgentAudioSubtitlesForegroundView.h"

@interface ZegoAIAgentAudioViewController ()

// 前景UI组件
@property (nonatomic, strong) ZegoAIAgentAudioSubtitlesForegroundView *foregroundView;

@end

@implementation ZegoAIAgentAudioViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self setupBackground];
    [self setupForeground];
    [self setupCloseBotton];
    
    __weak typeof(self) weakSelf = self;
    [[ZegoAIAgentServiceAPI sharedInstance] initWithCompletion:^(BOOL success, NSString * _Nullable errorMessage) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        
        if(success) {
            // 开始音频聊天流程
            [strongSelf startAudioChat];
        } else {
            NSLog(@"初始化错误");
        }
    }];
}

- (void)setupBackground{
    // 添加背景图片
    NSString* backgroundURL = @"https://zego-ai.oss-cn-shanghai.aliyuncs.com/agent-avatar/38597_1740990880443-20250303-163355.jpeg";
    UIImageView *backgroundView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    backgroundView.contentMode = UIViewContentModeScaleAspectFill;
    
    // 从URL异步加载背景图片
    NSURL *imageURL = [NSURL URLWithString:backgroundURL];
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithURL:imageURL
                                            completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (data) {
            UIImage *image = [UIImage imageWithData:data];
            if (image) {
                // 在主线程更新UI
                dispatch_async(dispatch_get_main_queue(), ^{
                    backgroundView.image = image;
                });
            }
        }
    }];
    [dataTask resume];
    
    // 添加背景图到视图层次并置于底层
    [self.view addSubview:backgroundView];
    [self.view sendSubviewToBack:backgroundView];
}

- (void)setupForeground {
    // 创建前景UI
    self.foregroundView = [[ZegoAIAgentAudioSubtitlesForegroundView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.foregroundView];
    
    // 设置约束
    [self.foregroundView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
}

- (void)setupCloseBotton{
    // 添加关闭按钮 - 底部中间的红色圆形按钮
    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    closeButton.translatesAutoresizingMaskIntoConstraints = NO;
    closeButton.backgroundColor = [UIColor redColor];
    closeButton.layer.cornerRadius = 25; // 设置为圆形
    closeButton.layer.masksToBounds = YES;
    
    // 创建X图标作为关闭按钮的标识
    [closeButton setTitle:@"✕" forState:UIControlStateNormal];
    [closeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    closeButton.titleLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightBold];
    
    // 添加点击事件
    [closeButton addTarget:self action:@selector(closeButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:closeButton];
    
    // 使用Auto Layout设置按钮位置 - 底部中间
    [NSLayoutConstraint activateConstraints:@[
        [closeButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [closeButton.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-30],
        [closeButton.widthAnchor constraintEqualToConstant:50],
        [closeButton.heightAnchor constraintEqualToConstant:50]
    ]];
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

// 开始音频聊天的方法
- (void)startAudioChat {
    // 1. 请求音频权限
    [self requestAudioPermission:^(BOOL granted) {
        if (!granted) {
            NSLog(@"未获得音频权限");
            return;
        }
        
        // 2. 开始聊天会话
        __weak typeof(self) weakSelf = self;
        [[ZegoAIAgentServiceAPI sharedInstance] startChatWithCompletion:^(BOOL success, NSString * _Nullable errorMessage) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) {
                return;
            }
            
            if (success) {
                NSLog(@"音频聊天开始成功");
                
                if(nil != strongSelf.foregroundView) {
                    [strongSelf.foregroundView updateStatusText:@"已连接"];
                }
            } else {
                NSLog(@"音频聊天开始失败：%@", errorMessage);
            }
        }];
    }];
}

// 视图即将消失时调用
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    // 停止聊天会话
    [self stopChat];
}

// 停止聊天会话
- (void)stopChat {
    // 调用SDK停止聊天
    [[ZegoAIAgentServiceAPI sharedInstance] stopChatWithCompletion:^(BOOL success, NSString * _Nullable errorMessage) {
        if (success) {
            NSLog(@"聊天停止成功");
        } else {
            NSLog(@"聊天停止失败：%@", errorMessage);
        }
    }];
}

// 关闭按钮点击事件处理
- (void)closeButtonClicked {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
