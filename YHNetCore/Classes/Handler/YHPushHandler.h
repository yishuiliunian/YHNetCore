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
{
    Class _responseClass;
}
@property (nonatomic, strong, readonly) NSString* servant;
@property (nonatomic, strong, readonly) NSString* method;
- (BOOL) canHanldCmd:(YHCmd*)cmd;
- (BOOL) handleFromMessage:(YHFromMessage*)message;


- (void) onHandleObject:(id)object;
- (void) onHandleError:(NSError*)error;
@end
