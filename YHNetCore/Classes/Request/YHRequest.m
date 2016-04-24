//
//  YHRequest.m
//  Pods
//
//  Created by stonedong on 16/4/23.
//
//

#import "YHRequest.h"


@implementation YHRequest


- (instancetype) init
{
    self = [super init];
    if (!self) {
        return self;
    }
    _timeout = 60;
    return self;
}

- (void) requestTimeOut
{
    
}
- (void) willStartRequest
{
    
}

- (void) didSendingRequest
{
    
}

- (void) reciveRspMessage:(YHFromMessage *)mssage
{
    
}
@end
