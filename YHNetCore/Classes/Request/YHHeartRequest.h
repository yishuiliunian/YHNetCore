//
//  YHHeartRequest.h
//  YaoHe
//
//  Created by stonedong on 16/4/26.
//  Copyright © 2016年 stonedong. All rights reserved.
//

#import "YHAuthedRequest.h"
#import "RpcLoginMessage.pbobjc.h"
@interface YHHeartRequest : YHAuthedRequest
@property (nonatomic, strong, readonly) HeartBeatRequest* heartBeat;
@end
