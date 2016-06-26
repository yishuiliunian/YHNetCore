//
//  YHNetNotification.h
//  Pods
//
//  Created by stonedong on 16/5/7.
//
//

#import <Foundation/Foundation.h>
#import <DZProgrameDefines/DZProgrameDefines.h>

DZExternObserverMessage(NewServerMessage);
DZExternObserverMessage(NetworkChanged)


@class YHNetStatusChangeEvent;
@interface NSDictionary (YHNetCoreNotificationDecode)
@property (nonatomic, strong, readonly) YHNetStatusChangeEvent* yh_netStatusChangEvent;
@end

@interface NSMutableDictionary  (YHNetCoreNotificationDecode)
- (void) setNetStatusChangEvent:(YHNetStatusChangeEvent*)event;
@end