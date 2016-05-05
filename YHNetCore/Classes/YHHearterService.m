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

@interface YHHearterService () <YHRequestHandler>
{
    NSTimer* _heartTimer;
    NSString* _currentUID;
    NSString* _currentSKEY;
}
@end
@implementation YHHearterService

- (BOOL) canStartWithUID:(NSString*)uid skey:(NSString*)skey
{
    if (![uid isEqualToString:_currentUID] && ![skey isEqualToString:_currentSKEY]) {
        return NO;
    }
    return YES;
}

- (void) connectionUsedWithUID:(NSString *)uid skey:(NSString *)skey
{
    if ([self canStartWithUID:uid skey:skey]) {
        return;
    }
    _currentUID = DZActiveAuthSession.userID;
    _currentSKEY = skey;
    //
    [self toggleHeart];
}

- (void) toggleHeart
{
    YHHeartRequest* request = [YHHeartRequest new];
    request.skey = _currentSKEY;
    request.heartBeat.userName = _currentUID;
    request.heartBeat.allowPush = YES;
    request.delegate = self;
    [request start];
}
- (void) yh_request:(YHRequest *)request onError:(NSError *)error
{
    
}

- (void) yh_request:(YHRequest *)request onSuccess:(id)object
{
    
}

@end
