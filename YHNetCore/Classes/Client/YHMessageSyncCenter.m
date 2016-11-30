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
    int eventCount = 0;
    YHDataBaseConnection* db =            YHActiveDBConnection;
    for (Msg* msg in msgs) {
        Event* event = [Event parseFromData:msg.msgBody error:nil];
        if (event.subType == EVENT_CLASS_CLOSE ||
            event.subType == EVENT_TROOP_CLOSE ||
            event.subType == EVENT_TROOP_MEMBER_KILL) {
            DZRouteRequestContext* context = [DZRouteRequestContext new];
            [context setValue:event forKey:@"event"];
            NSURL* url = DZURLRouteQueryLink(kYHURLEventHandler, @{});
            [[DZURLRoute defaultRoute] locationResource:url context:context redirect404:NO];
        } else if (event.subType == EVENT_COMMENT) {
            NSError* error;
            EventComment* comment = [EventComment parseFromData:event.subBody error:&error];
            if (error) {
                DDLogError(@"%@",error);
                continue;
            }
            YHFeedEvent* feedEvent = [YHFeedEvent new];
            feedEvent.eventID = msg.msgId;
            feedEvent.type = YHFeedEventTypeComment;
            //
            feedEvent.contentID = comment.commentId;
            feedEvent.subType = comment.commentType;
            feedEvent.content = comment.commentDigest;
            feedEvent.contentURL = comment.commentImage.URL;
            //
            feedEvent.toUserID = comment.toUserName;
            feedEvent.toUserNick = comment.toNick;
            feedEvent.replyContent = comment.replyContent;
            feedEvent.replyID = comment.replyId;
            //
            feedEvent.opUserID = comment.fromUserName;
            feedEvent.opUserNick  = comment.fromNick;
            feedEvent.opUserFaceURL = comment.fromFaceURL;
            feedEvent.readed = NO;
            feedEvent.date = comment.createTime;
            
            [db updateOrInsertObject:feedEvent];
            eventCount ++;
        } else if (event.subType == EVENT_LIKE) {
            NSError* error;
            EventLike* comment = [EventLike parseFromData:event.subBody error:&error];
            if (error) {
                DDLogError(@"%@",error);
                continue;
            }
            
            YHFeedEvent* feedEvent = [YHFeedEvent new];
            feedEvent.eventID = msg.msgId;
            feedEvent.type = YHFeedEventTypeLike;
            feedEvent.subType = comment.contentType;
            feedEvent.content = comment.contentDigest;
            feedEvent.contentURL = comment.contentImage.URL;
            feedEvent.contentID = comment.contentId;
            feedEvent.opUserID = comment.fromUserName;
            feedEvent.opUserNick  = comment.fromNick;
            feedEvent.opUserFaceURL = comment.fromFaceURL;
            feedEvent.date = comment.createTime;
            feedEvent.readed = NO;
            [db updateOrInsertObject:feedEvent];
            eventCount ++;
        }
    }
    if (eventCount) {
        DZPostFeedCommentEventArrive(@{});
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
