//
//  YHAuthedRequest.m
//  Pods
//
//  Created by stonedong on 16/4/30.
//
//

#import "YHAuthedRequest.h"

@implementation YHAuthedRequest

- (void) setSkey:(NSString *)skey
{
    [self addHeader:skey forKey:@"skey"];
}

- (NSString*) skey
{
    return self.requestHeader[@"skey"];
}
@end
