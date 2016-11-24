//
//  NSError+YHNetError.h
//  Pods
//
//  Created by stonedong on 16/4/23.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, YHNetErrorCode) {
    kYHNetErrorTimeOut = -8000,//超时错误
    kYHNetActiveDisconnect = -8001,//没有活跃链接
    kYHNetNotnetwork = -8002 ,//没有网络
    kYHNetSendButConnectionClose = -8100,//数据上行请求发出去了，但是链接断开了，就收不到回报数据了
};
FOUNDATION_EXTERN NSString* const YHNetErrorDomain;
@interface NSError (YHNetError)

+ (NSError*) YH_Error:(int)code reason:(NSString*)reason;

@end
