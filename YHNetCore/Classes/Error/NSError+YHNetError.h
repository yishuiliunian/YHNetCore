//
//  NSError+YHNetError.h
//  Pods
//
//  Created by stonedong on 16/4/23.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, YHNetErrorCode) {
    kYHNetErrorTimeOut,
};

@interface NSError (YHNetError)

+ (NSError*) YH_Error:(int)code reason:(NSString*)reason;

@end
