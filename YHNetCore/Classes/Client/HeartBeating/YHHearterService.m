//
//  YHHearterService.m
//  Pods
//
//  Created by stonedong on 16/4/24.
//
//

#import "YHHearterService.h"
#import "YHHeartRequest.h"
#import "DZAuthSession.h"
#import "YHNetRunloop.h"
#import <TransitionKit/TransitionKit.h>
#import "YHMessageSyncCenter.h"
#import "YHStepPoint.h"
#import <DZLogger.h>
static NSString* const kKAActive= @"kKAActive";
static NSString* const kKAIdle = @"kKAIdle";
static NSString* const kKAShifting = @"kKAShifting";


static NSString* const kKAEventBeating = @"kKAEventBeating";
static NSString* const kKAEventStopBeating = @"kKAEventStopBeating";
static NSString* const kKAEventShifting = @"kKAEventShifting";
static NSString* const kKAEventActive = @"kKAEventActive";



@interface YHHearterService () <YHRequestHandler, YHStepPointDelegate>
{
    NSTimer* _keepAliveTimer;
    TKStateMachine* _keepAliveMechine;
    NSInteger _errorCount;
}
@property (nonatomic, strong) YHStepPoint* stepPoint;
@end
@implementation YHHearterService

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) installNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAccountResigter) name:kDZAuthSessionRegisterActive object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAccountResign) name:kDZAuthSessionResignActive object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void) onBecomeActive
{
    [self forceBeating];
    [self startBeating];
    [[YHMessageSyncCenter shareCenter] syncMessage:0];
}

- (void) onAccountResigter
{
    [self stopBeating];
    [self startBeating];
    [[YHMessageSyncCenter shareCenter] syncMessage:0];
}

- (void) onAccountResign
{
    [self stopBeating];
}
- (instancetype) init
{
    self = [super init];
    if (!self) {
        return self;
    }
    _errorCount = 0;
    [self installKeepAliveMachie];
    [self installNotifications];
    return self;
}

- (void) installKeepAliveMachie
{
    _keepAliveMechine = [TKStateMachine new];
    
    TKState* activeState = [TKState stateWithName:kKAActive];
    TKState* idleState = [TKState stateWithName:kKAIdle];
    TKState* shiftingState = [TKState stateWithName:kKAShifting];
    
    
    TKEvent* beatEvent =[TKEvent eventWithName:kKAEventBeating transitioningFromStates:@[idleState] toState:shiftingState];
    TKEvent* idleEvent = [TKEvent eventWithName:kKAEventStopBeating transitioningFromStates:@[activeState, shiftingState] toState:idleState];
    TKEvent* shiftingEvetn = [TKEvent eventWithName:kKAEventShifting transitioningFromStates:@[idleState, activeState] toState:shiftingState];
    TKEvent* activeEvent = [TKEvent eventWithName:kKAEventActive transitioningFromStates:@[shiftingState] toState:activeState];
    
    
    [_keepAliveMechine addStates:@[activeState, idleState, shiftingState]];
    [_keepAliveMechine addEvents:@[beatEvent, idleEvent, activeEvent, shiftingEvetn]];
    
    [_keepAliveMechine setInitialState:idleState];
    
    __weak typeof(self) wSelf = self;
    
    [shiftingState setDidEnterStateBlock:^(TKState *state, TKTransition *transition) {
        
        [wSelf.stepPoint cancel];
        wSelf.stepPoint = [[YHStepPoint alloc] initWithTimes:@[@(2), @(5), @(30), @(60), @(120)]];
        wSelf.stepPoint.delegate = self;
        [wSelf.stepPoint fire];
        DDLogInfo(@"进入渐变模式，按照间隔递增模式发送心跳包...");
    }];
    
    [shiftingState setDidExitStateBlock:^(TKState *state, TKTransition *transition) {
        [wSelf.stepPoint cancel];
        wSelf.stepPoint = nil;
    }];
    
    [activeState setDidEnterStateBlock:^(TKState *state, TKTransition *transition) {
        [wSelf __startBeating];

    }];
    
    [activeState setDidExitStateBlock:^(TKState *state, TKTransition *transition) {
        [wSelf __stopBeating];
    }];
    
}

- (void) stepPointDidStep:(YHStepPoint *)point
{
    static int count;
    NSLog(@"get step count %d", count ++);
    [self beating];
    DDLogInfo(@"递增模式下发送心跳包...");
}
- (void) stepPointDidReachAim:(YHStepPoint *)point
{
    [_keepAliveMechine fireEvent:kKAEventActive userInfo:nil error:nil];
    DDLogInfo(@"递增模式结束，进入稳定状态");
}

- (void) __startBeating
{
    _keepAliveTimer = [NSTimer timerWithTimeInterval:60*4 target:self selector:@selector(beating) userInfo:nil repeats:YES];
    [YHNetRunloop addTimer:_keepAliveTimer];
    [_keepAliveTimer fire];
    DDLogInfo(@"进入稳定模式，持续稳定发送心跳包....");
}

- (void) beating{
    if (!DZActiveAuthSession.token || !DZActiveAuthSession.userID) {
        return;
    }
    YHHeartRequest* request = [YHHeartRequest new];
    request.skey = DZActiveAuthSession.token;
    request.heartBeat.allowPush = 1;
    request.delegate = self;
    [request start];
    DDLogInfo(@"发送一次心跳包...");
}
- (void) __stopBeating
{
    [YHNetRunloop removeTimer:_keepAliveTimer];
    [_keepAliveTimer invalidate];
    _keepAliveTimer = nil;
    DDLogInfo(@"停止发送心跳包....");
}

- (void) yh_request:(YHRequest *)request onError:(NSError *)error
{
    if ([request isKindOfClass:[YHHeartRequest class]]) {
        _errorCount ++;
        if (_errorCount < 2) {
            [self forceBeating];
        } else {
 
        }
    }
}

- (void) yh_request:(YHRequest *)request onSuccess:(id)object
{
    if ([request isKindOfClass:[YHHeartRequest class]]) {
        _errorCount = 0;
    }
}

- (void) startBeating
{
    [_keepAliveMechine fireEvent:kKAEventShifting userInfo:nil error:nil];
}

- (void) stopBeating
{
    [_keepAliveMechine fireEvent:kKAEventStopBeating userInfo:nil error:nil];
}

- (void) forceBeating
{
    if (DZActiveAuthSession) {
        [self beating];
    }
}
@end
