//
//  YHNetRunloop.m
//  Pods
//
//  Created by baidu on 16/4/22.
//
//

#import "YHNetRunloop.h"

static NSRunLoop* YHGlobalRunloop = nil;


@implementation YHNetRunloop

+ (void) load
{
    [self requestThread];
}

+ (NSRunLoop*) runloop
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self requestThread];
    });
    return YHGlobalRunloop;
}


+ (void) connectionThreadEntryPoint:(id) __unused object {
    @autoreleasepool {
        [[NSThread currentThread] setName:@"com.baidu.wallet.BWConnectionThread"];
        NSRunLoop* currentLoop = [NSRunLoop currentRunLoop];
        [currentLoop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
        YHGlobalRunloop = currentLoop;
        [currentLoop run];
    }
}

+ (NSThread*) requestThread
{
    static NSThread* thread = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        thread = [[NSThread alloc] initWithTarget:[self class] selector:@selector(connectionThreadEntryPoint:) object:nil];
        thread.threadPriority = 1.0;
        [thread start];
    });
    return thread;
}

+ (NSArray*) runloopModes
{
    return @[NSDefaultRunLoopMode];
}


+ (void) addSource:(CFRunLoopSourceRef)source
{
    for (NSString* model in [self runloopModes]) {
        CFRunLoopAddSource([[self runloop]  getCFRunLoop], source,(__bridge CFStringRef)model);
    }
}

+ (void) removeSource:(CFRunLoopSourceRef)source
{
     for (NSString* model in [self runloopModes]) {
        CFRunLoopRemoveSource([[self runloop]  getCFRunLoop], source,(__bridge CFStringRef)model);
    }
}

+ (void) addTimer:(NSTimer*)timer
{
    for (NSString* model in [self runloopModes]) {
        CFRunLoopAddTimer([[self runloop]  getCFRunLoop], (__bridge CFRunLoopTimerRef)timer ,(__bridge CFStringRef)model);
    }
}

+ (void) removeTimer:(NSTimer*)timer
{
    for (NSString* model in [self runloopModes]) {
        CFRunLoopRemoveTimer ([[self runloop]  getCFRunLoop], (__bridge CFRunLoopTimerRef)timer ,(__bridge CFStringRef)model);
    }
}

+ (void) scheduleReadStream:(CFReadStreamRef)stream{
    for (NSString* model in [self runloopModes]) {
        CFReadStreamScheduleWithRunLoop ( stream ,[[self runloop]  getCFRunLoop],(__bridge CFStringRef)model);
    }
}

+ (void) unscheduleReadStream:(CFReadStreamRef)stream {
    for (NSString* model in [self runloopModes]) {
        CFReadStreamUnscheduleFromRunLoop ( stream ,[[self runloop]  getCFRunLoop],(__bridge CFStringRef)model);
    }
}

+ (void) scheduleWriteStream:(CFWriteStreamRef)stream {
    for (NSString* model in [self runloopModes]) {
        CFWriteStreamScheduleWithRunLoop ( stream ,[[self runloop]  getCFRunLoop],(__bridge CFStringRef)model);
    }
}

+ (void) unscheduleWriteStream:(CFWriteStreamRef)stream {
    for (NSString* model in [self runloopModes]) {
        CFWriteStreamUnscheduleFromRunLoop( stream ,[[self runloop]  getCFRunLoop],(__bridge CFStringRef)model);
    }
}
@end
