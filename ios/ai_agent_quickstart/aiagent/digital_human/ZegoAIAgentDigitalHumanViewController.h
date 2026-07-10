//
//  ZegoAIAgentDigitalHumanViewController.h
//  ai_agent_quickstart
//
//  Created by Zego 2024/12/26.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @enum ZegoAIAgentDigitalHumanMode
 * @brief 数字人页面模式
 *
 * 用于区分数字人对话与数字人播报两种场景，
 * 让同一个页面复用渲染逻辑但执行不同的启动流程。
 */
typedef NS_ENUM(NSInteger, ZegoAIAgentDigitalHumanMode) {
    /// 数字人对话模式
    ZegoAIAgentDigitalHumanModeInteractive = 0,
    /// 数字人播报模式
    ZegoAIAgentDigitalHumanModeLiveBroadcast = 1,
};

/**
 * @class ZegoAIAgentDigitalHumanViewController
 * @brief 数字人智能体对话视图控制器
 *
 * 该类负责呈现和管理与数字人AI智能体的交互界面，包括视频显示和语音交互。
 * 它处理视频渲染、音频权限请求、建立与ZEGO AI服务的连接、管理对话生命周期，
 * 并提供友好的用户界面以展示数字人AI智能体的视觉和语音回复。
 */
@interface ZegoAIAgentDigitalHumanViewController : UIViewController

/// 当前页面使用的数字人模式，默认值为对话模式
@property (nonatomic, assign) ZegoAIAgentDigitalHumanMode mode;

@end

NS_ASSUME_NONNULL_END
