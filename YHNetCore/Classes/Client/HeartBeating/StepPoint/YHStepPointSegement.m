//
//  YHStepPointSegement.m
//  Pods
//
//  Created by stonedong on 16/7/24.
//
//

#import "YHStepPointSegement.h"
#import "DZObjectProxy.h"
#import "DZWeakProxy.h"

@interface YHStepPointSegement ()
{
    NSTimer* _fireTimer;
}
@end

@implementation YHStepPointSegement
- (instancetype) initWithFireTime:(float)time
{
    self = [super init];
    if (!self) {
        return self;
    }
    _time = time;
    return self;
}

- (void) fire
{
    if (_fireTimer) {
        [self stop];
    }
    _fireTimer  = [NSTimer scheduledTimerWithTimeInterval:_time target:[DZWeakProxy proxyWithTarget:self] selector:@selector(didFire) userInfo:nil repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:_fireTimer forMode:NSDefaultRunLoopMode];
}
- (void) didFire
{
    if ([self.delegate respondsToSelector:@selector(stepPointSegementDidFire:)]) {
        [self.delegate stepPointSegementDidFire:self];
    }
    [self stop];
}
- (void) stop
{
    [_fireTimer invalidate];
    _fireTimer = nil;
}

- (void) cancel
{
    [self stop];
}
@end
