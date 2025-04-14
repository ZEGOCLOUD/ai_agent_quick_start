//
//  ViewController.m
//  ai_agent_quickstart
//
//  Created by yoer on 2025/4/10.
//

#import "ViewController.h"

#import "ZegoAIAgentAudioViewController.h"

@interface ViewController ()

@property (nonatomic, strong) UIButton *audioButton;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 设置背景色为白色
    self.view.backgroundColor = [UIColor whiteColor];
    
    // 创建音频聊天按钮
    self.audioButton = [self createStyledButton:@"开始音频聊天" action:@selector(startAudioChat)];
    
    // 设置按钮位置（居中）
    CGFloat screenWidth = CGRectGetWidth(self.view.bounds);
    CGFloat screenHeight = CGRectGetHeight(self.view.bounds);
    CGFloat buttonWidth = 200.0f;
    CGFloat buttonHeight = 50.0f;
    
    // 计算按钮的中心位置
    CGFloat centerX = screenWidth / 2;
    CGFloat centerY = screenHeight / 2;
    
    // 设置按钮位置
    self.audioButton.center = CGPointMake(centerX, centerY);
    
    // 添加按钮到视图
    [self.view addSubview:self.audioButton];
}

// 创建统一样式的按钮
- (UIButton *)createStyledButton:(NSString *)title action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    
    // 设置按钮尺寸
    button.frame = CGRectMake(0, 0, 200, 50);
    
    // 设置标题
    [button setTitle:title forState:UIControlStateNormal];
    
    // 设置样式
    button.backgroundColor = [UIColor systemBlueColor]; // 使用系统蓝色
    button.layer.cornerRadius = 25.0f; // 圆角
    button.layer.masksToBounds = YES;
    
    // 设置字体
    button.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    
    // 设置不同状态下的颜色
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button setTitleColor:[[UIColor whiteColor] colorWithAlphaComponent:0.7] forState:UIControlStateHighlighted];
    
    // 添加点击事件
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    
    // 添加阴影效果
    button.layer.shadowColor = [UIColor blackColor].CGColor;
    button.layer.shadowOffset = CGSizeMake(0, 2);
    button.layer.shadowRadius = 4.0;
    button.layer.shadowOpacity = 0.1;
    
    return button;
}

#pragma mark - Button Actions

- (void)startAudioChat {
    ZegoAIAgentAudioViewController *audioChatVC = [[ZegoAIAgentAudioViewController alloc] init];
    // 使用全屏模态展示
    audioChatVC.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:audioChatVC animated:YES completion:nil];
}

@end
