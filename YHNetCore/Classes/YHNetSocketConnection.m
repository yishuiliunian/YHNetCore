//
//  YHNetSocketConnection.m
//  Pods
//
//  Created by stonedong on 16/4/19.
//
//

#import "YHNetSocketConnection.h"
#import <libkern/OSAtomic.h>
@implementation YHNetSocketConnection
{
    YHNetCommunicator* _communicator;
    BOOL _shouldClose;
}

- (instancetype) initWithCommunicator:(YHNetCommunicator *)c
{
    self = [super init];
    if (!self) {
        return self;
    }
    _communicator = c;
    return self;
}

- (void) open
{
    OSatomicread
    if (<#condition#>) {
        <#statements#>
    }
}


- (void) close
{
    
}

@end
