#ifndef ZEGO_DIGITAL_MOBILE_ERRORS_H
#define ZEGO_DIGITAL_MOBILE_ERRORS_H

#import <Foundation/Foundation.h>

extern NSString *ERROR_DOMAIN;

/**
 * 数字人错误码
 */
typedef NS_ENUM(NSInteger, ZegoDigitalMobileError) {
    ZegoDigitalMobileErrorSuccess       = 0,                // 成功
    ZegoDigitalMobileErrorInvalidParam  = -200000,          // 错误：参数错误
    ZegoDigitalMobileErrorLoadResource  = -200001,          // 错误：加载资源错误
    ZegoDigitalMobileErrorBackend       = -200002,          // 错误：后台错误
    ZegoDigitalMobileErrorNetwork       = -200003,          // 错误：网络错误
    ZegoDigitalMobileErrorTimeout       = -200004,          // 错误：超时
    ZegoDigitalMobileErrorInternal      = -200005,          // 错误：内部错误
    ZegoDigitalMobileErrorDuplicatedStart = -200006,        // 错误：重复启动错误
};

// 保留旧的错误码枚举，确保向后兼容
typedef NS_ENUM(NSInteger, ZegoDigtalMobileResult) {
    Success = 0,                 // 成功
    LoadResourceError = -200000, // 错误：加载资源错误
    BackendError = -200001       // 错误：后台错误
};

#endif // #ifndef ZEGO_DIGITAL_MOBILE_ERRORS_H
