#ifndef ZegoDigitalMobileImpl_h
#define ZegoDigitalMobileImpl_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <ZegoDigitalMobile/IZegoDigitalMobile.h>
#import <ZegoDigitalMobile/ZegoPreviewView.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * 数字人SDK实现类
 */
@interface ZegoDigitalMobileImpl : NSObject <IZegoDigitalMobile>

/**
 * 数字人回调
 */
@property (nonatomic, weak) id<ZegoDigitalMobileDelegate> delegate;

/**
 * 预览视图
 */
@property (nonatomic, weak) UIView *previewView;

/**
 * 创建数字人任务。
 *
 * @param digitalHumanConfig 数字人配置
 * @param listener 数字人SDK回调
 */
- (void)start:(NSString *)digitalHumanConfig delegate:(nullable id<ZegoDigitalMobileDelegate>)delegate;

/**
 * 绑定预览view
 *
 * @param previewView 预览view
 */
- (void)attach:(UIView *)previewView;

/**
 * 远端视频帧原始数据回调。当收到远端视频流的原始帧数据时调用此回调。
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
 * 播放器SEI信息同步接收回调。当播放器接收到SEI信息时调用此回调。
 *
 * @param streamID 视频流ID
 * @param data SEI数据
 */
- (void)onPlayerSyncRecvSEI:(NSString *)streamID data:(NSData *)data;

/**
 * 停止数字人
 */
- (void)stop;

@end

NS_ASSUME_NONNULL_END

#endif /* ZegoDigitalMobileImpl_h */ 
