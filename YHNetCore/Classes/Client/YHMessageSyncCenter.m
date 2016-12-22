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
#import <DateTools/DateTools.h>
#import "YHURLRouteDefines.h"
#import "DZMissionTask.h"
#import "DZMissionManager.h"
#import "YHEventMessageFliter.h"

@interface YHMessageSyncCenter ()
{
@protected
    NSMutableArray * _receiveFlitersLocal;
}
@property (nonatomic, assign) int64_t lastCookiedId;
@property  (nonatomic, strong, readonly) NSArray * receiveFliters;
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

- (instancetype)init {
    self = [super init];
    if (!self) {
        return self;
    }
    _receiveFlitersLocal = [NSMutableArray new];
    [self addReceiveFliter:[YHEventMessageFliter new]];
    return self;
}



- (NSArray *)receiveFliters {
    return [_receiveFlitersLocal copy];
}

- (void) addReceiveFliter:(id<YHMessageReceiveFliter>)fliter
{
    NSParameterAssert(fliter);
    [_receiveFlitersLocal addObject:fliter];
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
        //如果当前缓存ID为0则不进行确认
        if (object.cookieId == 0) {
            return ;
        }
        YHAcquirRequest* req = [YHAcquirRequest new];
        req.acquire.cookieId = object.cookieId;
        req.b_oneway = YES;
        req.skey = DZActiveAuthSession.token;
        [req start];
        
    }];
    
    [sync start];
}
- (NSArray*) flieMessages:(NSArray*)msgs
{
    for (id<YHMessageReceiveFliter> fliter in self.receiveFliters) {
        msgs = [fliter fliteMessage:msgs];
    }
    return msgs;
}


- (void) reciveRemoteMessages:(NSArray*)msgs
{
    msgs = [self flieMessages:msgs];
    NSArray* messages = [YHActiveDBConnection updateMessagesFromServer:msgs];
    if (messages.count) {
        DZPostNewServerMessage(@{
                                 @"messages":[messages copy],
                                 });
    }
    
}
@end
