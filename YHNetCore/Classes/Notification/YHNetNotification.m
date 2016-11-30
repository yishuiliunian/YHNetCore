//
//  YHNetNotification.m
//  Pods
//
//  Created by stonedong on 16/5/7.
//
//

#import "YHNetNotification.h"


DZObserverMessage(NewServerMessage)
DZObserverMessage(NetworkChanged)
DZObserverMessage(NetworkSocketStatusChanged)
DZObserverMessage(FeedCommentEventArrive);

static NSString* kYHNetCoreNotificationDecode = @"kYHNetCoreNotificationDecode";
@implementation NSDictionary (YHNetCoreNotificationDecode)

- (YHNetStatusChangeEvent*) yh_netStatusChangEvent
{
    return self[kYHNetCoreNotificationDecode];
}

@end


@implementation NSMutableDictionary (YHNetCoreNotificationDecode)

- (void) setNetStatusChangEvent:(YHNetStatusChangeEvent *)event
{
    if (!event) {
        return;
    }
    self[kYHNetCoreNotificationDecode] = event;
}

@end
