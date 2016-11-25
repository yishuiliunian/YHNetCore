//
//  YHMessageSyncCenter.h
//  Pods
//
//  Created by stonedong on 16/6/25.
//
//

#import <Foundation/Foundation.h>

@interface YHMessageSyncCenter : NSObject
+ (YHMessageSyncCenter*) shareCenter;
- (void) syncMessage:(int64_t)cookieId;

- (void) reciveRemoteMessages:(NSArray*)msgs;
@end
