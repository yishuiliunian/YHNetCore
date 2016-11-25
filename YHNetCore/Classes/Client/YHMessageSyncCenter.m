//
//  YHMessageSyncCenter.m
//  Pods
//
//  Created by stonedong on 16/6/25.
//
//

#import "YHMessageSyncCenter.h"
#import "YHSyncMsgRequest.h"
#import "DZAuthSession.h"
#import "YHCoreDB.h"
#import "DZAuthSession.h"
#import "YHAcquirRequest.h"
#import "YHNetNotification.h"
#import <DZLogger.h>
#import "YHURLRouteDefines.h"

@interface YHMessageSyncCenter ()
@property (nonatomic, assign) int64_t lastCookiedId;
@end

@implementation YHMessageSyncCenter

+ (YHMessageSyncCenter*) shareCenter
{
    static YHMessageSyncCenter* center =nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        center = [YHMessageSyncCenter new];
    });
    return center;
}

- (void) syncMessage:(int64_t)cookieId
{
    __weak typeof(self) weakSelf = self;
    if (DZActiveAuthSession.token.length == 0) {
        return;
    }
    DDLogInfo(@"%%%%%%%%同步消息%d%%%%%%%%%",cookieId);
    YHSyncMsgRequest* sync = [YHSyncMsgRequest new];
    sync.syncMsg.cookieId = cookieId;
    sync.skey = DZActiveAuthSession.token;
    
    [sync setErrorHandler:^(NSError *error) {
        DDLogError(@"同步消息失败%@",error);
    }];
    
    [sync setSuccessHanlder:^(SyncMsgResponse* object) {
        DDLogInfo(@"同步消息成功");
        if (object.cookieId != 0) {
            weakSelf.lastCookiedId = object.cookieId;
        }
        [weakSelf reciveRemoteMessages:object.msgArray];
        DDLogInfo(@"进行消息确认!");
        YHAcquirRequest* req = [YHAcquirRequest new];
        req.acquire.cookieId = object.cookieId;
        req.b_oneway = YES;
        req.skey = DZActiveAuthSession.token;
        [req start];
        
    }];
    
    [sync start];
}
- (NSArray*) fliteEventRemoteMessage:(NSArray*)msgs
{
    NSMutableArray* dbMsgs = [NSMutableArray new];
    NSMutableArray* eventMsgs = [NSMutableArray new];
    for (Msg* msg in msgs) {
        if (msg.msgType == MsgType_Event) {
            [eventMsgs addObject:msg];
        } else {
            [dbMsgs addObject:msg];
        }
    }
    [self handleEventMessage:eventMsgs];
    return dbMsgs;
}

- (void) handleEventMessage:(NSArray*)msgs
{
    for (Msg* msg in msgs) {
        DZRouteRequestContext* context = [DZRouteRequestContext new];
        Event* event = [Event parseFromData:msg error:nil];
        [context setValue:event forKey:@"event"];
        
        NSURL* url = DZURLRouteQueryLink(kYHURLEventHandler, @{});
        [[DZURLRoute defaultRoute] locationResource:url context:context redirect404:NO];
    }
}


- (void) reciveRemoteMessages:(NSArray*)msgs
{
    msgs = [self fliteEventRemoteMessage:msgs];
    NSArray* messages = [YHActiveDBConnection updateMessagesFromServer:msgs];
    if (messages.count) {
        DZPostNewServerMessage(@{
                                 @"messages":[messages copy],
                                 });
    }
    
}
@end
