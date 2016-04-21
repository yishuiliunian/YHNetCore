//
//  YHNetSocketConnection.h
//  Pods
//
//  Created by stonedong on 16/4/19.
//
//

#import <Foundation/Foundation.h>

@class YHNetCommunicator;
@interface YHNetSocketConnection : NSObject

- (instancetype) initWithCommunicator:(YHNetCommunicator*)c;

@end
