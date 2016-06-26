//
//  YHNetStatus.m
//  Pods
//
//  Created by stonedong on 16/6/26.
//
//

#import "YHNetStatus.h"
#import "YHDNS.h"
#import "YHNetNotification.h"
@implementation YHNetStatus
+ (YHNetStatus*) shareInstance
{
    static YHNetStatus* status;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        status = [YHNetStatus new];
    });
    return status;
}

- (instancetype) init
{
    self = [super init];
    if (!self) {
        return self;
    }
    _reachalility = [Reachability reachabilityWithHostName:[YHDNS shareDNS].yaoheHost.ip];
    [_reachalility startNotifier];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkChanged:) name:kReachabilityChangedNotification object:nil];
    _currentStatus = _reachalility.currentReachabilityStatus;
    return self;
}

- (void) networkChanged:(NSNotification*)nc
{
    if (nc.object != _reachalility) {
        return;
    }
    YHNetStatusChangeEvent* event = [YHNetStatusChangeEvent new];
    event.originStatus = _currentStatus;
    event.aimStatus = _reachalility.currentReachabilityStatus;
    NSMutableDictionary* userInfo = [NSMutableDictionary new];
    [userInfo setNetStatusChangEvent:event];
    DZPostNetworkChanged(userInfo);
    _currentStatus = event.aimStatus;
}

@end


@implementation YHNetStatusChangeEvent



@end