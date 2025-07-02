#ifndef ZegoHeadPreviewView_h
#define ZegoHeadPreviewView_h

//#import "ZegoPreviewView.h"
#import <ZegoDigitalMobile/ZegoPreviewView.h>

@interface ZegoHeadPreviewView : ZegoPreviewView

/**
 * @param radius 渲染的相对半径，取值范围为 [0.0, 1.0]，小于 0 取 0，大于 1 取 1
 */
- (void) updateRadiusRatio: (float)radius;


/**
 * 边框宽度相对于渲染半径的权重，取值范围为 [0.0, 1.0]，小于 0 取 0，大于 1 取 1
 */
- (void)updateBorderWeight: (float) weight;

@end

#endif
