//
//  YHReadBuffer.m
//  Pods
//
//  Created by stonedong on 16/4/23.
//
//

#import "YHReadBuffer.h"

static int8_t HEAD_LEN = 4;

int byteToInt2(Byte b[]) {
    int mask=0xff;
    int temp=0;
    int n=0;
    for(int i=0;i<HEAD_LEN;i++){
        n<<=8;
        temp=b[i]&mask;
        n|=temp;
    }
    return n;
}
@implementation YHReadBuffer
{
    NSMutableData* _data;
}
- (instancetype) init
{
    self = [super init];
    if (!self) {
        return self;
    }
    _aimDataLength = 0;
    _data = [NSMutableData new];
    return self;
}

- (void)appendBytes:(const void *)bytes length:(NSUInteger)length
{
    [_data appendBytes:bytes length:length];
}

- (int64_t) receivedDataLength
{
    return _data.length;
}


- (BOOL) isFull
{
    if (_aimDataLength !=0 && self.receivedDataLength != 0) {
        if (self.receivedDataLength < self.aimDataLength) {
            return NO;
        } else {
            return YES;
        }
    }
    return NO;
}

- (NSData*) bufferData
{
    return [_data copy];
}

@end
