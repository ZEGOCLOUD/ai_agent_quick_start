//
//  ai_companion_oc
//
//  Created by zego on 2024/8/28.
//

#import <Foundation/Foundation.h>

typedef void (^ZDMConnectionCallback)(NSInteger errorCode, NSString* errMsg, NSString* requestId, NSDictionary *data);

@protocol ZDMConnectionDelegate

-(void)zdmRequestSvrWithService:(unsigned int)interfaceID
                        service:(NSString*)service
                            url:(NSURL*)url
                           body:(NSDictionary*)body
                       callback:(ZDMConnectionCallback)callback;

@end
