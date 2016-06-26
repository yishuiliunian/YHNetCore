//
//  YHCmd.h
//  Pods
//
//  Created by stonedong on 16/4/23.
//
//

#import <Foundation/Foundation.h>

@interface YHCmd : NSObject
@property (nonatomic, strong, readonly) NSString* servant;
@property (nonatomic, strong, readonly) NSString* method;

+ (instancetype) new UNAVAILABLE_ATTRIBUTE;
- (instancetype) new UNAVAILABLE_ATTRIBUTE;

+ (instancetype) cmdWithServant:(NSString*)servant method:(NSString*)method;
- (instancetype) initWithServant:(NSString*)servant method:(NSString*)method;
@end
