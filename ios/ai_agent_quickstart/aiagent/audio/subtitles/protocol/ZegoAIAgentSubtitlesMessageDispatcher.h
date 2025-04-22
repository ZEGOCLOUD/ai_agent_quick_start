//
//  ZegoAIAgentChatMessageDispatcher.h
//  ai_agent_uikit
//
//  Created on 2024/7/15.
//  Copyright © 2024 Zego. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ZegoAIAgentSubtitlesEventHandler.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * 聊天消息分发器
 * 负责解析处理聊天消息，并将消息分发给注册的事件处理对象
 */
@interface ZegoAIAgentSubtitlesMessageDispatcher : NSObject

/**
 * 获取单例对象
 */
+ (instancetype)sharedInstance;

/**
 * 注册聊天事件处理对象
 * @param handler 聊天事件处理对象
 */
- (void)registerEventHandler:(id<ZegoAIAgentSubtitlesEventHandler>)handler;

/**
 * 注销聊天事件处理对象
 * @param handler 聊天事件处理对象
 */
- (void)unregisterEventHandler:(id<ZegoAIAgentSubtitlesEventHandler>)handler;


/**
* 处理express onRecvExperimentalAPI接收到的消息
 * @param content 回调内容，JSON 格式字符串
 * @param handler 解析成功后的回调，传入解析后的消息内容和发送者
 * @return 是否成功解析
*/
- (void)handleExpressExperimentalAPIContent:(NSString *)content;
@end

NS_ASSUME_NONNULL_END 
