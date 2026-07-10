//
//  ZegoAIAgentServiceAPI.h
//  ai_agent_uikit
//
//  Created by AI on 2024/7/14.
//

#import <Foundation/Foundation.h>

#import "ZegoAIServiceCommonResponse.h"
#import "ZegoAIGetTokenResponse.h"

#import "ZegoAIAgentAudioEventHandler.h"
#import "ZegoAIAgentDigitalHumanEventHandler.h"

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
 * 获取当前智能体ID
 * @return 智能体ID
 */
- (NSString *)getAgentId;

/**
 * 获取当前智能体实例ID
 * @return 智能体实例ID
 */
- (NSString *)getAgentInstanceId;

/**
 * 获取当前智能体用户ID
 * @return 智能体在RTC房间内的用户ID
 */
- (NSString *)getAgentUserId;

/**
 * 获取当前用户ID
 * @return 用户ID
 */
- (NSString *)getUserId;

/**
 * 注册音频事件处理器
 * @param handler 音频事件处理器
 */
- (void)registerAudioEventHandler:(id<ZegoAIAgentAudioEventHandler>)handler;

/**
 * 注册数字人事件处理器
 * @param handler 数字人事件处理器
 */
- (void)registerDigitalHumanEventHandler:(id<ZegoAIAgentDigitalHumanEventHandler>)handler;

/**
 * 获取当前房间ID
 * @return 房间ID
 */
- (NSString *)getRoomId;

/**
 * 开始与数字人聊天
 * @param digitalHumanId 数字人ID，可选参数
 * @param configId 配置ID，可选参数
 * @param completion 开始聊天的回调，成功返回digitalHumanEncodeConfig
 */
- (void)startDigitalHumanWithCompletion:(void (^)(BOOL success, NSInteger errorCode, NSString * _Nullable errorMessage, NSString * _Nullable digitalHumanEncodeConfig))completion;

/**
 * 开始播报数字人
 * @param completion 开始播报数字人的回调，成功返回数字人配置
 */
- (void)startLiveDigitalHumanWithCompletion:(void (^)(BOOL success, NSInteger errorCode, NSString * _Nullable errorMessage, NSString * _Nullable digitalHumanEncodeConfig))completion;

/**
 * 结束数字人聊天
 * @param completion 停止聊天的回调
 */
- (void)stopDigitalHumanWithCompletion:(void (^)(BOOL success, NSInteger errorCode, NSString * _Nullable errorMessage))completion;

/**
 * 结束播报数字人
 * @param completion 停止播报数字人的回调
 */
- (void)stopLiveDigitalHumanWithCompletion:(void (^)(BOOL success, NSInteger errorCode, NSString * _Nullable errorMessage))completion;

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
- (void)startAudioWithCompletion:(void (^)(BOOL success, NSInteger errorCode, NSString * _Nullable errorMessage))completion;

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
- (void)stopAudioWithCompletion:(void (^)(BOOL success, NSInteger errorCode, NSString * _Nullable errorMessage))completion;

/**
 * 向播报数字人实例发送自定义TTS内容
 * @param text 需要播报的文本内容
 * @param completion 发送结果回调
 */
- (void)sendAgentInstanceTTSWithText:(NSString *)text
                          completion:(void (^)(BOOL success, NSInteger errorCode, NSString * _Nullable errorMessage))completion;

/**
 * 获取Token
 */
- (void)getTokenWithCompletion:(void (^)(ZegoAIGetTokenResponse *response))completion;

/**
 * 兜底退出 RTC 房间（幂等）
 *
 * 视图层在销毁（pop/dismiss/dealloc）时如果发现用户没有手动 logout，
 * 应调用本方法安全释放 RTC 资源。本方法内部已做幂等处理：
 * - 若未登录过房间，直接返回；
 * - 若已 logout，再次调用也直接返回；
 * - 不会与 stopAudio/stopDigitalHuman 的 logout 流程产生重复调用。
 */
- (void)ensureLogoutRoom;

@end

NS_ASSUME_NONNULL_END 
