//
//  YHNetCommunicator.h
//  Pods
//
//  Created by stonedong on 16/4/19.
//
//

#import <Foundation/Foundation.h>
#import "YHNetSender.h"
#import "YHNetRespHandler.h"
@interface YHNetCommunicator : NSObject
@property (nonatomic, strong, readonly) YHNetSender* sender;
@property (nonatomic, strong, readonly) YHNetRespHandler* respHandler;
@end


