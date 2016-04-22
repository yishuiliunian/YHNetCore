//
//  YHNetRunloop.h
//  Pods
//
//  Created by baidu on 16/4/22.
//
//

#import <Foundation/Foundation.h>
#define YHNetDefaultRunloop [YHNetRunloop runloop]

@interface YHNetRunloop : NSObject
+ (NSArray*) runloopModes;
+ (NSRunLoop*) runloop;
@end
