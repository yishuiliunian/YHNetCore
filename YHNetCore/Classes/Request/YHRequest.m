//
//  YHRequest.m
//  Pods
//
//  Created by stonedong on 16/4/23.
//
//

#import "YHRequest.h"
#import "NSError+YHNetError.h"
#import "YHNetClient.h"
#import "RpcLoginMessage.pbobjc.h"
@interface YHRequest ()
{
    NSTimer* _timer;
    NSMutableDictionary* _allHeaders;
}
@end

@implementation YHRequest


- (instancetype) init
{
    self = [super init];
    if (!self) {
        return self;
    }
    _timeout = 60;
    _allHeaders = [NSMutableDictionary new];
    return self;
}

- (void) startTimeOut
{
    _timer = [NSTimer scheduledTimerWithTimeInterval:_timeout target:self selector:@selector(toggleTimeOut) userInfo:nil repeats:NO];
}

- (void) addHeader:(NSString *)paramter forKey:(NSString *)key
{
    NSParameterAssert(paramter);
    NSParameterAssert(key);
    _allHeaders[key] = paramter;
}
- (NSDictionary*) requestHeader
{
    return [_allHeaders copy];
}
- (void) invalidTimeOut
{
    [_timer invalidate];
    _timer = nil;

}
- (void) toggleTimeOut
{
    [self invalidTimeOut];
    [self onError:[NSError YH_Error:kYHNetErrorTimeOut reason:@"服务好长时间没反应，跑路了？"]];
}

- (void) onError:(NSError*)error
{
    [self invalidTimeOut];
    [self endRequest];
}

- (void) onNetSuccess:(id)object
{
    [self invalidTimeOut];
    [self endRequest];
}

- (void) reciveRspMessage:(YHFromMessage *)message
{
    if (message.error) {
        [self onError:message.error];
    } else {
        NSError* error;
        LoginResponse* rsp  = [_responseClass parseFromData:message.data error:&error];
        if (error) {
            [self onError:error];
        } else {
            [self onNetSuccess:rsp];
        }
    }
    [self invalidTimeOut];
}

- (void) start
{
    if (_requesting) {
        return;
    }
    [[YHNetClient shareClient] performRequest:self];
    _requesting = YES;
}
- (void) endRequest {
    _requesting = NO;
}
@end
