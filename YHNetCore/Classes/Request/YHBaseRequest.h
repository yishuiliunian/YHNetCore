//
//  YHBaseRequest.h
//  Pods
//
//  Created by baidu on 2016/11/30.
//
//

#import <Foundation/Foundation.h>
@class YHBaseRequest;
@protocol YHRequestHandler<NSObject>
- (void) yh_request:(YHBaseRequest*)request onError:(NSError*)error;
- (void) yh_request:(YHBaseRequest *)request onSuccess:(id)object;
@end
@interface YHBaseRequest : NSObject
{
    @protected
    BOOL _canceled;
}
@property (nonatomic, weak) NSObject<YHRequestHandler>* delegate;
@property (nonatomic, assign, readonly) BOOL canceled;
@property (nonatomic, strong) void(^errorHandler)(NSError* error) ;
@property (nonatomic, strong) void(^successHanlder) (id object);
- (void) setErrorHandler:(void (^)(NSError * error))errorHandler;
- (void) setSuccessHanlder:(void (^)(id object))successHanlder;
- (void) notifyResponseError:(NSError*)error;
- (void) notifyResponseSuccess:(id)object;
- (void) cancel;
- (void) start;
@end
