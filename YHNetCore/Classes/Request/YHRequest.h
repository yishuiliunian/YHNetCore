//
//  YHRequest.h
//  Pods
//
//  Created by stonedong on 16/4/23.
//
//

#import <Foundation/Foundation.h>
#import "YHFromMessage.h"

@class YHRequest;
@protocol YHRequestHandler<NSObject>
- (void) request:(YHRequest*)request onError:(NSError*)error;
- (void) request:(YHRequest *)request onSuccess:(id)object;
@end

@class GPBMessage;
@interface YHRequest : NSObject
@property (nonatomic, weak) NSObject<YHRequestHandler>* delegate;
@property (nonatomic, assign) BOOL sending;
@property (nonatomic, assign, readonly) int64_t seq;
@property (nonatomic, strong, readonly) GPBMessage* requestData;
@property (nonatomic, strong, readonly) NSDictionary* requestHeader;
@property (nonatomic, strong) Class responseObjectClass;
@property (nonatomic, strong) NSString* servant;
@property (nonatomic, strong) NSString* method;
@end

@interface YHRequest ()
- (void) willStartRequest;
- (void) didSendingRequest;
- (void) reciveRspMessage:(YHFromMessage*)mssage;
@end