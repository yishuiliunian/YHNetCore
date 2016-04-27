//
//  YHNetSocketConnection.m
//  Pods
//
//  Created by stonedong on 16/4/19.
//
//

#import "YHNetSocketConnection.h"
#import <libkern/OSAtomic.h>
#import <CoreFoundation/CoreFoundation.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <netdb.h>
#import "YHEndPoint.h"
#import "YHNetRunloop.h"
#import<libkern/OSAtomic.h>
#import "YHSendMessage.h"
#import "YHCodecWrapper.h"
#import "YHFromMessage.h"
#import "NSError+YHNetError.h"
#import "YHReadBuffer.h"

@interface YHNetSocketConnection  () <NSStreamDelegate>
{
    //read write stream
    NSInputStream* _readStream;
    NSOutputStream* _writeStream;
    //
    NSTimer* _connectionTimeOutTimer;
    //sendQueue to cache the sendmessage
    NSMutableArray* _sendQueue;
    //server data will seperate, use this to join those parts.
    YHReadBuffer* _readBuffer;
    //
    BOOL _destry;
    
}
@property (nonatomic, strong) YHEndPoint* endpoint;
@end

#pragma Retry
@interface YHNetSocketConnection ()
{
    NSInteger _maxRetryCount;
    NSInteger _currentRetryCount;
    BOOL _retrying;
}
@end

@implementation YHNetSocketConnection

- (instancetype) initWithEndPoint:(YHEndPoint*)point
{
    self = [super init];
    if (!self) {
        return self;
    }
    _flag = 0;
    _timeout = 40;
    _sendQueue = [NSMutableArray new];
    _readBuffer = nil;
    _socketStatus = YHScketDisconnected;
    //
    _maxRetryCount = 3;
    _currentRetryCount = 0;
    _retrying = NO;
    _destry = NO;
    //schedule send message in thread
    [NSThread detachNewThreadSelector:@selector(scheduleSend) toTarget:self withObject:nil];
    _endPoint = point;

    return self;
}

- (BOOL) open:(NSError *__autoreleasing *)error
{
    
    //if previous endpoint isEqual the point that will connected , and net connected now then return;
    if (_socketStatus == YHScketConnected || _socketStatus == YHScketConnecting) {
            return YES;
    }
    
    _socketStatus = YHScketConnecting;
    if ([self.delegate respondsToSelector:@selector(connectionWillOpen:)]) {
        [self.delegate connectionWillOpen:self];
    }
    CFReadStreamRef  readStream = (__bridge CFReadStreamRef)_readStream;
    CFWriteStreamRef writeStream = (__bridge CFWriteStreamRef)_writeStream;
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)self.endPoint.host, [self.endPoint.port intValue], &readStream, &writeStream);

    _readStream = (__bridge NSInputStream *)(readStream);
    _writeStream = (__bridge NSOutputStream*)(writeStream);
   
    _readStream.delegate = self;
    _writeStream.delegate = self;
    
    CFWriteStreamSetProperty(writeStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
    CFReadStreamSetProperty(readStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
    for (NSString* model in [YHNetRunloop runloopModes]) {
        [_readStream scheduleInRunLoop:YHNetDefaultRunloop forMode:model];
        [_writeStream scheduleInRunLoop:YHNetDefaultRunloop forMode:model];
    }
    [_readStream open];
    [_writeStream open];
    
    //fire open connection timeout
    [_connectionTimeOutTimer invalidate];
    _connectionTimeOutTimer = [NSTimer timerWithTimeInterval:_timeout target:self selector:@selector(commectionTimeOut) userInfo:nil repeats:NO];
    [YHNetRunloop addTimer:_connectionTimeOutTimer];
    [_connectionTimeOutTimer fire];
    return YES;
}

- (void) commectionTimeOut
{
    if ([self.delegate respondsToSelector:@selector(connection:occurError:)]) {
        NSError* error = [NSError YH_Error:kCFSocketTimeout reason:@"链接服务器超时，服务器跑路了！"];
        [self.delegate connection:self occurError:error];
    }
    [self invalideOpenTimeOut];
    
}

- (void) invalideOpenTimeOut
{
    [_connectionTimeOutTimer invalidate];
    [YHNetRunloop removeTimer:_connectionTimeOutTimer];
    _connectionTimeOutTimer = nil;
}

- (void) openSuccess
{
    [self invalideOpenTimeOut];
    [self stopRetry];
    if ((_flag & kDidCompleteOpenForRead) && (_flag & kDidCompleteOpenForWrite) ) {
        _socketStatus = YHScketConnected;
        if ([self.delegate respondsToSelector:@selector(connectionDidOpen:)]) {
            [self.delegate connectionDidOpen:self];
        }
    }
    
}

- (void) stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    if (aStream == _writeStream) {
        [self writeStream:_writeStream hanldeEvent:eventCode];
    }else if (aStream == _readStream) {
        [self readStream:_readStream handleEvent:eventCode];
    } else {
        //error
    }
}

