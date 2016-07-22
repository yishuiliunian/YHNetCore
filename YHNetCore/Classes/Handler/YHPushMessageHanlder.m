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
    
}

- (void) onHandleObject:(PushMsgRequest*)object
{
  
   NSArray* messages = [YHActiveDBConnection updateMessagesFromServer:object.msgArray];
 
    if (messages.count) {
        DZPostNewServerMessage(@{
                                 @"messages":[messages copy],
                                 });
    }
    
    YHAcquirRequest* req = [YHAcquirRequest new];
    req.acquire.cookieId = object.cookieId;
    req.b_oneway = YES;
    req.skey = DZActiveAuthSession.token;
    [req start];
}

@end
