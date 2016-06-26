//
//  YHPushNotifyHandler.m
//  Pods
//
//  Created by stonedong on 16/5/3.
//
//

#import "YHPushNotifyHandler.h"
#import "YHSyncMsgRequest.h"
#import "DZAuthSession.h"
#import "YHMessageSyncCenter.h"
@implementation YHPushNotifyHandler
- (instancetype) init
{
    self = [super init];
    if (!self) {
        return self;
    }
    _responseClass = [PushNotifyRequest class];
    return self;
}

- (NSString*) method
{
    return @"rpc.PushService.PushNotify";
}

- (NSString*) servant
{
    return @"Comm.DispatchServer.PushObj";
}

- (void) onHandleError:(NSError *)error
{
    [super onHandleError:error];
}

- (void) onHandleObject:(PushNotifyRequest*)object
{
    [[YHMessageSyncCenter shareCenter] syncMessage:object.cookieId];
}
@end
