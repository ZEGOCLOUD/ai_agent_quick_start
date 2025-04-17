//
//  ZegoAIGetTokenRequest.h
//  ai_agent_uikit
//
//  Created by AI on 2024/7/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief 获取ZEGO Token请求类
 * @details 用于向服务器请求ZEGO服务所需的token
 */
@interface ZegoAIGetTokenRequest : NSObject

@property (nonatomic, copy) NSString *userId;  // 用户ID

/**
 * 将对象转换为字典
 * @return 包含请求参数的字典
 */
- (NSDictionary *)toDictionary;

@end

NS_ASSUME_NONNULL_END 