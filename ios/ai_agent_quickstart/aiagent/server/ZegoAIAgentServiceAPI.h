//
//  ZegoAIAgentServiceAPI.h
//  ai_agent_uikit
//
//  Created by AI on 2024/7/14.
//

#import <Foundation/Foundation.h>
#import "ZegoAIServiceCommonResponse.h"
#import "ZegoAIRegisterAgentResponse.h"
#import "ZegoAICreateAgentInstanceResponse.h"
#import "ZegoAIGetTokenResponse.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * @class ZegoAIAgentServiceAPI
 * @brief 智能体服务API封装类
 *
 * 该类封装了与ZEGO AI智能体服务交互的所有API，作为客户端与服务器之间的通信桥梁。
 * 提供智能体初始化、会话创建、交互和终止等功能，使用单例模式确保全局唯一实例。
 * 所有与智能体服务相关的操作都应通过此类进行，它处理底层通信细节和状态管理。
 */
@interface ZegoAIAgentServiceAPI : NSObject

/**
 * 单例方法
 * @return ZegoPassServiceAPI的全局唯一实例
 *
 * 使用单例模式确保在整个应用生命周期中只存在一个服务API实例，
 * 避免多实例导致的资源冲突和状态不一致问题
 */
+ (instancetype)sharedInstance;

/**
 * 初始化方法
 * 会去创建智能体
 * @param completion 初始化完成的回调
 *
 * 此方法执行服务API的初始化流程，包括：
 * 1. 准备必要的认证信息
 * 2. 建立与ZEGO服务器的连接
 * 3. 注册智能体并创建实例
 * 4. 回调通知初始化结果
 */
- (void)initWithCompletion:(void (^)(BOOL success, NSString * _Nullable errorMessage))completion;

/**
 * 开始与智能体聊天
 * @param completion 开始聊天的回调，成功返回agentInstanceId
 *
 * 此方法启动与AI智能体的会话交互，包括：
 * 1. 准备音频流和处理管道
 * 2. 连接到已创建的智能体实例
 * 3. 建立双向通信通道
 * 4. 开始接收和处理音频/文本数据
 */
- (void)startChatWithCompletion:(void (^)(BOOL success, NSString * _Nullable errorMessage))completion;

/**
 * 停止与智能体聊天
 * @param completion 停止聊天的回调
 *
 * 此方法终止与AI智能体的会话交互，包括：
 * 1. 关闭音频流和处理管道
 * 2. 断开与智能体实例的连接
 * 3. 清理会话资源
 * 4. 回调通知会话终止结果
 */
- (void)stopChatWithCompletion:(void (^)(BOOL success, NSString * _Nullable errorMessage))completion;

@end

NS_ASSUME_NONNULL_END 
