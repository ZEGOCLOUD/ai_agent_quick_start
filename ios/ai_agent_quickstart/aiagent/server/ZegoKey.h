//
//  ZegoKey.h
//  ai_agent_express
//
//  Created by AI on 2024/7/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @class ZegoKey
 * @brief ZEGO PASS服务密钥和配置参数管理类
 *
 * 该类集中管理所有与ZEGO PASS服务访问相关的密钥和配置常量，
 * 包括认证信息、LLM配置和TTS参数等。
 * 作为统一的密钥管理入口，便于安全管理和更新这些敏感信息。
 */
@interface ZegoKey : NSObject

// 前往 [ZEGO 控制台](https://console.zegocloud.com/) 创建项目.
// 获取 **AppID**，**AppSign** 和**AppSecret**

// Auth Keys
/// ZEGO分配的应用ID，用于身份认证
extern unsigned int const kZegoAppId;

@end

NS_ASSUME_NONNULL_END 
