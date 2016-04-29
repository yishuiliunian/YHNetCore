//
//  YHRequest.h
//  Pods
//
//  Created by stonedong on 16/4/23.
//
//

#import <Foundation/Foundation.h>
#import "YHFromMessage.h"
#import <YHProtoBuff/RpcLoginMessage.pbobjc.h>

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
@property (nonatomic, assign) NSTimeInterval timeout;
@property (nonatomic, strong) Class responseObjectClass;
@property (nonatomic, strong) void(^errorHandler)(NSError* error)  ;
@property (nonatomic, strong) void(^successHanlder) (id object);

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