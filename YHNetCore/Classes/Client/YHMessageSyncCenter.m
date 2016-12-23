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
@private
    NSMutableArray * _messageQueue;
    NSRecursiveLock * _lock;
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
    _messageQueue = [NSMutableArray new];
    _lock = [NSRecursiveLock new];
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

- (void) onHandleReceivedRemoteMessages
{
    NSArray * msgs = nil;
    NSArray *(^GetMsgs)() = ^ {
         NSArray * msgs = [_messageQueue copy];
        [_messageQueue removeAllObjects];
        return msgs;
    };
    if ([_lock tryLock]) {
        msgs = GetMsgs();
        [_lock unlock];
    } else {
        msgs = GetMsgs();
    }
    if (msgs.count) {
        DZPostNewServerMessage(@{
                 @"messages":[msgs copy],
        });
    }
#ifdef DEBUG
    NSLog(@"Perform Notify ReceiveMessges %d", msgs.count);
#endif
}

- (void) recivePushMessages:(NSArray *)msgs
{
    int remoteRequeCount = 0;
    [_lock lock];
    remoteRequeCount = [_messageQueue count];
    [_lock unlock];
    if (remoteRequeCount) {
        [self reciveRemoteMessages:msgs];
    } else {
        NSArray* flitedMsgs = [self flieMessages:msgs];
        NSArray* messages = [YHActiveDBConnection updateMessagesFromServer:flitedMsgs];
        if (messages.count) {
            DZPostNewServerMessage(@{
                    @"messages":[messages copy],
            });
        }
    }

}

- (void) reciveRemoteMessages:(NSArray*)msgs
{
    __block NSArray * flitedMsgs = msgs;
    __block int cachedMessageCount = 0;
    void (^ReceiveBlock)() = ^ {
        flitedMsgs = [self flieMessages:flitedMsgs];
        NSArray* messages = [YHActiveDBConnection updateMessagesFromServer:msgs];
        [_messageQueue addObjectsFromArray:messages];
        cachedMessageCount = _messageQueue.count;
    };

    if ([_lock tryLock]) {
        ReceiveBlock();
        [_lock unlock];
    } else {
        ReceiveBlock();
    }
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(onHandleReceivedRemoteMessages) object:Nil];
    if (cachedMessageCount < 150) {
        [self performSelector:@selector(onHandleReceivedRemoteMessages) withObject:nil afterDelay:0.3];
    } else {
        [self onHandleReceivedRemoteMessages];
    }
}

@end
