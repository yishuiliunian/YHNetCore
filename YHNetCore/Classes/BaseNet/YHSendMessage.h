//
//  YHSendMessage.h
//  Pods
//
//  Created by stonedong on 16/4/23.
//
//

#import <Foundation/Foundation.h>

@class YHCmd;
@interface YHSendMessage : NSObject
@property (nonatomic, strong) YHCmd* cmd;
@property (nonatomic, assign) int32_t version;
@property (nonatomic, strong) NSString* imei;
@property (nonatomic, assign) int64_t seq;
@property (nonatomic, strong) NSDictionary* headers;
@property (nonatomic, assign) BOOL doOneWay;
@property (nonatomic, strong) NSData* dataBuffer;

- (instancetype) initWithSEQ:(int32_t)seq cmd:(YHCmd*)cmd;
@end
