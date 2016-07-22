//
//  YHPushHandler.m
//  Pods
//
//  Created by stonedong on 16/4/27.
//
//

#import "YHPushHandler.h"
#import "YHCmd.h"
#import "YHFromMessage.h"
#import "RpcPushMessage.pbobjc.h"
@implementation YHPushHandler
- (instancetype) initWithServant:(NSString *)servant method:(NSString *)method
{
    self = [super init];
    if (!self) {
        return self;
    }
    _servant = servant;
    _method = method;
    return self;
}

- (BOOL) canHanldCmd:(YHCmd *)cmd
{
    if (![cmd.servant isEqualToString:self.servant]) {
        return NO;
    }
    if (![cmd.method isEqualToString:self.method]) {
        return NO;
    }
    return YES;
}

- (void) onHandleObject:(id)object
{
    
}
- (void) onHandleError:(NSError*)error
{
    
}
- (BOOL) handleFromMessage:(YHFromMessage*)message
{
    NSError* error = nil;
    id msg = [_responseClass parseFromData:message.data error:&error];
    if (!error) {
        [self onHandleObject:msg];
    } else
    {
        [self onHandleError:error];
    }
    return YES;
    
}
@end
