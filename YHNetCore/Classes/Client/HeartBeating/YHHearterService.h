//
//  YHHearterService.h
//  Pods
//
//  Created by stonedong on 16/4/24.
//
//

#import <Foundation/Foundation.h>

@class YHHearterService;
@protocol YHHearterServiceDelegate <NSObject>

- (void) heartServiceOccurCloseError:(YHHearterService*)service;

@end

@interface YHHearterService : NSObject
@property (nonatomic, weak) id<YHHearterServiceDelegate> delegate;
- (void) startBeating;
- (void) stopBeating;
- (void) forceBeating;
@end
