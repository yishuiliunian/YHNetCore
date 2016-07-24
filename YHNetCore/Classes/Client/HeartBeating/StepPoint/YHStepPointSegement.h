//
//  YHStepPointSegement.h
//  Pods
//
//  Created by stonedong on 16/7/24.
//
//

#import <Foundation/Foundation.h>


@class YHStepPointSegement;
@protocol YHStepPointSegementDelegate <NSObject>

- (void) stepPointSegementDidFire:(YHStepPointSegement*)step;

@end

@interface YHStepPointSegement : NSObject
@property (nonatomic, assign) float time;
@property (nonatomic, weak) id<YHStepPointSegementDelegate> delegate;
- (instancetype) initWithFireTime:(float) time;
- (void) fire;
- (void) cancel;
@end