- (void) readBytes
{
    static NSUInteger MaxReadLength = 1024;
    while ([_readStream hasBytesAvailable]) {
        uint8_t *buffer = malloc(sizeof(uint8_t) * MaxReadLength);
        int64_t length =  [_readStream read:buffer maxLength:MaxReadLength];
        if (length < 0) {
            break;
        }
        [self deallWithBuffer:buffer length:length];
        free(buffer);
    }
}
// you must be so carefully about those lines , the sever transfer data not only sperate package and join package!!, so you need join it and sperate it too.
- (void) deallWithBuffer:(uint8_t*)buffer length:(int64_t)length
{
    
    void(^CheckFull)(void) = ^(void) {
        // if the read buffer is full ,then decode it. Otherwise do nothing , but just wait the next package
        if (_readBuffer.isFull) {
            NSData* data = _readBuffer.bufferData;
            YHFromMessage* msg = [YHCodecWrapper decode:data];
            
            if ([self.delegate respondsToSelector:@selector(connection:getFromMessage:)]) {
                [self.delegate connection:self getFromMessage:msg];
            }
#ifdef DEBUG
            NSLog(@"Got From Message %d %@", msg.seq, msg.cmd);
            NSLog(@"header is %@", msg.headers);
#endif
            _readBuffer = nil;
        }
    };
    
    uint8_t * readBufferPoint = buffer;
    uint32_t aimLength = 0;
    if (!_readBuffer) {
        _readBuffer = [YHReadBuffer new];
        aimLength = byteToInt2(buffer);
        readBufferPoint += 4;
        aimLength -= 4;
        length -= 4;
        _readBuffer.dataLength = aimLength;
    } else {
        aimLength = _readBuffer.dataLength;
    }
    if (_readBuffer.reciveDataLength + length < aimLength) {
        [_readBuffer appendBytes:readBufferPoint length:length];
    } else if (_readBuffer.reciveDataLength + length == aimLength) {
        [_readBuffer appendBytes:readBufferPoint length:length];
        CheckFull();
    } else {
        int32_t readLength = (aimLength - _readBuffer.reciveDataLength);
        [_readBuffer appendBytes:readBufferPoint length:readLength];
        CheckFull();
        [self deallWithBuffer:readBufferPoint+readLength length:length-readLength];
    }
}

- (void) readStream:(NSInputStream*)stream handleEvent:(NSStreamEvent)eventCode
{
    switch (eventCode) {
        case NSStreamEventOpenCompleted:
            _flag |= kDidCompleteOpenForRead;
            [self openSuccess];
            break;
        case NSStreamEventHasBytesAvailable:
            [self readBytes];
            break;
        // if error occurred the close the stream and socket;
        case NSStreamEventErrorOccurred:
            [self closeWithError:[stream streamError]];
            break;
        case NSStreamEventEndEncountered:
        case NSStreamEventNone:
            break;
        default:
            break;
    }
}

