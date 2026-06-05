#import <Foundation/Foundation.h>
#import "AiAgentAction.pbobjc.h"
#import "ZegoAIAgentActionDefines.h"
#import "ZegoAIAgentActionLogger.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZegoAIAgentActionOCSendParams : NSObject
@property (nonatomic, copy, readonly) NSString *roomId;
@property (nonatomic, assign, readonly) NSInteger msgType;
@property (nonatomic, copy, readonly) NSString *seq;
@property (nonatomic, copy, readonly) NSString *msgContent;
@property (nonatomic, copy, readonly) NSArray<NSString *> *userList;
- (instancetype)initWithRoomId:(NSString *)roomId
                       msgType:(NSInteger)msgType
                           seq:(NSString *)seq
                    msgContent:(NSString *)msgContent
                      userList:(NSArray<NSString *> *)userList NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
@end

@interface ZegoAIAgentActionOCSendResult : NSObject
@property (nonatomic, assign, readonly) NSInteger errorCode;
@property (nonatomic, copy, readonly) NSString *seq;
- (instancetype)initWithErrorCode:(NSInteger)errorCode seq:(NSString *)seq NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
@end

@interface ZegoAIAgentActionOCResponse : NSObject
@property (nonatomic, copy, readonly) NSString *action;
@property (nonatomic, copy, readonly) NSString *seq;
@property (nonatomic, assign, readonly) NSInteger code;
@property (nonatomic, copy, readonly) NSString *message;
@property (nonatomic, copy, readonly) NSString *requestId;
@property (nonatomic, strong, nullable, readonly) id data;
@property (nonatomic, copy, readonly) NSString *rawMessage;
@end

@interface ZegoAIAgentActionOCError : NSObject
@property (nonatomic, copy, readonly) NSString *seq;
@property (nonatomic, copy, readonly) NSString *action;
@property (nonatomic, strong, readonly) id code;
@property (nonatomic, copy, readonly) NSString *message;
@property (nonatomic, strong, nullable, readonly) id cause;
@end

@protocol ZegoAIAgentActionOCSender <NSObject>
- (void)sendAgentAction:(ZegoAIAgentActionOCSendParams *)params
           formatedJson:(NSString *)formatedJson
             completion:(void (^)(ZegoAIAgentActionOCSendResult *result))completion;
@end

typedef void (^ZegoAIAgentActionOCCompletion)(ZegoAIAgentActionOCResponse * _Nullable response,
                                              ZegoAIAgentActionOCError * _Nullable error);
typedef void (^ZegoAIAgentActionOCResponseHandler)(ZegoAIAgentActionOCResponse *response);
typedef void (^ZegoAIAgentActionOCErrorHandler)(ZegoAIAgentActionOCError *error);

@interface ZegoAIAgentActionOCClient : NSObject

@property (nonatomic, copy, readonly) NSString *roomId;
@property (nonatomic, copy, readonly) NSString *agentUserId;
@property (nonatomic, copy, readonly) NSString *userId;
@property (nonatomic, copy, readonly) NSString *deviceId;
@property (nonatomic, assign, readonly) NSInteger timeoutMs;

@property (nonatomic, weak, readonly) id<ZegoAIAgentActionOCSender> sender;
@property (nonatomic, copy, nullable, readonly) ZegoAIAgentActionOCResponseHandler onResponse;
@property (nonatomic, copy, nullable, readonly) ZegoAIAgentActionOCErrorHandler onError;

- (instancetype)initWithRoomId:(NSString *)roomId
                   agentUserId:(NSString *)agentUserId
                        userId:(NSString *)userId
                        sender:(id<ZegoAIAgentActionOCSender>)sender
                    onResponse:(nullable ZegoAIAgentActionOCResponseHandler)onResponse
                       onError:(nullable ZegoAIAgentActionOCErrorHandler)onError;

- (instancetype)initWithRoomId:(NSString *)roomId
                   agentUserId:(NSString *)agentUserId
                        userId:(NSString *)userId
                      deviceId:(nullable NSString *)deviceId
                     timeoutMs:(NSInteger)timeoutMs
                        sender:(id<ZegoAIAgentActionOCSender>)sender
                    onResponse:(nullable ZegoAIAgentActionOCResponseHandler)onResponse
                       onError:(nullable ZegoAIAgentActionOCErrorHandler)onError NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (void)sendAgentInstanceTTSWithParams:(SendAgentInstanceTTSParams *)params
                             timeoutMs:(nullable NSNumber *)timeoutMs
                            completion:(ZegoAIAgentActionOCCompletion)completion;

- (void)sendAgentInstanceLLMWithParams:(SendAgentInstanceLLMParams *)params
                             timeoutMs:(nullable NSNumber *)timeoutMs
                            completion:(ZegoAIAgentActionOCCompletion)completion;

- (void)interruptAgentInstanceWithTimeoutMs:(nullable NSNumber *)timeoutMs
                                 completion:(ZegoAIAgentActionOCCompletion)completion;
- (void)startListeningWithParams:(StartListeningParams *)params
                       timeoutMs:(nullable NSNumber *)timeoutMs
                      completion:(ZegoAIAgentActionOCCompletion)completion;
- (void)stopListeningWithParams:(StopListeningParams *)params
                      timeoutMs:(nullable NSNumber *)timeoutMs
                     completion:(ZegoAIAgentActionOCCompletion)completion;

- (BOOL)handleRoomChannelMessageWithContent:(NSString *)content;
- (void)cancelAllWithMessage:(NSString *)message;
@end

NS_ASSUME_NONNULL_END
