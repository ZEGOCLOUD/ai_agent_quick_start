//
//  ZegoAIServiceCommonResponse.h
//  ai_agent_uikit
//
//  Created by AI on 2024/7/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @class ZegoAIServiceCommonResponse
 * @brief 服务响应通用类
 *
 * 该类定义了所有API响应的基础结构，包含必要的状态码、消息和数据。
 * 所有具体的响应类都应该继承自该基类，以保持接口一致性。
 */
@interface ZegoAIServiceCommonResponse : NSObject

/// 响应状态码，0表示成功，非0表示错误
@property (nonatomic, assign) NSInteger code;

/// 响应消息，成功或错误的描述信息
@property (nonatomic, copy, nullable) NSString *message;

/// 请求ID，用于跟踪和调试
@property (nonatomic, copy, nullable) NSString *requestId;

/// 响应数据，可以是任何类型
@property (nonatomic, strong, nullable) id data;

/**
 * 判断响应是否成功
 * @return 如果状态码为0，返回YES；否则返回NO
 */
- (BOOL)isSuccess;

/**
 * 设置通用请求头
 * @param request 需要设置头部的NSMutableURLRequest对象
 */
- (void)applyToRequest:(NSMutableURLRequest *)request;

@end

/**
 * @class ZegoAIServiceCommonHeader
 * @brief 服务请求通用头部类
 *
 * 为所有API请求提供统一的头部设置，确保认证和格式一致。
 */
@interface ZegoAIServiceCommonHeader : NSObject

/**
 * 设置通用请求头
 * @param request 需要设置头部的NSMutableURLRequest对象
 *
 * 此方法会给请求添加通用头部，包括但不限于：
 * - Content-Type: application/json
 * - Authorization: 如果需要认证信息
 * - User-Agent: 客户端标识
 * - 其他必要的元数据
 */
- (void)applyToRequest:(NSMutableURLRequest *)request;

@end

NS_ASSUME_NONNULL_END 