//
//  ZegoAIAgentAudioEventHandler.h
//  ai_agent_quickstart
//
//  Created by AI on 2024/12/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @protocol ZegoAIAgentAudioEventHandler
 * @brief 音频智能体事件处理协议
 *
 * 该协议定义了音频智能体相关的事件回调方法，实现此协议的类可以接收和响应
 * 音频智能体产生的各类事件，包括实验性API消息等。
 */
@protocol ZegoAIAgentAudioEventHandler <NSObject>

@optional
/**
 * 接收到实验性API消息
 * @param content API消息内容
 */
- (void)onRecvExperimentalAPI:(NSString *)content;

@end

NS_ASSUME_NONNULL_END
