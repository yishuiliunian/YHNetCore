//
//  YHEndPoint.h
//  Pods
//
//  Created by stonedong on 16/4/21.
//
//

#import <Foundation/Foundation.h>

@interface YHEndPoint : NSObject
@property (nonatomic, strong, readonly) NSString* port;
@property (nonatomic, strong, readonly) NSString* host;
@property (nonatomic, assign) CFTimeInterval lastOpenTime;

+ (instancetype) new UNAVAILABLE_ATTRIBUTE;
- (instancetype) init UNAVAILABLE_ATTRIBUTE;

- (instancetype) initWithHost:(NSString*)host port:(NSString*)port;
- (void) onConnected;
- (NSData*) addressIPV4:(NSError* __autoreleasing*)error;
@end
