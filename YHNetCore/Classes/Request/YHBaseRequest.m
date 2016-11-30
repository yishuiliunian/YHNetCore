//
//  YHBaseRequest.m
//  Pods
//
//  Created by baidu on 2016/11/30.
//
//

#import "YHBaseRequest.h"

@implementation YHBaseRequest
- (instancetype) init
{
    self = [super init];
    if (!self) {
        return self;
    }
    
    _canceled = NO;

    return self;
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

- (void) cancel
{
    _canceled = YES;
}

- (void) start
{
    @throw [NSException exceptionWithName:@"com.dzpqzb.exception" reason:@"您需要实现Request动作部分" userInfo:@{}];
}

@end
