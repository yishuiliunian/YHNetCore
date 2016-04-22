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
@end
