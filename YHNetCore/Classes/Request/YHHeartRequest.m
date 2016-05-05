//
//  YHHeartRequest.m
//  YaoHe
//
//  Created by stonedong on 16/4/26.
//  Copyright © 2016年 stonedong. All rights reserved.
//

#import "YHHeartRequest.h"

@implementation YHHeartRequest

- (instancetype) init
{
    self = [super init];
    if (!self) {
        return self;
    }
    _responseClass = [HeartBeatResponse class];
    return self;
}

- (NSString*) method
{
    return @"rpc.LoginService.HeartBeat";
}

- (NSString*) servant
{
    return @"Comm.LoginServer.LoginObj";
}

- (HeartBeatRequest*) heartBeat
{
    if (!_requestData) {
        _requestData = [HeartBeatRequest new];
    }
    return (HeartBeatRequest*)_requestData;
}

- (void) onError:(NSError *)error
{
    [super onError:error];
}

- (void) onNetSuccess:(HeartBeatResponse*)object
{
    [super onNetSuccess:object];
}
@end
