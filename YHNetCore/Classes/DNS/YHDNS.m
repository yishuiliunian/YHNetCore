//
//  YHDNS.m
//  Pods
//
//  Created by stonedong on 16/6/26.
//
//

#import "YHDNS.h"

@implementation YHDNS
+ (YHDNS*) shareDNS
{
    static YHDNS* dns = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dns = [YHDNS new];
    });
    return dns;
}

- (instancetype) init
{
    self = [super init];
    if (!self) {
        return self;
    }
    _yaoheHost = [YHHost new];
    _yaoheHost.hostName = @"yaohe.com";
    _yaoheHost.ip = @"182.254.232.60";
    _yaoheHost.port = @"10010";
    return self;
}
@end
