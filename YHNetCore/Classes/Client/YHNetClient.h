//
//  YHNetClient.h
//  Pods
//
//  Created by stonedong on 16/4/23.
//
//

#import <Foundation/Foundation.h>
#import "YHRequest.h"
#import "YHNetSocketConnection.h"
@class YHSendMessage;
@interface YHNetClient : NSObject
@property (nonatomic, strong, readonly) YHNetSocketConnection* currentSocketConnection;
+ (YHNetClient*) shareClient;
- (void) performRequest:(YHRequest*)request;
@end
