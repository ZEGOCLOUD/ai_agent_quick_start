#ifndef IZegoDigitalMobileRuntime_h
#define IZegoDigitalMobileRuntime_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <ZegoDigitalMobile/ZegoDigitalMobileConfig.h>
#import <ZegoDigitalMobile/IZegoDigitalMobile.h>
#import <ZegoDigitalMobile/ZDMVideoFrameParam.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * 数字人运行时接口
 */
@protocol IZegoDigitalMobileRuntime <NSObject>

/**
 * 初始化运行时
 *
 * @param config 数字人配置
 * @param listener 数字人SDK回调
 */
- (void)initWithConfig:(ZegoDigitalMobileConfig *)config delegate:(nullable id<ZegoDigitalMobileDelegate>)delegate;

/**
 * 绑定预览视图
 *
 * @param view 预览视图
 */
- (void)attach:(UIView *)view;

/**
 * 远端视频帧原始数据回调
 *
 * @param data 视频帧数据数组
 * @param dataLength 每个数据缓冲区的长度数组
 * @param param 视频帧参数，包含格式、分辨率等信息
 * @param streamID 视频流ID
 */
- (void)onRemoteVideoFrameRawData:(unsigned char *_Nonnull *_Nonnull)data
                       dataLength:(unsigned int *)dataLength
                            param:(ZDMVideoFrameParam *)param
                         streamID:(NSString *)streamID;

/**
 * 播放器SEI信息同步接收回调
 *
 * @param streamID 视频流ID
 * @param data SEI数据
 */
- (void)onPlayerSyncRecvSEI:(NSString *)streamID data:(NSData *)data;

/**
 * 销毁运行时
 */
- (void)destroy;

@end

NS_ASSUME_NONNULL_END

#endif /* IZegoDigitalMobileRuntime_h */ 
