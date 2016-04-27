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
@interface YHNetClient () <YHNetSocketConnectionDelegate>
{
    YHNetSocketConnection* _connection;
    NSMutableDictionary* _requestCache;
    YHNetResponseDispatch* _pushHanlder;
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
    YHEndPoint* endP0int = [[YHEndPoint alloc] initWithHost:@"182.254.232.60" port:@"10010"];
    _connection = [[YHNetSocketConnection alloc] initWithEndPoint:endP0int];
    _connection.delegate = self;
    _requestCache = [NSMutableDictionary new];
    _pushHanlder = [YHNetResponseDispatch new];
    [_pushHanlder registerHandler:[[YHPushMessageHanlder alloc] initWithServant:@"Comm.DispatchServer.PushObj" method:@"rpc.PushService.PushMsg"]];
    [self open];
    return self;
}


- (void) open
{
    NSError* error;
    [_connection open:&error];
}


- (void) performRequest:(YHRequest *)request
{
    YHCmd* cmd = [YHCmd cmdWithServant:request.servant method:request.method];
    int64_t seq = [_connection sendCMD:cmd data:request.requestData.data headers:request.requestHeader];
    @synchronized (_requestCache) {
        _requestCache[@(seq)] = request;
    }
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

- (void) connection:(YHNetSocketConnection *)connection getFromMessage:(YHFromMessage *)message
{
    if (connection != _connection) {
        return;
    }
    YHRequest* request = [self takeRequestWithSEQ:message.seq];
    if (request) {
        [request reciveRspMessage:message];
    } else if([_pushHanlder handleFromMessage:message])
    {
        NSLog(@"Can't Handler message");
    }
}
- (int64_t) sendCMD:(YHCmd*)cmd data:(NSData*)data headers:(NSDictionary*)headers
{
    return[_connection sendCMD:cmd data:data headers:headers];
}

@end
