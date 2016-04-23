//
//  YHFromMessage.h
//  Pods
//
//  Created by stonedong on 16/4/23.
//
//

#import <Foundation/Foundation.h>

@class YHCmd;
@interface YHFromMessage : NSObject
@property (nonatomic, strong) YHCmd* cmd;
@property (nonatomic, assign) int64_t seq;
@property (nonatomic, strong) NSDictionary* headers;
@property (nonatomic, strong) NSData* data;
@property (nonatomic, assign) BOOL doOneWay;
@property (nonatomic, strong) NSError* error;

+ (instancetype) new UNAVAILABLE_ATTRIBUTE;
- (instancetype) init UNAVAILABLE_ATTRIBUTE;
- (instancetype) initWithSEQ:(int64_t)seq cmd:(YHCmd*)cmd;

@end
