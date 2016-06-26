//
//  YHCodecWrapper.h
//  Pods
//
//  Created by stonedong on 16/4/23.
//
//

#import <Foundation/Foundation.h>

@class YHSendMessage;
@class YHFromMessage;
@interface YHCodecWrapper : NSObject
+ (NSData*) encode:(YHSendMessage*)message;
+ (YHFromMessage*) decode:(NSData*)data;
@end
