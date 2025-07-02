#ifndef ZegoDigitalMobileForWebDemo_h
#define ZegoDigitalMobileForWebDemo_h

#import <Foundation/Foundation.h>
#import <ZegoDigitalMobile/ZegoRTCOptions.h>
#import <ZegoDigitalMobile/ZegoDigitalMobileStartDelegate.h>
#import <ZegoDigitalMobile/ZegoPreviewView.h>

@interface ZegoDigitalMobileForWebDemo : NSObject

- (void)setResource:(NSString *)resourcePath;

- (void)attach:(ZegoPreviewView*)digitalHumanView;

- (void)stop;

/**
 * @param appID 应用 appID
 * @param appSign     应用 appSign
 * @param rtcOptions  rtc 相关选项
 * @param completion    初始化回调
 */
- (void)startWithAppID:(NSString *)appID
               appSign:(NSString *)appSign
            rtcOptions:(ZegoRTCOptions *)rtcOptions
               modelID:(NSString *)modelID
            delegate:(id<ZegoDigitalMobileStartDelegate>)delegate;

@end

#endif // #ifndef ZegoDigitalMobileForWebDemo_h

