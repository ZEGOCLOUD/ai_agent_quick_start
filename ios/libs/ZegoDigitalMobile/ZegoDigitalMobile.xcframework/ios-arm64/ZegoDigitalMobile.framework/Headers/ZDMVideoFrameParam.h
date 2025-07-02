#ifndef ZDMVideoFrameParam_h
#define ZDMVideoFrameParam_h

#import <Foundation/Foundation.h>
#import <ZegoDigitalMobile/IZegoDigitalMobile.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * 视频帧参数
 */
@interface ZDMVideoFrameParam : NSObject

/**
 * 视频帧格式
 */
@property (nonatomic, assign) ZDMVideoFrameFormat format;

/**
 * 获取指定索引的步长值
 *
 * @param index 索引，范围为0-3
 * @return 步长值
 */
- (int)strideAtIndex:(int)index;

/**
 * 设置指定索引的步长值
 *
 * @param stride 步长值
 * @param index 索引，范围为0-3
 */
- (void)setStride:(int)stride atIndex:(int)index;

/**
 * 视频帧宽度
 */
@property (nonatomic, assign) int width;

/**
 * 视频帧高度
 */
@property (nonatomic, assign) int height;

/**
 * 视频帧旋转角度
 */
@property (nonatomic, assign) int rotation;

@end

NS_ASSUME_NONNULL_END

#endif /* ZDMVideoFrameParam_h */ 
