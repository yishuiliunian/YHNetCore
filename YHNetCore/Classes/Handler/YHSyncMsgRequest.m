//
//  YHSyncMsgRequest.m
//  Pods
//
//  Created by stonedong on 16/5/3.
//
//

#import "YHSyncMsgRequest.h"
#import "YHCoreDB.h"
#import "DZAuthSession.h"
#import "YHAcquirRequest.h"

@implementation YHSyncMsgRequest

- (instancetype) init
{
    self = [super init];
    if (!self) {
        return self;
    }
    _responseClass = [SyncMsgResponse class];
    return self;
}

- (NSString*) method
{
    return @"rpc.MsgService.SyncMsg";
}


- (NSString*) servant
{
    return @"Comm.MsgServer.MsgObj";
}

- (SyncMsgRequest*) syncMsg
{
    if (!_requestData) {
        _requestData = [SyncMsgRequest new];
    }
    return  (SyncMsgRequest*) _requestData;
}

- (void) onError:(NSError *)error
{
    [super onError:error];
}
- (void) onNetSuccess:(SyncMsgResponse*)object
{
    NSString* uid = DZActiveAuthSession.userID;
   
    RLMRealm* realm = YHDBConnectionWithUID(uid);
    
    [realm beginWriteTransaction];
    for (Msg* msg  in object.msgArray) {
        YHMessage* message = [YHMessage objectInRealm:realm forPrimaryKey:@(msg.msgId)];
        if (!message) {
            message = [YHMessage new];
            message.msgID = msg.msgId;
        }
        message.seqID = msg.msgId;
        message.msgStatus = MsgStatus_Delivered;
        message.isRead = NO;
        message.extention  = msg.msgExt;
        message.data = msg.msgBody;
        message.createTime = msg.createTime;
        message.type = msg.msgType;
        message.fromAccount = msg.fromUserName;
        message.fromType = msg.fromUserType;
        message.toAccount = msg.toUserName;
        message.toType = msg.toUserType;
        [realm addOrUpdateObject:message];
    }
    [realm commitWriteTransaction];
    [super onNetSuccess:object];
    
    
    YHAcquirRequest* req = [YHAcquirRequest new];
    req.acquire.cookieId = object.cookieId;
    req.b_oneway = YES;
    req.skey = DZActiveAuthSession.token;
    [req start];
}
@end
