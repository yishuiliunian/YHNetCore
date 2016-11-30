//
//  YHAuthedRequest.m
//  Pods
//
//  Created by stonedong on 16/4/30.
//
//

#import "YHAuthedRequest.h"
#import "NSError+YHNetError.h"
@implementation YHAuthedRequest

- (void) setSkey:(NSString *)skey
{
    [self addHeader:skey forKey:@"skey"];
}

- (NSString*) skey
{
    return self.requestHeader[@"skey"];
}

- (void) start
{
    if (self.skey) {
        [super start];
    } else {
        NSError* error = [NSError YH_Error:-400 reason:@"当前SKEY为空，不能进行需要授权的网络请求"];
        [self onError:error];
    }
}
@end
