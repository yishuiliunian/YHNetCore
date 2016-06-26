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
@interface YHNetClient () <YHNetSocketConnectionDelegate>
{
    YHNetSocketConnection* _connection;
    NSMutableDictionary* _requestCache;
    YHNetResponseDispatch* _pushHanlder;
    YHHearterService* _heaterService;
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
    return self;
}


- (void) open
{
    NSError* error;
    [_connection open:&error];
    DDLogError(@"打开链接失败%@",error);
}


- (void) performRequest:(YHRequest *)request
{
    YHCmd* cmd = [YHCmd cmdWithServant:request.servant method:request.method];
    YHSendMessage* msg = [_connection messageWithCMD:cmd data:request.requestData.data headers:request.requestHeader];
    msg.doOneWay = request.b_oneway;
    @synchronized (_requestCache) {
        _requestCache[@(msg.seq)] = request;
    }
    [_connection sendMessage:msg];
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
    return request;
}

- (void) connectionDidOpen:(YHNetSocketConnection *)connection
{
    if (DZActiveAuthSession) {
        [_heaterService startBeating];
    }
}

- (void) connectionDidClose:(YHNetSocketConnection *)connection
{
    [_heaterService stopBeating];
}

- (void) connection:(YHNetSocketConnection *)connection getFromMessage:(YHFromMessage *)message
{
    if (connection != _connection) {
        return;
    }
    
    YHRequest* request = [self takeRequestWithSEQ:message.seq];
    if (request) {
        [request reciveRspMessage:message];
    }
    else if([_pushHanlder handleFromMessage:message])
    {
        DDLogError(@"无法处理消息%@",message);
    }
}


@end
