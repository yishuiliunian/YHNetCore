//
//  YHMessageReceiveFilter.h
//  YaoHe
//
//  Created by baidu on 2016/12/22.
//
//

#import <Foundation/Foundation.h>

@protocol YHMessageReceiveFliter <NSObject>
@required
- (NSArray *) fliteMessage:(NSArray *)messages;
@end
