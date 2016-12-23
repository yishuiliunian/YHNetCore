//
//  YHPushMessageHanlder.m
//  Pods
//
//  Created by stonedong on 16/4/27.
//
//

#import "YHPushMessageHanlder.h"
#import "YHCoreDB.h"
#import "DZAuthSession.h"
#import "YHAcquirRequest.h"
#import "YHNetNotification.h"
#import "YHMessageSyncCenter.h"

@implementation YHPushMessageHanlder
- (instancetype) init
{
    self = [super init];
    if (!self) {
        return self;
    }
    _responseClass = [PushMsgRequest class];
    return self;
}
- (NSString*) method
{
    return @"rpc.PushService.PushMsg";
}

- (NSString*) servant
{
    return @"Comm.DispatchServer.PushObj";
}

- (void) onHandleError:(NSError *)error
{
    [super onHandleError:error];
}

- (void) onHandleObject:(PushMsgRequest*)object
{

    [[YHMessageSyncCenter shareCenter] recivePushMessages:object.msgArray];
    YHAcquirRequest* req = [YHAcquirRequest new];
    req.acquire.cookieId = object.cookieId;
    req.b_oneway = YES;
    req.skey = DZActiveAuthSession.token;
    [req start];
}

@end
