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
#import <TransitionKit/TransitionKit.h>
#import "YHHeartRequest.h"
#import "DZAuthSession.h"
#import <DZLogger/DZLogger.h>
#import "YHNetStatus.h"
#import "YHNetNotification.h"


@interface YHNetSocketConnection ()

@property (nonatomic, strong)   TKStateMachine* keepAliveMechine;
@end

#pragma --normal
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
   //
    TKStateMachine* _stateMachine;
}
@property (nonatomic, strong) YHEndPoint* endpoint;
@end

#pragma Retry
@interface YHNetSocketConnection ()
{
    NSInteger _maxRetryCount;
    NSInteger _currentRetryCount;
    BOOL _retrying;
    dispatch_semaphore_t _queueSemphore;
    

}
@end

@implementation YHNetSocketConnection


static NSString* const kStateConnected = @"connected";
static NSString* const kStateDisConnected = @"disconnected";
static NSString* const kStateError = @"error";
static NSString* const kStateConnecting= @"connecting";


static NSString* const kEventConnect = @"conncte";
static NSString* const kEventConnected = @"kEventConnected";
static NSString* const kEventErrorOccur= @"kEventErrorOccur";
static NSString* const kEventDisconnection= @"kEventDisconnection";


- (void) installStateMachine
{
    _stateMachine = [TKStateMachine new];
    
    TKState* connectionState = [TKState stateWithName:kStateConnected];
    TKState* errorState = [TKState stateWithName:kStateError];
    TKState* connectingState = [TKState stateWithName:kStateConnecting];
    TKState* disconnectionState = [TKState stateWithName:kStateDisConnected];
    
    TKEvent* connectingEvent = [TKEvent eventWithName:kEventConnect transitioningFromStates:@[disconnectionState, errorState] toState:connectingState];
    TKEvent* connectedEvent = [TKEvent eventWithName:kEventConnected transitioningFromStates:@[connectingState] toState:connectionState];
    TKEvent* errorEvent = [TKEvent eventWithName:kEventErrorOccur transitioningFromStates:@[connectingState, connectionState] toState:errorState];
    TKEvent* disconnectionEvent = [TKEvent eventWithName:kEventDisconnection transitioningFromStates:@[connectionState,errorState] toState:disconnectionState];
    
    [_stateMachine addStates:@[connectionState, errorState, connectingState, disconnectionState]];
    [_stateMachine addEvents:@[connectedEvent, disconnectionEvent, errorEvent, connectingEvent]];
    [_stateMachine setInitialState:disconnectionState];
    
    
    __weak typeof(self) wSelf = self;
    
  
    
    [connectingState setDidEnterStateBlock:^(TKState *state, TKTransition *transition) {
        [wSelf startConnecting];
    }];
    
    [errorState setDidEnterStateBlock:^(TKState *state, TKTransition *transition) {
        [wSelf enterErrorState:transition.userInfo];
    }];
    
    [connectionState setDidEnterStateBlock:^(TKState *state, TKTransition *transition) {
        [wSelf socketConnected];
    }];
    
    [disconnectionState setDidEnterStateBlock:^(TKState *state, TKTransition *transition) {
        if (transition.sourceState) {
           [wSelf closeAllStream];
        }
        [wSelf didDisconnection:transition.userInfo];
    }];
}

- (void) didDisconnection:(NSDictionary*)userInfo
{
    NSError* error = userInfo[@"error"];
    if (error) {
        if ([self.delegate respondsToSelector:@selector(connection:occurError:)]) {
            [self.delegate connection:self occurError:error];
        }
    }
    _socketStatus = YHScketDisconnected;
    if ([self.delegate respondsToSelector:@selector(connectionDidClose:)]) {
        [self.delegate connectionDidClose:self];
    }
}
- (void) socketConnected
{
    _socketStatus = YHScketConnected;
    _connectionSEQ ++;
    if ([self.delegate respondsToSelector:@selector(connectionDidOpen:)]) {
        [self.delegate connectionDidOpen:self];
    }
}

- (void) startConnecting
{
    NSError* error;
    [self openConnection:&error];
    _socketStatus = YHScketConnecting;
    DDLogInfo(@"开始尝试建立连接");
}

- (void) enterErrorState:(NSDictionary*) userInfo
{
    DDLogInfo(@"Enter Error State %@", userInfo);
    [self closeAllStream];
    if ([self.delegate respondsToSelector:@selector(connectionDidClose:)]) {
        [self.delegate connectionDidClose:self];
    }
    NSError* error = userInfo[@"error"];
    if (error.code == kYHNetErrorTimeOut) {
        [_stateMachine fireEvent:kEventDisconnection userInfo:userInfo error:nil];
    } else {
        if ([error.domain isEqualToString:NSPOSIXErrorDomain]) {
            //Socket is not connected
            if (error.code == 57) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [_stateMachine fireEvent:kEventConnect userInfo:nil error:nil];
                });
            }
        }
    }
}

