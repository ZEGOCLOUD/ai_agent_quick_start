#ifndef DigitalMobileConfigDecoder_h
#define DigitalMobileConfigDecoder_h

#import <Foundation/Foundation.h>
#import <ZegoDigitalMobile/ZegoDigitalMobileConfig.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * 数字人配置解析工具类
 */
@interface ZegoDigitalMobileConfigDecoder : NSObject



/**
 * 解析配置字符串
 *
 * @param configStr 配置字符串（Base64编码的JSON）
 * @return 数字人配置对象，解析失败返回nil
 */
+ (nullable ZegoDigitalMobileConfig *)decode:(NSString *)configStr;

@end

NS_ASSUME_NONNULL_END

#endif /* DigitalMobileConfigDecoder_h */ 
