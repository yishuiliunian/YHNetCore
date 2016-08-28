//
//  YHRequest_SendIntereact.h
//  Pods
//
//  Created by stonedong on 16/8/28.
//
//

#import <YHNetCore/YHNetCore.h>


@interface YHRequest ()
/**
 *  当交付到具体的链接上的时候，该字段表示当前请求交付到了哪个连接上面
 */
@property (atomic, assign) int64_t connectionSEQ;
@end
