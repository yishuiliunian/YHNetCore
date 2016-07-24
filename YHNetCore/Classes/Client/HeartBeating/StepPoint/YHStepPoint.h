//
//  YHStepPoint.h
//  Pods
//
//  Created by stonedong on 16/7/24.
//
//

#import <Foundation/Foundation.h>

@class YHStepPoint;
@protocol YHStepPointDelegate <NSObject>
- (void) stepPointDidStep:(YHStepPoint*)point;
- (void) stepPointDidReachAim:(YHStepPoint*)point;
@end

@interface YHStepPoint : NSObject
@property (nonatomic,weak) id<YHStepPointDelegate> delegate;
@property (nonatomic, strong, readonly) NSArray* times;
- (instancetype) initWithTimes:(NSArray*)times;
- (void) fire;
- (void) cancel;
@end
