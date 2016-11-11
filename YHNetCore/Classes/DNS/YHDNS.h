//
//  YHDNS.h
//  Pods
//
//  Created by stonedong on 16/6/26.
//
//

#import <Foundation/Foundation.h>
#import "YHHost.h"
@interface YHDNS : NSObject
@property (nonatomic, strong, readonly) YHHost* debugHost;
@property (nonatomic, strong, readonly) YHHost* yaoheHost;
+ (YHDNS*) shareDNS;
@end
