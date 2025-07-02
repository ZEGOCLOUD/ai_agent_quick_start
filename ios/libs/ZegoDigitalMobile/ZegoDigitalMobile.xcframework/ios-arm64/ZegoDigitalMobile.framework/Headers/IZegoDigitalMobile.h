//
//  IZegoDigitalMobile.h
//  ZegoDigitalMobile 数字人移动端SDK接口定义
//
//  Created by zego on 2025/1/20.
//  Copyright © 2024 Zego. All rights reserved.
//

#ifndef IZegoDigitalMobile_h
#define IZegoDigitalMobile_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * 视频帧格式枚举
 * 
 * 定义数字人SDK支持的各种视频帧格式，用于视频数据的编码和解码
 */
typedef NS_ENUM(NSInteger, ZDMVideoFrameFormat) {
    ZDMVideoFrameFormatUnknown = 0,     ///< 未知格式
    ZDMVideoFrameFormatI420 = 1,        ///< I420格式，YUV420平面格式
    ZDMVideoFrameFormatNV12 = 2,        ///< NV12格式，YUV420半平面格式
    ZDMVideoFrameFormatNV21 = 3,        ///< NV21格式，YVU420半平面格式
    ZDMVideoFrameFormatBGRA32 = 4,      ///< BGRA32格式，32位BGRA格式
    ZDMVideoFrameFormatRGBA32 = 5,      ///< RGBA32格式，32位RGBA格式
    ZDMVideoFrameFormatARGB32 = 6,      ///< ARGB32格式，32位ARGB格式
    ZDMVideoFrameFormatABGR32 = 7,      ///< ABGR32格式，32位ABGR格式
    ZDMVideoFrameFormatI422 = 8,        ///< I422格式，YUV422平面格式
    ZDMVideoFrameFormatBGR24 = 9,       ///< BGR24格式，24位BGR格式
    ZDMVideoFrameFormatRGB24 = 10       ///< RGB24格式，24位RGB格式
};

// 前向声明
@class ZDMVideoFrameParam;
@class ZegoVideoFrameParam;

/**
 * 数字人SDK回调协议
 * 
 * 定义数字人SDK的各种事件回调，用于通知应用层数字人的状态变化和事件
 */
@protocol ZegoDigitalMobileDelegate <NSObject>

/**
 * 数字人创建成功回调
 * 
 * 当数字人SDK成功启动并准备就绪时触发此回调
 */
- (void)onDigitalMobileStartSuccess;

/**
 * 错误回调
 * 
 * 当数字人SDK运行过程中发生错误时触发此回调
 * @param errorCode 错误码，用于标识具体的错误类型
 * @param errorMsg 错误信息描述，提供详细的错误说明
 */
- (void)onError:(int)errorCode errorMsg:(NSString *)errorMsg;

/**
 * Surface首帧渲染回调
 * 
 * 当数字人视频首帧开始渲染时触发此回调。
 * 客户可以监听此回调在首帧渲染前设置loading view，避免预览视图出现黑屏闪烁
 */
- (void)onSurfaceFirstFrameDraw;

@end

/**
 * 数字人SDK核心接口协议
 * 
 * 定义数字人移动端SDK的核心功能接口，包括数字人的创建、控制、
 * 视频渲染、数据回调等主要功能
 */
@protocol IZegoDigitalMobile <NSObject>

/**
 * 启动数字人任务
 * 
 * 根据指定的配置启动数字人服务，建立数字人实例并开始运行
 * @param digitalHumanConfig 数字人配置字符串，包含数字人的各种参数设置
 * @param delegate 数字人SDK事件回调代理，用于接收状态变化和错误通知，可选参数
 */
- (void)start:(NSString *)digitalHumanConfig delegate:(nullable id<ZegoDigitalMobileDelegate>)delegate;

/**
 * 绑定预览视图
 * 
 * 将数字人的视频输出绑定到指定的UI视图上进行显示
 * @param previewView 用于显示数字人视频的预览视图
 */
- (void)attach:(UIView *)previewView;

/**
 * 远端视频帧原始数据回调
 * 
 * 当接收到远端数字人视频流的原始帧数据时调用此回调。
 * 应用可以通过此回调获取视频帧数据进行自定义处理
 * 
 * @param data 视频帧数据数组，包含各个颜色平面的数据指针
 * @param dataLength 每个数据缓冲区的长度数组，对应data数组中每个平面的数据长度
 * @param param 视频帧参数对象，包含格式、分辨率、旋转角度等信息
 * @param streamID 视频流ID，用于标识数据来源的视频流
 */
- (void)onRemoteVideoFrameRawData:(unsigned char *_Nonnull *_Nonnull)data
                       dataLength:(unsigned int *)dataLength
                            param:(ZDMVideoFrameParam *)param
                         streamID:(NSString *)streamID;

/**
 * 播放器SEI信息同步接收回调
 * 
 * 当播放器接收到视频流中的SEI（Supplemental Enhancement Information）信息时调用此回调。
 * SEI通常包含与视频同步的元数据信息，如时间戳、自定义数据等
 * 
 * @param streamID 视频流ID，标识SEI数据来源的视频流
 * @param data SEI数据内容，包含具体的增强信息
 */
- (void)onPlayerSyncRecvSEI:(NSString *)streamID data:(NSData *)data;

/**
 * 停止数字人服务
 * 
 * 停止当前运行的数字人任务，释放相关资源并清理连接
 */
- (void)stop;

@end

NS_ASSUME_NONNULL_END

#endif // #ifndef IZegoDigitalMobile_h
