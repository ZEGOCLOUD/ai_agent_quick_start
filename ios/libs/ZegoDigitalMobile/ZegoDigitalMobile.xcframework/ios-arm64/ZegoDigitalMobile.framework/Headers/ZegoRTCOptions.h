#ifndef ZEGO_RTC_OPTIONS_H
#define ZEGO_RTC_OPTIONS_H

#import <Foundation/Foundation.h>

@interface ZegoRTCOptions : NSObject

@property(nonatomic, strong) NSString *roomID;
@property(nonatomic, strong) NSString *inputVoiceStreamID;
@property(nonatomic, strong) NSString *outputStreamID;

- (instancetype)initWithRoomID:(NSString *)roomID
            inputVoiceStreamID:(NSString *)inputVoiceStreamID
                outputStreamID:(NSString *)outputStreamID;

@end

#endif // #ifndef ZEGO_RTC_OPTIONS_H
