//
//  YHNetResponseDispatch.m
//  Pods
//
//  Created by stonedong on 16/4/23.
//
//

#import "YHNetResponseDispatch.h"
#import "YHFromMessage.h"
#import "YHPushHandler.h"

@interface YHNetResponseDispatch ()
{
    NSMutableArray* _allHandler;
}
@end

@implementation YHNetResponseDispatch
- (instancetype) init
{
    self = [super init];
    if (!self) {
        return self;
    }
    _allHandler = [NSMutableArray new];
    return self;
}
- (void) registerHandler:(YHPushHandler*)handler
{
    NSParameterAssert(handler);
    [_allHandler addObject:handler];
}

- (BOOL) handleFromMessage:(YHFromMessage*)message
{
    for (YHPushHandler* hanlder  in _allHandler) {
        if ([hanlder canHanldCmd:message.cmd]) {
           return [hanlder handleFromMessage:message];
        }
    }
    return NO;
}
@end