- (void) installNotification
{
    DZAddObserverForNetworkChanged(self, @selector(handleNetchanged:));
}

- (void) dealloc
{
    DZRemoveObserverForNetworkChanged(self);
}
- (void) handleNetchanged:(NSNotification*)nc
{
    YHNetStatusChangeEvent* event = nc.userInfo.yh_netStatusChangEvent;
    if (event.originStatus == NotReachable && event.aimStatus != NotReachable) {
        NSError* error;
        [self open:&error];
        DDLogError(@"(NO->Reach)网络变化时尝试链接%@",error);
    } else if (event.originStatus == ReachableViaWWAN && event.aimStatus == ReachableViaWiFi) {
        NSError* error = [NSError YH_Error:kYHNetActiveDisconnect reason:@"主动断开链接"];
        [self closeWithError:error];
        DDLogError(@"尝试充值链接，先关闭%@",error);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSError* error;
            [self open:&error];
            DDLogError(@"(WLAN->WIFI)网络变化时尝试链接%@",error);
        });
    }
}
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
    _queueSemphore = dispatch_semaphore_create(0);
    [self installStateMachine];
    //schedule send message in thread
    [NSThread detachNewThreadSelector:@selector(scheduleSend) toTarget:self withObject:nil];
    _endPoint = point;
    [self installNotification];
    _connectionSEQ = 13534;
    
    return self;
}

- (BOOL)open:(NSError *__autoreleasing *)error
{
    return  [_stateMachine fireEvent:kEventConnect userInfo:nil error:error];
}

- (BOOL) openConnection:(NSError *__autoreleasing *)error
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
    CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, (__bridge CFStringRef)self.endPoint.host, [self.endPoint.port intValue], &readStream, &writeStream);

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
    return YES;
}

- (void) commectionTimeOut
{
    NSError* error = [NSError YH_Error:kCFSocketTimeout reason:@"链接服务器超时，服务器跑路了！"];
    [_stateMachine fireEvent:kEventErrorOccur userInfo:@{@"error":error} error:nil];
    [self invalideOpenTimeOut];
    DDLogError(@"创建连接失败超时，无法创建连接");
}

- (void) invalideOpenTimeOut
{
    [_connectionTimeOutTimer invalidate];
    [YHNetRunloop removeTimer:_connectionTimeOutTimer];
    _connectionTimeOutTimer = nil;
    DDLogInfo(@"关闭创建连接超时Timer");
}

- (void) openSuccess
{
    DDLogInfo(@"连接建立成功，🎀");
    [self invalideOpenTimeOut];
    [self stopRetry];
    if ((_flag & kDidCompleteOpenForRead) && (_flag & kDidCompleteOpenForWrite) ) {
        [_stateMachine fireEvent:kEventConnected userInfo:nil error:nil];
    }
    dispatch_semaphore_signal(_queueSemphore);

}

- (void) stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    if (aStream == _writeStream) {
        [self writeStream:_writeStream hanldeEvent:eventCode];
    }else if (aStream == _readStream) {
        [self readStream:_readStream handleEvent:eventCode];
    } else {
        DDLogError(@"发生错误的流既不是输入流也不是输出流，我操，什么鬼！！！");
        //error
    }
}

