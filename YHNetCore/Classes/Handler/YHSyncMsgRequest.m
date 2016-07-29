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
#import "YHNetNotification.h"
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
    
    

    [super onNetSuccess:object];
    

}
@end
