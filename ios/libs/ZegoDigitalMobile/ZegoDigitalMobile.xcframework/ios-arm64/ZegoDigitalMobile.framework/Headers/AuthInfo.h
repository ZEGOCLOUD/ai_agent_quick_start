#ifndef AuthInfo_h
#define AuthInfo_h

#import <Foundation/Foundation.h>

@interface AuthInfo : NSObject

@property(nonatomic, strong) NSString *appID;
@property(nonatomic, strong) NSString *userID;
@property(nonatomic, strong) NSString *token;

- (instancetype)initWithAppID:(NSString *)appID userID:(NSString *)userID token:(NSString *)token;

@end

#endif // #ifndef AuthInfo_h
