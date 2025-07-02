#ifndef ZEGO_FRAME_DATA_H
#define ZEGO_FRAME_DATA_H

#import <Foundation/Foundation.h>

@interface ZegoFrameData : NSObject

// roi frame from RTC, RGB
@property(nonatomic, strong) NSMutableData *roiData;
@property(nonatomic, assign) NSInteger roiWidth;
@property(nonatomic, assign) NSInteger roiHeight;

// origin frame, RGBA
@property(nonatomic, strong) NSMutableData *originFrameData;
@property(nonatomic, assign) NSInteger originFrameWidth;
@property(nonatomic, assign) NSInteger originFrameHeight;

// SEI information
@property(nonatomic, assign) NSInteger fps;
@property(nonatomic, assign) NSInteger type;            // 0: normal, 1: interpolation
@property(nonatomic, assign) NSInteger startIndex;
@property(nonatomic, assign) NSInteger endIndex;
@property(nonatomic, assign) NSInteger frameIndex;
@property(nonatomic, assign) NSInteger left;
@property(nonatomic, assign) NSInteger top;
@property(nonatomic, assign) NSInteger right;
@property(nonatomic, assign) NSInteger bottom;

- (void)updateSEI:(NSData *)data;

- (void)updateROIFrame:(const void *)data
                 length:(NSUInteger)length
                  width:(int)width
                 height:(int)height;

- (void)updateOriginFrame:(NSMutableData *)data
                    width:(int)width
                   height:(int)height;
@end

#endif // #ifndef ZEGO_FRAME_DATA_H
