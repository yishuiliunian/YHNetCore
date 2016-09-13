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
#import <DZLogger/DZLogger.h>
#import "YHRequest_Timeout.h"
#import "YHRequest_SendIntereact.h"
#import "DZGlobalEnv.h"
NSString* const kYHSkeyInvalidNotification = @"kYHSkeyInvalidNotification";

@interface YHRequest ()
{
    NSMutableDictionary* _allHeaders;
    
}

@end

@implementation YHRequest
@synthesize startReqeustTime = _startReqeustTime;
@synthesize connectionSEQ = _connectionSEQ;

+ (NSString*) DefaultUserAgentInfo
{
    static NSDictionary* userAgent = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSDictionary *infoDic = [[NSBundle mainBundle] infoDictionary];
        NSString *appVersion = [infoDic objectForKey:@"CFBundleShortVersionString"];
        
        userAgent = @{
                      @"c_os" : @"1",
                      @"c_version" : appVersion?:@"",
#ifdef DEBUG
                      @"c_debug" : @"1",
#endif
                      };

    });
    return userAgent;
}

- (void) addCommonHeader
{
    [_allHeaders addEntriesFromDictionary:[YHRequest DefaultUserAgentInfo]];
    if (DEBUG_DZGlobalEnv) {
        _allHeaders[@"c_debug"] = @"1";
    }
}

- (instancetype) init
{
    self = [super init];
    if (!self) {
        return self;
    }
    _canceled = NO;
    _timeout = 30;
    _allHeaders = [NSMutableDictionary new];
    _b_oneway = NO;
    _responseClass = [SimpleResponse class];
    _connectionSEQ = 0;
    [self addCommonHeader];
    return self;
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
- (void) notifyResponseError:(NSError*)error
{
    if (_canceled) {
        return;
    }
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
    if (_canceled) {
        return;
    }
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
    DDLogError(@"网络错误%@ : %@",self, error);
    
    if (error.localizedDescription.length == 0) {
        NSString* msg = [NSString stringWithFormat:@"网络错误，稍后重试(%d)",error.code];
        error = [NSError errorWithDomain:error.domain code:error.code userInfo:@{NSLocalizedDescriptionKey:msg}];
    }
    [self endRequest];
    [self notifyResponseError:error];

}

- (void) onNetSuccess:(id)object
{
    [self endRequest];
    [self notifyResponseSuccess:object];
}

- (void) reciveRspMessage:(YHFromMessage *)message
{
    _responseMessage = message;
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


- (void) cancel
{
    _canceled = YES;
}

@end
