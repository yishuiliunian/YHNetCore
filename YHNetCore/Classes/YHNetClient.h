//
//  YHNetClient.h
//  Pods
//
//  Created by stonedong on 16/4/23.
//
//

#import <Foundation/Foundation.h>
#import "YHRequest.h"

@class YHSendMessage;
@interface YHNetClient : NSObject
+ (YHNetClient*) shareClient;
- (void) performRequest:(YHRequest*)request;
@end
