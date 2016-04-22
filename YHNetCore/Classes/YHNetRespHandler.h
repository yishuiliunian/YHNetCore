//
//  YHNetRespHandler.h
//  Pods
//
//  Created by stonedong on 16/4/19.
//
//

#import <Foundation/Foundation.h>

@interface YHNetRespHandler : NSObject
@property (atomic, assign, readonly) BOOL active;
- (void) startWithReadStream:(CFReadStreamRef) readStream;
@end
