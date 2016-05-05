//
//  YHAcquirRequest.m
//  Pods
//
//  Created by stonedong on 16/5/5.
//
//

#import "YHAcquirRequest.h"

@implementation YHAcquirRequest

- (NSString*) servant
{
    return @"Comm.MsgServer.MsgObj";
}

- (NSString*) method
{
    return @"rpc.MsgService.Acquire";
}
- (AcquireRequest*) acquire
{
    if (!_requestData) {
        _requestData = [AcquireRequest new];
    }
    return _requestData;
}

- (void) onError:(NSError *)error
{
    [super onError:error];
}

- (void) onNetSuccess:(id)object
{
    [super onNetSuccess:object];
}
@end
