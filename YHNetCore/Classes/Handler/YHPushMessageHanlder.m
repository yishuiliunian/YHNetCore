//
//  YHPushMessageHanlder.m
//  Pods
//
//  Created by stonedong on 16/4/27.
//
//

#import "YHPushMessageHanlder.h"
#import "YHCoreDB.h"
#import "DZAuthSession.h"
#import "YHAcquirRequest.h"
@implementation YHPushMessageHanlder
- (instancetype) init
{
    self = [super init];
    if (!self) {
        return self;
    }
    _responseClass = [PushMsgRequest class];
    return self;
}
- (NSString*) method
{
    return @"rpc.PushService.PushMsg";
}

- (NSString*) servant
{
    return @"Comm.DispatchServer.PushObj";
}

- (void) onHandleError:(NSError *)error
{
    
}

- (void) onHandleObject:(PushMsgRequest*)object
{
    NSMutableArray* objects = [NSMutableArray new];
    for (Msg* msg  in object.msgArray) {
        YHMessage* message = [YHActiveDBConnection messageWithSeqID:msg.msgId];
        if (!message) {
            message = [YHMessage new];
            message.msgID = YHActiveDBConnection.genNextMsgId;
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
        [objects addObject:message];
    }
    [YHActiveDBConnection updateObjects:objects];
    
    
    
    YHAcquirRequest* req = [YHAcquirRequest new];
    req.acquire.cookieId = object.cookieId;
    req.b_oneway = YES;
    req.skey = DZActiveAuthSession.token;
    [req start];
}

@end
