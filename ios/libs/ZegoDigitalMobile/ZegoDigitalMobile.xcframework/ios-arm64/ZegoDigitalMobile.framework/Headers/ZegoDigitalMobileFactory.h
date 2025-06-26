#ifndef ZegoDigitalMobileFactory_h
#define ZegoDigitalMobileFactory_h

#import <ZegoDigitalMobile/ZegoDigitalMobileForAIAgent.h>
#import <ZegoDigitalMobile/ZegoDigitalMobileForWebDemo.h>
#import <ZegoDigitalMobile/ZegoDigitalMobileImpl.h>

@interface ZegoDigitalMobileFactory : NSObject

/**
 * 创建通用数字人API实现
 */
+ (id<IZegoDigitalMobile>)create;


@end

#endif
