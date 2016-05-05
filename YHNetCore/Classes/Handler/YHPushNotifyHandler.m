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
    
}

- (void) onHandleObject:(PushNotifyRequest*)object
{
    YHSyncMsgRequest* sync = [YHSyncMsgRequest new];
    sync.syncMsg.cookieId = object.cookieId;
    sync.skey = DZActiveAuthSession.token;
    [sync start];
}
@end
