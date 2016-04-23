//
//  YHNetRunloop.h
//  Pods
//
//  Created by baidu on 16/4/22.
//
//

#import <Foundation/Foundation.h>
#define YHNetDefaultRunloop [YHNetRunloop runloop]

@interface YHNetRunloop : NSObject
+ (NSArray*) runloopModes;
+ (NSRunLoop*) runloop;

+ (void) addSource:(CFRunLoopSourceRef)source;
+ (void) removeSource:(CFRunLoopSourceRef)source;
+ (void) addTimer:(NSTimer*)timer;
+ (void) removeTimer:(NSTimer*)timer;
+ (void) scheduleReadStream:(CFReadStreamRef)stream;
+ (void) unscheduleReadStream:(CFReadStreamRef)stream ;
+ (void) scheduleWriteStream:(CFWriteStreamRef)stream;
+ (void) unscheduleWriteStream:(CFWriteStreamRef)stream;
@end
