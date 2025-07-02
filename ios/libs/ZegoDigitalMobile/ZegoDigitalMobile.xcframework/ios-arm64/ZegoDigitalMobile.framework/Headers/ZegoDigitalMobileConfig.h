#ifndef DigitalMobileConfig_h
#define DigitalMobileConfig_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * 流配置
 */
@interface ZegoDigitalMobileStream : NSObject

/**
 * 房间ID
 */
@property (nonatomic, copy) NSString *roomId;

/**
 * 流ID
 */
@property (nonatomic, copy) NSString *streamId;

/**
 * 编码码
 */
@property (nonatomic, copy) NSString *encodeCode;

/**
 * 包URL
 */
@property (nonatomic, copy) NSString *packageUrl;

/**
 * 平台
 */
@property (nonatomic, copy) NSString *configId;

/**
 * 获取描述
 */
- (NSString *)string;

@end

/**
 * 数字人配置类
 */
@interface ZegoDigitalMobileConfig : NSObject

/**
 * Web类型
 */
extern NSString * const STREAM_TYPE_WEB;

/**
 * 移动端类型
 */
extern NSString * const STREAM_TYPE_MOBILE;

/**
 * 数字人ID
 */
@property (nonatomic, copy) NSString *digitalHumanId;

/**
 * 流数组
 */
@property (nonatomic, strong) NSArray<ZegoDigitalMobileStream *> *streams;

/**
 * 适合的流（缓存）
 */
@property (nonatomic, strong, nullable) ZegoDigitalMobileStream *fitStream;

/**
 * 获取适合的流
 *
 * @return 适合的流
 */
- (nullable ZegoDigitalMobileStream *)getFitStream;

/**
 * 检查配置是否有效
 *
 * @return 配置是否有效
 */
- (BOOL)isValid;

/**
 * 获取配置描述
 *
 * @return 配置描述
 */
- (NSString *)string;

@end

NS_ASSUME_NONNULL_END

#endif /* DigitalMobileConfig_h */ 
