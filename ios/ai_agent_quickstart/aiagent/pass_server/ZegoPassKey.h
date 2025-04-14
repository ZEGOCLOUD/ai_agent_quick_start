//
//  ZegoPassKey.h
//  ai_agent_express
//
//  Created by AI on 2024/7/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @class ZegoPassKey
 * @brief ZEGO PASS服务密钥和配置参数管理类
 *
 * 该类集中管理所有与ZEGO PASS服务访问相关的密钥和配置常量，
 * 包括认证信息、LLM配置和TTS参数等。
 * 作为统一的密钥管理入口，便于安全管理和更新这些敏感信息。
 */
@interface ZegoPassKey : NSObject

// 前往 [ZEGO 控制台](https://console.zegocloud.com/) 创建项目.
// 获取 **AppID**，**AppSign** 和**AppSecret**

// Auth Keys
/// ZEGO分配的应用ID，用于身份认证
extern unsigned int const kZegoPassAppId;
/// ZEGO分配的应用签名，用于加密通信
extern NSString * const kZegoPassAppSign;
/// ZEGO分配的应用密钥，用于服务器端验证
extern NSString * const kZegoPassAppSecret;

// LLM Keys
/// 大语言模型API密钥，用于访问LLM服务
extern NSString * const kZegoPassLLMApiKey;
/// 大语言模型服务URL，指定LLM服务的API端点
extern NSString * const kZegoPassLLMUrl;
/// 使用的语言模型名称，如gpt-4、claude等
extern NSString * const kZegoPassLLMModel;

// TTS Params
/// 文本转语音服务提供商，如azure、elevenlabs等
extern NSString * const kZegoPassTTSVendor;
/**
 * 获取文本转语音参数
 * @return 包含TTS配置的参数字典
 */
+ (NSDictionary *)zegoPassTTSParams;

@end

NS_ASSUME_NONNULL_END 
