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

//---------Toast包括：

typedef NS_ENUM(NSUInteger, TOAST_VALUE) {
    TOAST_TROOP_MEMBER_KILL = 0x0001,//（非全员，有人被踢，被踢者接收的是事件，非toast）
    TOAST_TROOP_MEMBER_JOIN = 0x0003,//（非全员，入群者不用收该消息）
    TOAST_TROOP_MEMBER_QUIT = 0x0004,//（非全员，退群者不用收该消息）
    TOAST_PWD_UPDATE = 0x0040,//新注册或重置密码系统消息提示
    TOAST_CLASS_JOIN = 0x0011//有人申请加入班级
};

//---------事件包括：

//0x4001: 被踢, 0x4002: 活动关闭, 0x4010：班级解散


typedef NS_ENUM(NSUInteger, EVENT_VALUE) {
    EVENT_TROOP_MEMBER_KILL = 0x4001,//自己被踢
    EVENT_TROOP_CLOSE = 0x4002,//群关闭 = 事件 （非全员，群主不用收该事件） + 所有人收到关群的系统消息(包括群主)
    EVENT_CLASS_CLOSE = 0x4010//班级解散 = 事件 （非全员，班长不用收该事件） + 所有人收到班级关闭的系统消息（包括班长）
};





@interface YHSyncMsgRequest : YHAuthedRequest
@property (nonatomic, strong, readonly) SyncMsgRequest* syncMsg;
@end
