//
//  YHSyncMsgRequest.h
//  Pods
//
//  Created by stonedong on 16/5/3.
//
//

#import <YHNetCore/YHNetCore.h>
#import "RpcMsgMessage.pbobjc.h"
#import "RpcPushMessage.pbobjc.h"
@interface YHSyncMsgRequest : YHAuthedRequest
@property (nonatomic, strong, readonly) SyncMsgRequest* syncMsg;
@end
