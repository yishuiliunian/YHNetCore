//
//  YHNetClient.m
//  Pods
//
//  Created by stonedong on 16/4/23.
//
//

#import "YHNetClient.h"
#import "YHNetSocketConnection.h"
#import "YHEndPoint.h"
#import "YHCmd.h"
#import "YHSendMessage.h"
#import <libkern/OSAtomic.h>
#import "GPBMessage.h"
#import "YHFromMessage.h"
#import "YHNetResponseDispatch.h"
#import "YHPushMessageHanlder.h"
#import "YHHearterService.h"
#import "YHPushNotifyHandler.h"
#import "DZAuthSession.h"
#import <DZLogger/DZLogger.h>
#import "YHAcquirRequest.h"
#import "YHDNS.h"
#import "YHNetStatus.h"
#import "YHRequest_RequestID.h"
#import "NSError+YHNetError.h"
#import "DZLogger.h"
#import "YHAuthedRequest.h"
#import "YHNetRunloop.h"
#import "YHRequest_Timeout.h"
#import "YHMessageSyncCenter.h"
#import "YHNetStatus.h"
#import "YHRequest_SendIntereact.h"
@interface YHNetClient () <YHNetSocketConnectionDelegate>
{
    YHNetSocketConnection* _connection;
    NSMutableDictionary* _requestCache;
    YHNetResponseDispatch* _pushHanlder;
    YHHearterService* _heaterService;
    
    NSInteger _timeOutCount;
    NSTimeInterval _lastTimeOutTimeSpace;
    /**
     *  每隔0.1s检查一下_sendQueue中的请求是否存在超时的，存在超时的请求则进行清除操作
     */
    NSTimer* _timeoutTimer;
}
@end

@implementation YHNetClient

+ (YHNetClient*)shareClient
{
    static YHNetClient* client = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        client = [YHNetClient new];
    });
    return client;
}
- (instancetype) init
{
    self = [super init];
    if (!self) {
        return self;
    }
    YHHost* host = [YHDNS shareDNS].yaoheHost;
    YHEndPoint* endP0int = [[YHEndPoint alloc] initWithHost:host.ip port:host.port];
    _connection = [[YHNetSocketConnection alloc] initWithEndPoint:endP0int];
    _connection.delegate = self;
    _requestCache = [NSMutableDictionary new];
    //
    _heaterService = [YHHearterService new];
    //
    _pushHanlder = [YHNetResponseDispatch new];
    [_pushHanlder registerHandler:[[YHPushMessageHanlder alloc] init]];
    [_pushHanlder registerHandler:[YHPushNotifyHandler new]];
    [self open];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [YHNetStatus shareInstance];
    });
   
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAccountResign) name:kDZAuthSessionResignActive object:nil];
    return self;
}

- (YHNetSocketConnection*) currentSocketConnection
{
    return _connection;
}
- (void) onAccountResign
{
    DDLogInfo(@"网络层捕获到用户退出操作，关闭网络链接");
    [_connection close];
    NSError* error;
    DDLogInfo(@"网络层捕获到用户退出操作，重新建立网络链接");
    [_connection open:&error];
    if (error) {
        DDLogError(@"重新建立网络链接失败,%@",error);
    }
}
- (void) startTimeoutTimer
{
    if (_timeoutTimer.valid) {
        return;
    }
    _timeoutTimer = [NSTimer timerWithTimeInterval:0.1 target:self selector:@selector(checkTimeoutRequest:) userInfo:nil repeats:YES];
    [YHNetRunloop addTimer:_timeoutTimer ];
}




- (void) stopTimeoutTimer
{
    [_timeoutTimer invalidate];
    [YHNetRunloop removeTimer:_timeoutTimer];
    _timeoutTimer = nil;
}

- (void) checkTimeoutRequest:(NSTimer*)timer
{
    @synchronized (_requestCache) {
        NSArray* allKeys= [_requestCache allKeys];
        NSMutableArray* willTimeOutRequests = [NSMutableArray new];
        CFTimeInterval now = CFAbsoluteTimeGetCurrent();
        for (NSNumber* key in allKeys) {
            YHRequest* req = _requestCache[key];
            if (ABS(req.startReqeustTime - now) > req.timeout) {
                [willTimeOutRequests addObject:key];
                if (!req.b_oneway) {
                    [req onError:[NSError YH_Error:kYHNetErrorTimeOut reason:@"服务好长时间没反应，跑路了？"]];
                    _timeOutCount ++;
                    _lastTimeOutTimeSpace = CFAbsoluteTimeGetCurrent() - _lastTimeOutTimeSpace;
                    [self checkWillReconnection];
                }
            }
        }
        [_requestCache removeObjectsForKeys:willTimeOutRequests];
    }
    [self tryStopTimeoutTimer];
}

