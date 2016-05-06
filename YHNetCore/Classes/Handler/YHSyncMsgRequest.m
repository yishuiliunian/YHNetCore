//
//  YHSyncMsgRequest.m
//  Pods
//
//  Created by stonedong on 16/5/3.
//
//

#import "YHSyncMsgRequest.h"
#import "YHCoreDB.h"
#import "DZAuthSession.h"
#import "YHAcquirRequest.h"

@implementation YHSyncMsgRequest

- (instancetype) init
{
    self = [super init];
    if (!self) {
        return self;
    }
    _responseClass = [SyncMsgResponse class];
    return self;
}

- (NSString*) method
{
    return @"rpc.MsgService.SyncMsg";
}


- (NSString*) servant
{
    return @"Comm.MsgServer.MsgObj";
}

- (SyncMsgRequest*) syncMsg
{
    if (!_requestData) {
        _requestData = [SyncMsgRequest new];
    }
    return  (SyncMsgRequest*) _requestData;
}

- (void) onError:(NSError *)error
{
    [super onError:error];
}
- (void) onNetSuccess:(SyncMsgResponse*)object
{
    [YHActiveDBConnection updateMessagesFromServer:object.msgArray];
    [super onNetSuccess:object];
    
    YHAcquirRequest* req = [YHAcquirRequest new];
    req.acquire.cookieId = object.cookieId;
    req.b_oneway = YES;
    req.skey = DZActiveAuthSession.token;
    [req start];
}
@end
