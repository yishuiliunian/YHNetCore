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
    YHSyncMsgRequest* sync = [YHSyncMsgRequest new];
    sync.syncMsg.cookieId = cookieId;
    sync.skey = DZActiveAuthSession.token;
    
    [sync setErrorHandler:^(NSError *error) {
        
    }];
    
    [sync setSuccessHanlder:^(SyncMsgResponse* object) {
        if (object.cookieId != 0) {
            weakSelf.lastCookiedId = object.cookieId;
            return;
        }
        if (object.msgArray.count == 0) {
            return ;
        }
        NSArray* messages = [YHActiveDBConnection updateMessagesFromServer:object.msgArray];
        if (messages.count) {
            DZPostNewServerMessage(@{
                                     @"messages":[messages copy],
                                     });
        }
        
        YHAcquirRequest* req = [YHAcquirRequest new];
        req.acquire.cookieId = object.cookieId;
        req.b_oneway = YES;
        req.skey = DZActiveAuthSession.token;
        [req start];
        
    }];
    
    [sync start];
}
@end