- (void) writeStream:(NSOutputStream*)stream hanldeEvent:(NSStreamEvent)eventCode
{
    switch (eventCode) {
        case NSStreamEventOpenCompleted:
            _flag |= kDidCompleteOpenForWrite;
            [self openSuccess];
            break;
        case NSStreamEventHasSpaceAvailable:
        
            break;
        // if error occurred the close the stream and socket;
        case NSStreamEventErrorOccurred:
            [self closeWithError:[stream streamError]];
            break;
        default:
            break;
    }
}
- (int64_t) getNextSEQ
{
    static volatile int64_t YHGlobalMessageSendSEQ = 10001;
    OSAtomicIncrement64(&YHGlobalMessageSendSEQ);
    return YHGlobalMessageSendSEQ;
}
- (int64_t) sendCMD:(YHCmd *)cmd data:(NSData *)data headers:(NSDictionary *)headers
{
    YHSendMessage* sendMsg = [YHSendMessage new];
    sendMsg.seq = [self getNextSEQ];
    sendMsg.cmd = cmd;
    sendMsg.dataBuffer = data;
    sendMsg.headers = headers;
    [self sendMessage:sendMsg];
    return sendMsg.seq;
}

- (void) sendMessage:(YHSendMessage *)message
{
    @synchronized (_sendQueue) {
        [_sendQueue addObject:message];
    }
    if ([self.delegate respondsToSelector:@selector(connection:enqueueSendMessage:)]) {
        [self.delegate connection:self enqueueSendMessage:message];
    }
}

- (void) scheduleSend
{
    while (!_destry) {
        @autoreleasepool {
        YHSendMessage* msg = nil;
        for (;;) {
            if (!_socketStatus == YHScketConnected) {
                break;
            }
            @synchronized (_sendQueue) {
                if (_sendQueue.count == 0) {
                    break;
                }
                msg = _sendQueue.firstObject;
                [_sendQueue removeObject:msg];
            }
            
            if (!msg) {
                break;
            }
            
            if ([self.delegate respondsToSelector:@selector(connection:willSendMessage:)]) {
                [self.delegate connection:self willSendMessage:msg];
            }
            
            NSData* data = [YHCodecWrapper encode:msg];
            [_writeStream write:[data bytes] maxLength:data.length];
            
            if ([self.delegate respondsToSelector:@selector(connection:didSendMessage:)]) {
                [self.delegate connection:self didSendMessage:msg];
            }
#ifdef DEBUG
            NSLog(@"Send Message %d , %@", msg.seq, msg.cmd);
#endif
            break;
        }
        }
        [NSThread sleepForTimeInterval:0.01];
    }
}

- (void) closeWithError:(NSError*)error
{
    [self close];
    if ([error.domain isEqualToString:NSPOSIXErrorDomain]) {
        //Socket is not connected
        if (error.code == 57) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self startRetry];
            });
        }
    }
}

- (void) close
{
    [self invalideOpenTimeOut];
    if (_readStream) {
        [YHNetRunloop unscheduleReadStream:(__bridge CFReadStreamRef)(_readStream)];
    }
    if (_writeStream) {
        [YHNetRunloop unscheduleWriteStream:(__bridge CFWriteStreamRef)(_writeStream)];
    }
    [_writeStream close];
    [_readStream close];
    _flag &= 0x0;
    _socketStatus = YHScketDisconnected;
}

////////////////////////////////////////////////////
#pragma Retry
////////////////////////////////////////////////////

- (void) startRetry
{
    // it is retrying, so it will not retry untill the previos progress is end
    if (_retrying) {
        return;
    }
    _retrying =  YES;
    _currentRetryCount = 0;
    [self onceTry];
}

- (void) onceTry
{
    if ([self canRetry]) {
        [self retryAtTimeInterval:4*(2^_currentRetryCount)];
    }
}

- (BOOL) canRetry
{
    if (_currentRetryCount < _maxRetryCount) {
        return YES;
    }
    return NO;
}

- (void) retryAtTimeInterval:(NSTimeInterval)timeInterval
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!_retrying) {
            return;
        }
        [self open:nil];
        _currentRetryCount++;
        [self onceTry];
    });
}

- (void) stopRetry
{
    _retrying = NO;
    _currentRetryCount = 0;
}
@end

