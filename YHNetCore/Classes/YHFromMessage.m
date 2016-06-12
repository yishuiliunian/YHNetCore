//
//  YHFromMessage.m
//  Pods
//
//  Created by stonedong on 16/4/23.
//
//

#import "YHFromMessage.h"

@implementation YHFromMessage
@synthesize cmd = __cmd;

- (instancetype) initWithSEQ:(int64_t)seq cmd:(YHCmd*)cmd
{
    self = [super init];
    if (!self) {
        return self;
    }
    _seq = seq;
    __cmd = cmd;
    return self;
}
- (NSString*) description
{
    return [NSString stringWithFormat:@"YHFromMessage<%ux> SEQ:%d CMD:(%@)", self, _seq, self.cmd];
}

@end
