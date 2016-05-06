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
#import "RpcMessage.pbobjc.h"
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
    _b_oneway = NO;
    _responseClass = [SimpleResponse class];
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

- (void) notifyResponseError:(NSError*)error
{
    dispatch_sync(dispatch_get_main_queue(), ^{

        if ([self.delegate respondsToSelector:@selector(yh_request:onError:)]) {
            [self.delegate yh_request:self onError:error];
        }
        
        if (self.errorHandler) {
            self.errorHandler(error);
        }
        
    });
}

- (void) notifyResponseSuccess:(id)object
{
    dispatch_sync(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(yh_request:onSuccess:)]) {
            [self.delegate yh_request:self onSuccess:object];
        }
        
        if (self.successHanlder) {
            self.successHanlder(object);
        }
    });

}
- (void) onError:(NSError*)error
{
    [self invalidTimeOut];
    [self endRequest];
    [self notifyResponseError:error];
}

- (void) onNetSuccess:(id)object
{
    [self invalidTimeOut];
    [self endRequest];
    [self notifyResponseSuccess:object];
}

- (void) reciveRspMessage:(YHFromMessage *)message
{
    if (message.error) {
        [self onError:message.error];
    } else {
        NSError* error;
        LoginResponse*  rsp  = [_responseClass parseFromData:message.data error:&error];
        if ([rsp respondsToSelector:@selector(reason)] && [rsp respondsToSelector:@selector(result)]) {
            if (rsp.result != 0) {
                error = [NSError YH_Error:rsp.result reason:rsp.reason];
            }
        }
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
