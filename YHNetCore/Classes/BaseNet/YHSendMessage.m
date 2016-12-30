//
//  YHSendMessage.m
//  Pods
//
//  Created by stonedong on 16/4/23.
//
//

#import <libkern/OSAtomic.h>
#import "YHSendMessage.h"
#import "YHCmd.h"

@interface YHSendMessage ()
{
    NSMutableDictionary* _allHeaders;
}
@end

@implementation YHSendMessage
@synthesize cmd = __cmd;
- (instancetype) init
{
    self = [super init];
    if (!self) {
        return self;
    }
    return self;
}

- (instancetype) initWithSEQ:(int32_t)seq cmd:(YHCmd *)cmd
{
    self = [self init];
    if (!self) {
        return self;
    }
    _seq = seq;
    __cmd = cmd;
    return self;
}


+ (int64_t) getNextSEQ
{
    static volatile int64_t YHGlobalMessageSendSEQ = 10001;
    OSAtomicIncrement64(&YHGlobalMessageSendSEQ);
    return YHGlobalMessageSendSEQ;
}
@end
