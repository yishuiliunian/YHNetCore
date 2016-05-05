//
//  YHAcquirRequest.h
//  Pods
//
//  Created by stonedong on 16/5/5.
//
//

#import <YHNetCore/YHNetCore.h>
#import "RpcMsgMessage.pbobjc.h"
#import "RpcPushMessage.pbobjc.h"
@interface YHAcquirRequest : YHAuthedRequest
@property (nonatomic, strong,readonly) AcquireRequest* acquire;
@end
