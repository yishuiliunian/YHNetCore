//
//  YHNetSocketConnection.h
//  Pods
//
//  Created by stonedong on 16/4/19.
//
//

#import <Foundation/Foundation.h>


typedef NS_ENUM(NSInteger, YHNetConnectionFlag) {
   	kEnablePreBuffering      = 1 <<  0,  // If set, pre-buffering is enabled
    kDidStartDelegate        = 1 <<  1,  // If set, disconnection results in delegate call
    kDidCompleteOpenForRead  = 1 <<  2,  // If set, open callback has been called for read stream
    kDidCompleteOpenForWrite = 1 <<  3,  // If set, open callback has been called for write stream
    kStartingReadTLS         = 1 <<  4,  // If set, we're waiting for TLS negotiation to complete
    kStartingWriteTLS        = 1 <<  5,  // If set, we're waiting for TLS negotiation to complete
    kForbidReadsWrites       = 1 <<  6,  // If set, no new reads or writes are allowed
    kDisconnectAfterReads    = 1 <<  7,  // If set, disconnect after no more reads are queued
    kDisconnectAfterWrites   = 1 <<  8,  // If set, disconnect after no more writes are queued
    kClosingWithError        = 1 <<  9,  // If set, the socket is being closed due to an error
    kDequeueReadScheduled    = 1 << 10,  // If set, a maybeDequeueRead operation is already scheduled
    kDequeueWriteScheduled   = 1 << 11,  // If set, a maybeDequeueWrite operation is already scheduled
    kSocketCanAcceptBytes    = 1 << 12,  // If set, we know socket can accept bytes. If unset, it's unknown.
    kSocketHasBytesAvailable = 1 << 13,  // If set, we know socket has bytes available. If unset, it's unknown.
};



typedef NS_ENUM(NSInteger, YHSocketStatus) {
    YHScketConnected,
    YHScketDisconnected,
    YHScketConnecting,
    YHScketDisconnecting
};

@class YHNetCommunicator;
@class YHEndPoint;
@class YHSendMessage;


@class YHNetSocketConnection;
@class YHFromMessage;
@class YHCmd;
@protocol YHNetSocketConnectionDelegate
- (void) connectionWillOpen:(YHNetSocketConnection*)connection;
- (void) connectionDidOpen:(YHNetSocketConnection*)connection;
- (void) connection:(YHNetSocketConnection*)connection occurError:(NSError*)error;
- (void) connectionDidClose:(YHNetSocketConnection*)connection;
- (void) connection:(YHNetSocketConnection*)connection getFromMessage:(YHFromMessage*)message;
- (void) connection:(YHNetSocketConnection*)connection enqueueSendMessage:(YHSendMessage*)massage;
- (void) connection:(YHNetSocketConnection*)connection willSendMessage:(YHSendMessage*)message;
- (void) connection:(YHNetSocketConnection*)connection didSendMessage:(YHSendMessage*)message;
@end

@interface YHNetSocketConnection : NSObject
/**
 *  the endpoint that opened
 */
@property (nonatomic, strong, readonly) YHEndPoint* endPoint;
@property (nonatomic, weak) NSObject<YHNetSocketConnectionDelegate>* delegate;
@property (nonatomic, assign, readonly) YHNetConnectionFlag flag;
@property (nonatomic, assign) NSTimeInterval timeout;
@property (nonatomic, assign, readonly) YHSocketStatus socketStatus;
- (instancetype) initWithEndPoint:(YHEndPoint*)point;
- (BOOL) open:(NSError* __autoreleasing*) error;
- (int64_t) sendCMD:(YHCmd*)cmd data:(NSData*)data headers:(NSDictionary*)headers;
@end
