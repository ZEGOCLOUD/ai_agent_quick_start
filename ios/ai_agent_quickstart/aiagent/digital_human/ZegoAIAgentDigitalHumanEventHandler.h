//
//  ZegoAIAgentDigitalHumanEventHandler.h
//  ai_agent_quickstart
//
//  Created by AI on 2024/12/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class ZegoVideoFrameParam;

/**
 * @protocol ZegoAIAgentDigitalHumanEventHandler
 * @brief 数字人智能体事件处理协议
 *
 * 该协议定义了数字人智能体相关的事件回调方法，实现此协议的类可以接收和响应
 * 数字人智能体产生的各类事件，包括视频帧数据和SEI数据等。
 */
@protocol ZegoAIAgentDigitalHumanEventHandler <NSObject>

@optional
/**
 * 远程视频帧原始数据回调
 * @param data 视频帧数据
 * @param dataLength 数据长度
 * @param param 视频帧参数
 * @param streamID 流ID
 */
- (void)onRemoteVideoFrameRawData:(unsigned char **)data
                       dataLength:(unsigned int *)dataLength
                            param:(ZegoVideoFrameParam *)param
                         streamID:(NSString *)streamID;

/**
 * 播放器同步接收SEI数据回调
 * @param data SEI数据
 * @param streamID 流ID
 */
- (void)onPlayerSyncRecvSEI:(NSData *)data streamID:(NSString *)streamID;

@end

NS_ASSUME_NONNULL_END
