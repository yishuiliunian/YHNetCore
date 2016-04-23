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
    NSInputStream* _readStream;
    NSOutputStream* _writeStream;
    NSTimer* _connectionTimeOutTimer;
    NSMutableArray* _sendQueue;
    YHReadBuffer* _readBuffer;
}
@property (nonatomic, strong) YHEndPoint* endpoint;
@end

@implementation YHNetSocketConnection

- (instancetype) init
{
    self = [super init];
    if (!self) {
        return self;
    }
    _flag = 0;
    _timeout = 40;
    _sendQueue = [NSMutableArray new];
    _connected = NO;
    _readBuffer = nil;
    [NSThread detachNewThreadSelector:@selector(scheduleSend) toTarget:self withObject:nil];
    return self;
}

- (BOOL) openWithEndPoint:(YHEndPoint *)point error:(NSError *__autoreleasing *)error
{
    if ([self.delegate respondsToSelector:@selector(connectionWillOpen:)]) {
        [self.delegate connectionWillOpen:self];
    }
    CFReadStreamRef  readStream = (__bridge CFReadStreamRef)_readStream;
    CFWriteStreamRef writeStream = (__bridge CFWriteStreamRef)_writeStream;
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)point.host, [point.port intValue], &readStream, &writeStream);

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
    if ((_flag & kDidCompleteOpenForRead) && (_flag & kDidCompleteOpenForWrite) ) {
        _connected =YES;
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
    if (!_readBuffer) {
        _readBuffer = [YHReadBuffer new];
    }
    while ([_readStream hasBytesAvailable]) {
        uint8_t buffer[MaxReadLength];
        int64_t length =  [_readStream read:buffer maxLength:MaxReadLength];
        if (length < 0) {
            break;
        }
        [_readBuffer appendBytes:buffer length:length];
    }
    // if the read buffer is full ,then decode it. Otherwise do nothing , but just wait the next package
    if (_readBuffer.isFull) {
        NSData* data = _readBuffer.bufferData;
        YHFromMessage* msg = [YHCodecWrapper decode:data];
        if ([self.delegate respondsToSelector:@selector(connection:getFromMessage:)]) {
            [self.delegate connection:self getFromMessage:msg];
        }
        _readStream = nil;
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
            [self closeWithError:nil];
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
            [self closeWithError:nil];
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
    while (true) {
        @autoreleasepool {
        YHSendMessage* msg = nil;
        for (;;) {
            if (!_connected) {
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
            break;
        }
        }
        [NSThread sleepForTimeInterval:0.01];
    }
}

- (void) closeWithError:(NSError*)error
{
    
    [self close];
}

- (void) close
{
    [self invalideOpenTimeOut];
    [YHNetRunloop unscheduleReadStream:(__bridge CFReadStreamRef)(_readStream)];
    [YHNetRunloop unscheduleWriteStream:(__bridge CFWriteStreamRef)(_readStream)];
    [_writeStream close];
    [_readStream close];
    _flag &= 0x0;
    _connected = NO;
}
@end

