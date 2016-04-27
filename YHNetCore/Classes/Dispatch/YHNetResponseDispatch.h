//
//  YHNetResponseDispatch.h
//  Pods
//
//  Created by stonedong on 16/4/23.
//
//

#import <Foundation/Foundation.h>



@class YHFromMessage;
@class YHPushHandler;
@interface YHNetResponseDispatch : NSObject
- (void) registerHandler:(YHPushHandler*)handler;
- (BOOL) handleFromMessage:(YHFromMessage*)message;
@end
