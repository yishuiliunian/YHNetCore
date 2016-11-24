//
//  NSError+YHNetError.m
//  Pods
//
//  Created by stonedong on 16/4/23.
//
//

#import "NSError+YHNetError.h"
 NSString* const YHNetErrorDomain = @"com.yaohe.net.error";

@implementation NSError (YHNetError)

+ (NSError*) YH_Error:(int)code reason:(NSString *)reason
{
    reason = reason ? reason : @"Unkonw Error!";
    return [NSError errorWithDomain:YHNetErrorDomain code:code userInfo:@{
                                                                          NSLocalizedDescriptionKey:reason
                                                                          }];
}

@end