- (void) readBytes
{
    static NSUInteger MaxReadLength = 1024*30;
    while ([_readStream hasBytesAvailable]) {
        uint8_t *buffer = malloc(sizeof(uint8_t) * MaxReadLength);
        int64_t length =  [_readStream read:buffer maxLength:MaxReadLength];
        if (length <= 0) {
            break;
        }
        [self deallWithBuffer:buffer length:length];
        free(buffer);
    }
}
// you must be so carefully about those lines , the sever transfer data not only sperate package and join package!!, so you need join it and sperate it too.
- (void) deallWithBuffer:(uint8_t*)buffer length:(int64_t)length
{

    if (length == NSNotFound) {
        return;
    }
    void(^CheckFull)(void) = ^(void) {
        // if the read buffer is full ,then decode it. Otherwise do nothing , but just wait the next package
        if (_readBuffer.isFull) {
            NSData* data = _readBuffer.bufferData;
            YHFromMessage* msg = [YHCodecWrapper decode:data];
            
            if ([self.delegate respondsToSelector:@selector(connection:getFromMessage:)]) {
                [self.delegate connection:self getFromMessage:msg];
            }
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
    if (0 <length && ( _readBuffer.reciveDataLength + length < aimLength)) {
        [_readBuffer appendBytes:readBufferPoint length:length];
    } else if (_readBuffer.reciveDataLength + length == aimLength) {
        [_readBuffer appendBytes:readBufferPoint length:length];
        CheckFull();
    } else {
        int32_t readLength = (aimLength - _readBuffer.reciveDataLength);
        [_readBuffer appendBytes:readBufferPoint length:readLength];
        CheckFull();
        if (length - readLength < 0) {
            return;
        } else {
            [self deallWithBuffer:readBufferPoint+readLength length:length-readLength];
        }
    }
}

- (void) readStream:(NSInputStream*)stream handleEvent:(NSStreamEvent)eventCode
{
    switch (eventCode) {
        case NSStreamEventOpenCompleted:
            _flag |= kDidCompleteOpenForRead;
            [self openSuccess];
            DDLogInfo(@"写入流建立连接");
            break;
        case NSStreamEventHasBytesAvailable:
            [self readBytes];
            break;
        // if error occurred the close the stream and socket;
            
        case NSStreamEventEndEncountered:
        {
            DDLogError(@"读入流被结束了");
        }
        case NSStreamEventErrorOccurred:
        {
            DDLogError(@"读入流发生问题%@",[stream streamError]);
            [self closeWithError:[stream streamError]];
        }
            break;

        case NSStreamEventNone:
        {
            DDLogError(@"读入流触发其他状态%d", eventCode);
        }
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
            DDLogInfo(@"写入流建立连接");
            break;
        case NSStreamEventHasSpaceAvailable:
            break;
        // if error occurred the close the stream and socket;
        case NSStreamEventEndEncountered:
        {
            
            DDLogError(@"写入流被结束了");
        }
        case NSStreamEventErrorOccurred:
        default:
            {
                DDLogError(@"写入流发生错误%@",[stream streamError]);
                [self closeWithError:[stream streamError]];
            }
            break;
    }
}
- (int64_t) getNextSEQ
{
    static volatile int64_t YHGlobalMessageSendSEQ = 10001;
    OSAtomicIncrement64(&YHGlobalMessageSendSEQ);
    return YHGlobalMessageSendSEQ;
}

- (YHSendMessage*) messageWithCMD:(YHCmd *)cmd data:(NSData *)data headers:(NSDictionary *)headers
{
    YHSendMessage* sendMsg = [YHSendMessage new];
    sendMsg.seq = [self getNextSEQ];
    sendMsg.cmd = cmd;
    sendMsg.dataBuffer = data;
    sendMsg.headers = headers;
    return sendMsg;
}

- (void) sendMessage:(YHSendMessage *)message
{
    DDLogInfo(@"请求%@,放入队列当中 SEQ:[%lld]",message, message.seq);
    @synchronized (_sendQueue) {
        [_sendQueue addObject:message];
    }
    if ([self.delegate respondsToSelector:@selector(connection:enqueueSendMessage:)]) {
        [self.delegate connection:self enqueueSendMessage:message];
    }
    dispatch_semaphore_signal(_queueSemphore);
}

- (void) scheduleSend
{
    while (!_destry) {
        
        void(^eatSendMessage)(void) = ^(void) {
            @autoreleasepool {
                YHSendMessage* msg = nil;
                for (;;) {
                    if (_socketStatus != YHScketConnected) {
                        if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive &&
                            _socketStatus == YHScketDisconnected )
                        {
                            NSError* error;
                            [self open:&error];
                            if (error) {
                                DDLogError(@"在断开的状态下进行重练%@",error);
                            }
                        }
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
                    DDLogInfo(@"取出请求%@",msg);
                    
                    if ([self.delegate respondsToSelector:@selector(connection:willSendMessage:)]) {
                        [self.delegate connection:self willSendMessage:msg];
                    }
                    
                    NSData* data = [YHCodecWrapper encode:msg];
                    
                   NSInteger ret =  [_writeStream write:[data bytes] maxLength:data.length];
                    
                    if ([self.delegate respondsToSelector:@selector(connection:didSendMessage:withError:)]) {
                        if (ret < 0) {
                            [self.delegate connection:self didSendMessage:msg withError:_writeStream.streamError];
                        } else {
                            [self.delegate connection:self didSendMessage:msg withError:nil];
                        }
                    }
#ifdef DEBUG
                    NSLog(@"Send Message %d , %@", msg.seq, msg.cmd);
#endif
                    break;
                    
                }
            }
        };
        int count = _sendQueue.count;
        for (int i = 0; i < count; i++) {
            eatSendMessage();
        }
        dispatch_semaphore_wait(_queueSemphore, DISPATCH_TIME_FOREVER);
    }
}

- (void) closeWithError:(NSError*)error
{
    if (!error) {
        error = [NSError YH_Error:-9999 reason:@"network error unkonwn!!!"];
    }
    [_stateMachine fireEvent:kEventErrorOccur userInfo:@{@"error":error} error:nil];

}

- (void) closeAllStream
{
    DDLogError(@"连接关闭");
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

- (void) close
{
    NSError* error;
    [_stateMachine fireEvent:kEventDisconnection userInfo:nil error:&error];
    if (error) {
        DDLogError(@"扭转状态为关闭态失败%@",error);
    }}
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
    } else {
        [_stateMachine fireEvent:kEventDisconnection userInfo:nil error:nil];
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
        [_stateMachine fireEvent:kEventConnect userInfo:nil error:nil];
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