- (void) checkWillReconnection
{
    DDLogInfo(@"检查是否需要重置链接");
    if (_lastTimeOutTimeSpace < 30 && _timeOutCount > 2) {
        if ([YHNetStatus shareInstance].currentStatus != NotReachable) {
            DDLogInfo(@"需要重置链接，进行链接重置操作,当前有网络");
            [_connection close];
            NSError* error;
            [_connection open:&error];
            if (error) {
                DDLogError(@"打开链接失败%@",error);
            }
            _timeOutCount ==0;
        } else {
            DDLogInfo(@"当前没有网络，不进行链接重置操作");
        }
    }
}

- (void) tryStartTimeoutTimer
{
    @synchronized (_requestCache) {
        if (_requestCache.count) {
         [self startTimeoutTimer];
        }
    }
}

- (void) tryStopTimeoutTimer
{
    @synchronized (_requestCache) {
        if (_requestCache.count == 0) {
            [self stopTimeoutTimer];
        }
    }
}
                     

- (void) open
{
    NSError* error;
    [_connection open:&error];
    DDLogError(@"打开链接失败%@",error);
}


- (void) performRequest:(YHRequest *)request
{
    if ([YHNetStatus shareInstance].currentStatus == NotReachable) {
        NSError* error = [NSError YH_Error:kYHNetNotnetwork reason:@"没有网络链接，请检查网络!"];
        [request onError:error];
        return;
    }
    YHCmd* cmd = [YHCmd cmdWithServant:request.servant method:request.method];
    YHSendMessage* msg = [_connection messageWithCMD:cmd data:request.requestData.data headers:request.requestHeader];
    msg.doOneWay = request.b_oneway;
    if (!request.b_oneway) {
        @synchronized (_requestCache) {
            _requestCache[@(msg.seq)] = request;
        }
    }
    request.seq = msg.seq;
    request.startReqeustTime = CFAbsoluteTimeGetCurrent();
    [_connection sendMessage:msg];
    [self tryStartTimeoutTimer];
}

- (YHRequest*) takeRequestWithSEQ:(int64_t)seq
{
    YHRequest* request = nil;
    @synchronized (_requestCache) {
        request = _requestCache[@(seq)];
        if (request) {
            [_requestCache removeObjectForKey:@(seq)];
        }
    }
    [self tryStopTimeoutTimer];
    return request;
}

- (void) connection:(YHNetSocketConnection *)connection didSendMessage:(YHSendMessage *)message withError:(NSError *)error
{
    if (error) {
        YHRequest* request = [self takeRequestWithSEQ:message.seq];
        [request onError:error];
    } else {
        YHRequest* request = nil;
        @synchronized (_requestCache) {
            request = _requestCache[@(message.seq)];
            request.connectionSEQ = connection.connectionSEQ;
        }

    }

}
- (void) connectionWillOpen:(YHNetSocketConnection *)connection
{
    DZPostNetworkSocketStatusChanged(@{});
}

- (void) connectionDidOpen:(YHNetSocketConnection *)connection
{
    if (DZActiveAuthSession) {
        [_heaterService startBeating];
        [_heaterService forceBeating];
        [[YHMessageSyncCenter shareCenter] syncMessage:0];
    }
    DZPostNetworkSocketStatusChanged(@{});
}

- (void) clearRequstOnCloseConnection:(YHNetSocketConnection*)connection
{
    
    @synchronized (_requestCache) {
        int64_t connectionID = connection.connectionSEQ;
        NSArray* allSEQs = _requestCache.allKeys;
        NSMutableArray* willClearSEQ = [NSMutableArray new];
        for (NSNumber* seq  in allSEQs) {
            YHRequest* req = _requestCache[self];
            if (req.connectionSEQ == connectionID) {
                [willClearSEQ addObject:seq];
                NSError* error = [NSError YH_Error:kYHNetSendButConnectionClose reason:@"请求已发出，但链接断开，无法接受回文"];
                [req onError:error];
            }
        }
        [_requestCache removeObjectsForKeys:willClearSEQ];
    }
}
- (void) connectionDidClose:(YHNetSocketConnection *)connection
{
    [self clearRequstOnCloseConnection:connection];
    [_heaterService stopBeating];
    DZPostNetworkSocketStatusChanged(@{});
}

- (void) connection:(YHNetSocketConnection *)connection getFromMessage:(YHFromMessage *)message
{
    if (connection != _connection) {
        return;
    }
    _timeOutCount = 0;
    DDLogInfo(@"从服务器得到响应SEQ[%D],\%@", message.seq, message.cmd);
    YHRequest* request = [self takeRequestWithSEQ:message.seq];
    if (request) {
        [request reciveRspMessage:message];
    }
    else if(![_pushHanlder handleFromMessage:message])
    {
        DDLogError(@"无法处理消息%@",message);
    }
    if ([request isKindOfClass:[YHAuthedRequest class]]) {
        if (message.error.code == 14) {
            DDLogError(@"捕获到登录态错误,%@",request);
            [[NSNotificationCenter defaultCenter] postNotificationName:kYHSkeyInvalidNotification object:nil];
        }
    }
    
}

@end
