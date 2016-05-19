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

static NSString* const kKAActive= @"kKAActive";
static NSString* const kKAIdle = @"kKAIdle";


static NSString* const kKAEventBeating = @"kKAEventBeating";
static NSString* const kKAEventStopBeating = @"kKAEventStopBeating";

@interface YHHearterService () <YHRequestHandler>
{
    NSTimer* _keepAliveTimer;
    TKStateMachine* _keepAliveMechine;
}
@end
@implementation YHHearterService

- (instancetype) init
{
    self = [super init];
    if (!self) {
        return self;
    }
    [self installKeepAliveMachie];
    return self;
}


- (void) installKeepAliveMachie
{
    _keepAliveMechine = [TKStateMachine new];
    
    TKState* activeState = [TKState stateWithName:kKAActive];
    TKState* idleState = [TKState stateWithName:kKAIdle];
    
    
    TKEvent* beatEvent =[TKEvent eventWithName:kKAEventBeating transitioningFromStates:@[idleState] toState:activeState];
    TKEvent* idleEvent = [TKEvent eventWithName:kKAEventStopBeating transitioningFromStates:@[activeState] toState:idleState];
    
    [_keepAliveMechine addStates:@[activeState, idleState]];
    [_keepAliveMechine addEvents:@[beatEvent, idleEvent]];
    
    [_keepAliveMechine setInitialState:idleState];
    
    __weak typeof(self) wSelf = self;
    [activeState setDidEnterStateBlock:^(TKState *state, TKTransition *transition) {
        [wSelf __startBeating];
    }];
    
    [activeState setDidExitStateBlock:^(TKState *state, TKTransition *transition) {
        [wSelf __stopBeating];
    }];
    
}

- (void) __startBeating
{
    _keepAliveTimer = [NSTimer timerWithTimeInterval:60*4 target:self selector:@selector(beating) userInfo:nil repeats:YES];
    [YHNetRunloop addTimer:_keepAliveTimer];
    [_keepAliveTimer fire];
}

- (void) beating{
    if (!DZActiveAuthSession.token || !DZActiveAuthSession.userID) {
        return;
    }
    YHHeartRequest* request = [YHHeartRequest new];
    request.skey = DZActiveAuthSession.token;
    request.heartBeat.userName = DZActiveAuthSession.userID;
    request.heartBeat.allowPush = YES;
    request.delegate = self;
    [request start];
}
- (void) __stopBeating
{
    [YHNetRunloop removeTimer:_keepAliveTimer];
    [_keepAliveTimer invalidate];
    _keepAliveTimer = nil;
}

- (void) startBeating
{
    [_keepAliveMechine fireEvent:kKAEventBeating userInfo:nil error:nil];
}

- (void) stopBeating
{
    [_keepAliveMechine fireEvent:kKAEventStopBeating userInfo:nil error:nil];
}

@end
