#ifndef ZegoDigitalMobileForAIAgent_h
#define ZegoDigitalMobileForAIAgent_h

#import <Foundation/Foundation.h>
#import <ZegoDigitalMobile/ZegoPreviewView.h>
#import <ZegoDigitalMobile/AuthInfo.h>
#import <ZegoDigitalMobile/ZDMConnectionDelegate.h>
#import <ZegoDigitalMobile/ZegoDigitalMobileStartDelegate.h>

@interface ZegoDigitalMobileForAIAgent : NSObject

- (void)attach:(ZegoPreviewView*)digitalHumanView;

- (void)stop;

- (void)startWithAuthInfo:(AuthInfo*)authInfo
              metaHumanID:(NSString*)metaHumanID
           zegoConnection:(id<ZDMConnectionDelegate>)zegoConnection
               completion:(id<ZegoDigitalMobileStartDelegate>)completion;

@end

#endif // #ifndef ZegoDigitalMobileForAIAgent
