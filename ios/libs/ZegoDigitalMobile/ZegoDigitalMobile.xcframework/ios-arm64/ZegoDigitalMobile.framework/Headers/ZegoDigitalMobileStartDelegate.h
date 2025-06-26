#ifndef ZegoDigitalMobileInitCompletion_h
#define ZegoDigitalMobileInitCompletion_h

#import <Foundation/Foundation.h>

@protocol ZegoDigitalMobileStartDelegate <NSObject>

@required
- (void)onDigitalMobileStartSuccess;
- (void)onDigitalMobileStartFail:(NSInteger)errorCode errorMsg:(NSString *)errorMsg;

@optional
- (void)onDigitalMobileFirstFrameDraw;

@end

#endif /* ZegoDigitalMobileInitCompletion_h */
