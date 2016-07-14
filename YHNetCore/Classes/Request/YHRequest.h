//
//  YHRequest.h
//  Pods
//
//  Created by stonedong on 16/4/23.
//
//

#import <Foundation/Foundation.h>
#import "YHFromMessage.h"

extern NSString* const kYHSkeyInvalidNotification ;
@class YHRequest;
@protocol YHRequestHandler<NSObject>
- (void) yh_request:(YHRequest*)request onError:(NSError*)error;
- (void) yh_request:(YHRequest *)request onSuccess:(id)object;
@end

@class GPBMessage;
@interface YHRequest : NSObject
{
    @protected
    GPBMessage* _requestData;
    Class _responseClass;
}
@property (nonatomic, weak) NSObject<YHRequestHandler>* delegate;
@property (nonatomic, assign, readonly) BOOL requesting;
@property (nonatomic, assign, readonly) int64_t seq;
@property (nonatomic, strong, readonly) NSDictionary* requestHeader;
@property (nonatomic, strong, readonly) GPBMessage* requestData;
@property (nonatomic, strong, readonly) NSString* servant;
@property (nonatomic, strong, readonly) NSString* method;
@property (nonatomic, assign) BOOL b_oneway;
@property (nonatomic, assign) NSTimeInterval timeout;
@property (nonatomic, strong) Class responseObjectClass;
@property (nonatomic, strong) void(^errorHandler)(NSError* error) ;
@property (nonatomic, strong) void(^successHanlder) (id object);
@property (nonatomic, strong, readonly) YHFromMessage*  responseMessage;

- (void) setErrorHandler:(void (^)(NSError * error))errorHandler;
- (void) setSuccessHanlder:(void (^)(id object))successHanlder;
- (void) addHeader:(NSString*)paramter forKey:(NSString*)key;

- (void) notifyResponseError:(NSError*)error;
- (void) notifyResponseSuccess:(id)object;
@end

@interface YHRequest ()
- (int64_t) start;
- (void) reciveRspMessage:(YHFromMessage*)mssage;
@end


@interface YHRequest ()
- (void) onError:(NSError*)error;
- (void) onNetSuccess:(id)object;
@end


@protocol YHRequestTimeOutDelegate <NSObject>
- (void) requestOccurTimeOut:(YHRequest*)request;
@end

@interface YHRequest ()
@property (nonatomic, weak) id<YHRequestTimeOutDelegate> timeoutDelegate;
- (void) startTimeOut;
@end