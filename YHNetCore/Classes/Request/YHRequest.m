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
#import "YHRequest_RequestID.h"
#import "YHNetRunloop.h"
NSString* const kYHSkeyInvalidNotification = @"kYHSkeyInvalidNotification";

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
    _timeout = 20;
    _allHeaders = [NSMutableDictionary new];
    _b_oneway = NO;
    _responseClass = [SimpleResponse class];
    return self;
}

- (void) startTimeOut
{
    [self invalidTimeOut];
    _timer = [NSTimer scheduledTimerWithTimeInterval:_timeout target:self selector:@selector(toggleTimeOut) userInfo:nil repeats:NO];
    [YHNetRunloop addTimer:_timer];
}

- (void) addHeader:(NSString *)paramter forKey:(NSString *)key
{
    if (!paramter || !key) {
        return;
    }
    _allHeaders[key] = paramter;
}
- (NSDictionary*) requestHeader
{
    return [_allHeaders copy];
}
- (void) invalidTimeOut
{
    [_timer invalidate];
    [YHNetRunloop removeTimer:_timer];
    _timer = nil;
    

}
- (void) toggleTimeOut
{
    [self invalidTimeOut];
    if ([self.timeoutDelegate respondsToSelector:@selector(requestOccurTimeOut:)]) {
        [self.timeoutDelegate requestOccurTimeOut:self];
    }
}

- (void) notifyResponseError:(NSError*)error
{
    void(^Action)(void) = ^(void) {
        if ([self.delegate respondsToSelector:@selector(yh_request:onError:)]) {
            [self.delegate yh_request:self onError:error];
        }
        
        if (self.errorHandler) {
            self.errorHandler(error);
        }
    };
    if ([NSThread isMainThread]) {
        Action();
    } else {
        dispatch_async(dispatch_get_main_queue(),Action);
    }
  
}

- (void) notifyResponseSuccess:(id)object
{
    void(^Action)(void) = ^(void) {
        if ([self.delegate respondsToSelector:@selector(yh_request:onSuccess:)]) {
            [self.delegate yh_request:self onSuccess:object];
        }
        
        if (self.successHanlder) {
            self.successHanlder(object);
        }
    };
    if ([NSThread isMainThread]) {
        Action();
    } else {
        dispatch_async(dispatch_get_main_queue(),Action);
    }

}
- (void) onError:(NSError*)error
{
    [self invalidTimeOut];
    [self endRequest];
    [self notifyResponseError:error];
    if (error.code == 1) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kYHSkeyInvalidNotification object:nil];
    }
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
