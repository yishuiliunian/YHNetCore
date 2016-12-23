//
// Created by baidu on 2016/12/22.
//

#import "YHEventMessageFliter.h"
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

@implementation YHEventMessageFliter


- (NSArray*) fliteMessage:(NSArray*)msgs
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
            feedEvent.replyContent = comment.replyContent;
            feedEvent.replyID = comment.replyId;
            //
            feedEvent.opUserID = comment.fromUserName;
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
            feedEvent.date = comment.createTime;
            feedEvent.readed = NO;
            [db updateOrInsertObject:feedEvent];
            eventCount ++;
        } else if (event.subType == EVENT_DYEING) {
            EventDyeing* dyeing = [EventDyeing parseFromData:event.subBody error:nil];
            NSString * uid = dyeing.dyeingId;
            if (uid.length) {

                DZMissionTask * task = [DZMissionTask new];
                task.startDate = [NSDate date];
                task.endDate = [[NSDate date] dateByAddingDays:1];
                task.name = @"upload_logs";
                task.additions = @{@"upid":uid};
                task.exclusive = YES;
                [[DZMissionManager shareActiveManger] addMission:task];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [[DZMissionManager shareActiveManger] tryTriggleMission];
                });
            } else {
                [[DZMissionManager shareActiveManger] completeMissionByKey:@"upload_logs"];
            }

        }
    }
    if (eventCount) {
        DZPostFeedCommentEventArrive(@{});
    }
}

@end