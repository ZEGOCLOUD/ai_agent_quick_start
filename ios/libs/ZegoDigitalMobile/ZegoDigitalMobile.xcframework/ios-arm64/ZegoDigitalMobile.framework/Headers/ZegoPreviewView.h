#ifndef ZEGO_DIGITAL_HUMAN_VIEW_H
#define ZEGO_DIGITAL_HUMAN_VIEW_H

#import <UIKit/UIKit.h>

//#import "ZegoFrameData.h"
#import <ZegoDigitalMobile/ZegoFrameData.h>

@interface ZegoPreviewView : UIView

@property(nonatomic, copy) void (^firstFrameCallback)(void);

- (void)drawFrame:(ZegoFrameData *)frameData;

- (void)stop;

@end

#endif // #ifndef ZEGO_DIGITAL_HUMAN_VIEW_H

