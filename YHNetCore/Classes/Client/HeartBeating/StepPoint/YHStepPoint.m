//
//  YHStepPoint.m
//  Pods
//
//  Created by stonedong on 16/7/24.
//
//

#import "YHStepPoint.h"
#import "YHStepPointSegement.h"

@interface YHStepPoint () <YHStepPointSegementDelegate>
{
    NSMutableArray* _timesRestArray;
}
@property (nonatomic, strong, readonly) YHStepPointSegement* currentSegement;
@end
@implementation YHStepPoint
- (instancetype) initWithTimes:(NSArray *)times
{
    self = [super init];
    if (!self) {
        return self;
    }
    _timesRestArray = [times mutableCopy];
    return self;
}

- (void) fire
{
    [self eatOneTime];
}

- (void) eatOneTime
{
    if (_timesRestArray.count == 0) {
        if ([self.delegate respondsToSelector:@selector(stepPointDidReachAim:)]) {
            [self.delegate stepPointDidReachAim:self];
        }
    } else {
        NSNumber* time = _timesRestArray.firstObject;
        [_timesRestArray removeObjectAtIndex:0];
        float timeF = time.floatValue;
        _currentSegement = [[YHStepPointSegement alloc] initWithFireTime:timeF];
        _currentSegement.delegate = self;
        [_currentSegement fire];
        if ([self.delegate respondsToSelector:@selector(stepPointDidStep:)]) {
            [self.delegate stepPointDidStep:self];
        }
    }
}

- (void) stepPointSegementDidFire:(YHStepPointSegement *)step
{
    [_currentSegement cancel];
    [self eatOneTime];
}

- (void) cancel
{
    [self.currentSegement cancel];
}
@end
