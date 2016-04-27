//
//  YHPushHandler.h
//  Pods
//
//  Created by stonedong on 16/4/27.
//
//

#import <Foundation/Foundation.h>

@class YHCmd;
@class YHFromMessage;
@interface YHPushHandler : NSObject
@property (nonatomic, strong, readonly) NSString* servant;
@property (nonatomic, strong, readonly) NSString* method;
- (instancetype) initWithServant:(NSString*)servant method:(NSString*)method;
- (BOOL) canHanldCmd:(YHCmd*)cmd;
- (void) handleFromMessage:(YHFromMessage*)message;
@end
