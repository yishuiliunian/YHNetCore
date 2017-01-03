//
//  YHCmd.m
//  Pods
//
//  Created by stonedong on 16/4/23.
//
//

#import "YHCmd.h"

@implementation YHCmd

+ (instancetype) cmdWithServant:(NSString *)servant method:(NSString *)method
{
    return [[YHCmd alloc] initWithServant:servant method:method];
}
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

- (NSString*) description
{
    return [NSString stringWithFormat:@"Servant:%@  Method:%@", _servant, _method];
}

- (BOOL)isEqual:(YHCmd *)object {
    if (![object isKindOfClass:[YHCmd class]]) return NO;
    if (![self.servant isEqualToString:object.servant]) {
        return NO;
    }
    if (![self.method isEqualToString:object.method]) {
        return NO;
    }
    return YES;
}
@end
