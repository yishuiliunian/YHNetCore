//
//  YHRequest.h
//  Pods
//
//  Created by stonedong on 16/4/23.
//
//

#import <Foundation/Foundation.h>
#import "YHFromMessage.h"
#import "YHBaseRequest.h"
extern NSString* const kYHSkeyInvalidNotification ;


@class GPBMessage;
@interface YHRequest : YHBaseRequest
{
    @protected
    GPBMessage* _requestData;
    Class _responseClass;
}
@property (nonatomic, assign, readonly) BOOL requesting;
@property (nonatomic, assign, readonly) int64_t seq;
@property (nonatomic, strong, readonly) NSDictionary* requestHeader;
@property (nonatomic, strong, readonly) GPBMessage* requestData;
@property (nonatomic, strong, readonly) NSString* servant;
@property (nonatomic, strong, readonly) NSString* method;
@property (nonatomic, assign) BOOL b_oneway;
@property (nonatomic, assign) NSTimeInterval timeout;
@property (nonatomic, strong) Class responseObjectClass;

@property (nonatomic, strong, readonly) YHFromMessage*  responseMessage;


- (void) addHeader:(NSString*)paramter forKey:(NSString*)key;



@end

@interface YHRequest ()
- (void) reciveRspMessage:(YHFromMessage*)mssage;
@end

@interface YHRequest ()
- (void) onError:(NSError*)error;
- (void) onNetSuccess:(id)object;
@end


