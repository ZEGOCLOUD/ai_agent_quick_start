#ifndef ZegoROIRuntime_h
#define ZegoROIRuntime_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <ZegoDigitalMobile/IZegoDigitalMobileRuntime.h>
#import <ZegoDigitalMobile/IZegoDigitalMobile.h>
#import <ZegoDigitalMobile/ZegoPreviewView.h>
#import <ZegoDigitalMobile/ZegoFrameData.h>
#import <ZegoDigitalMobile/ZegoDigitalMobileConfig.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * ROI运行时实现
 * 用于处理移动端特定的数字人渲染
 */
@interface ZegoROIRuntime : NSObject <IZegoDigitalMobileRuntime>

/**
 * 数字人SDK回调
 */
@property (nonatomic, weak) id<ZegoDigitalMobileDelegate> delegate;

/**
 * 数字人配置
 */
@property (nonatomic, strong) ZegoDigitalMobileConfig *config;


/**
 * 帧数据
 */
@property (nonatomic, strong) ZegoFrameData *frameData;

/**
 * ZegoPreviewView实例
 */
@property (nonatomic, weak) ZegoPreviewView *zegoPreviewView;

/**
 * 初始化ROI运行时
 */
- (instancetype)init;

@end

NS_ASSUME_NONNULL_END

#endif /* ZegoROIRuntime_h */ 
