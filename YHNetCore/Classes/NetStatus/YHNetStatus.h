//
//  YHNetStatus.h
//  Pods
//
//  Created by stonedong on 16/6/26.
//
//

#import <Foundation/Foundation.h>
#import <Reachability/Reachability.h>

@interface YHNetStatusChangeEvent : NSObject
@property (nonatomic, assign) NetworkStatus originStatus;
@property (nonatomic, assign) NetworkStatus aimStatus;
@end

@interface YHNetStatus : NSObject
@property (nonatomic, strong, readonly) Reachability* reachalility;
@property (nonatomic, assign, readonly) NetworkStatus currentStatus;
+ (YHNetStatus*) shareInstance;
@end
